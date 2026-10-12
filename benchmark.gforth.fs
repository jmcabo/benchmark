#! /usr/bin/gforth-fast
\ Benchmark in GNU FORTH (Gforth) by JMC
\
\ Compile and run:
\      ./benchmark.gforth.fs 304500
\ or
\      gforth-fast benchmark.gforth.fs 304500
\
\ Remarks:
\     -Forth is a stack based language created in 1970. Coming from HP calculators' User RPL or System RPL makes
\      Forth pretty easy to learn, since RPL is based on FORTH, especially SysRPL.
\
\     -The programs are made of WORDs, ie: commands. Even the addition operator is a word that operates
\      on the arguments in the stack. Example: "1 2 +" gives "3". Control flow statements like IF
\      and DO are also words.
\
\     -Words are case insensitive. "IF" is the same as "if".
\
\     -Almost any character can be used in a word name except for space. For example, the word "0<>"
\      starts with a number and has brackets in its name ("0<>" returns true if the number in the stack
\      is different than 0).
\
\     -In the interpreter command line, use "words" to print the names of all the available commands,
\      and "see WORD" to decompile a word (it doesn't work with built-in words).
\
\     -There are two types of integer values in Forth: single precision ints and double precision ints.
\      Single precision ints fit into a single "cell" in the stack. Double precision ints use two cells,
\      with the one in the most recent place in the stack having the high part and the other the lower part.
\      The 64-bit version of Gforth uses 64 bits per cell. That means that single precision ints are 64 bits
\      and doubles are 128 bits.
\      The following code evidences that. It multiplies by two with each iteration and prints the values,
\      so it's easy to see where the ints wrap around to zero:
\
\            : testPrecision
\                cr s" Single precision ints:" type cr
\                1  65 1 ?do
\                    2* dup .
\                loop
\                cr
\                cr s" Double precision ints:" type cr
\                1 0  129 1 ?do
\                    d2* 2dup d.
\                loop
\            ;
\            testPrecision
\
\      The 32-bit version of Gforth uses 32 bits per cell and 32 bits for single precision ints and
\      64 bits for doubles.
\      The documentation isn't clear on bit sizes, so I had to do the above test.
\      NOTE: A simpler way to find out the number of bytes per cell is simply:
\            1 cells .
\      which will print 8 in 64-bit Gforth and 4 in 32-bit Gforth.
\
\     -Integer size is very important since integer division is faster for 32-bit registers than for 64-bit registers.
\      The x86 assembly instruction IDIV which implements division and modulus is faster for 32-bit registers.
\
\     -Strings are represented in the stack as a "c-addr nlength" pair, where the c-addr is a pointer
\      to the first byte, and nlength is the number of bytes (chars) in the string.
\
\     -DO loops always name their counter variable "i". When DO loops are nested, inside the nested loop
\      the innermost variable is "i" and the outer loop variable is named "j".
\      That can be a bit confusing. Suddenly, the outer variable that was "i" before is now called "j".
\      When a DO loop finishes, the counter variable disappears.
\
\
\ Limitations:
\     -No command line exit code. The "bye" word doesn't accept an exit code parameter.
\      UPDATE: Actually, I found an undocumented variant of "bye" called "(bye)", with parentheses,
\      "paren_bye", that returns the specified exit code to the OS. Too bad it isn't documented.
\
\     -Comments are started with an inverted slash "\" but one must leave a space after the slash.
\
\     -The shebang line at the top must contain a space before the path, otherwise Gforth doesn't
\      see it as a comment. This is invalid:
\          #!/usr/bin/gforth-fast
\      This is valid:
\          #! /usr/bin/gforth-fast
\
\     -Float to string commands are almost what I need but not quite. I need to print
\      the elapsed time in seconds with 3 decimals and padding with spaces up to 6 chars.
\      This almost does it:
\          elapsedSecs 6 3 1 f.rdp
\      except that the "f.rdp" command prints an asterisk instead of the number when it
\      exceeds the 6 chars width. The words "f>str-rdp" and "f>buf-rdp" do the same.
\      And "represent" is too basic: it just prints the mantissa without a decimal dot and
\      returns the exponent separately.
\      So instead of using floats, I used integer formatting with "<# #s #>" which is flexible
\      enough to do what I needed.
\


\ NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
\ that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
\ but puts the function in a loop and counts 10000 calls).
\ Returns how many prime numbers exist between 2 and n:
: findPrimes ( n -- count )
    0 { n count }

    \ For each number up to 'n':
    n 1 +  2 ?do
        count 1+ to count
        i 2 ?do  \ NOT using the sqrt optimization (for easier benchmarking).
            \ If j divisible by i, it wasn't a prime number:
            j i mod 0= if
                count 1- to count
                leave
            endif
        loop
        \ If the previous loop ended without divisors found, it is
        \ a prime number. Count is not decremented in that case.
    loop

    \ Return count by placing it in the stack:
    count
;


\ Version using DO loops with no local vars. It is almost the same as using local vars for n and count.
\ Execution time is 43.788s for n=304500 using a 64-bit Gforth.
: findPrimes_DoNoLocalVars ( n -- count )

    0                   \ Put count=0 in the stack

    \ For each number up to 'n':
    swap 1+  2 ?do
        1+              \ Increment count

        i 2 ?do  \ NOT using the sqrt optimization (for easier benchmarking).
            \ If j divisible by i, it wasn't a prime number:
            j i mod 0= if
                1-      \ Decrement count
                leave   \ Break loop
            endif
        loop

        \ If the previous loop ended without divisors found, it is
        \ a prime number. Count is not decremented in that case.
    loop

    \ Return count that is already on the stack
;


\ Version using WHILE loops instead of DO loops. It is slower than using DO loops.
\ Execution time is 60.158s for n=304500 using a 64-bit Gforth.
: findPrimes_While ( n -- count )
    0 0 0 { n count i j }

    2 to i
    begin
        i n <=
    while
        count 1+ to count
        2 to j
        begin
            j i <
        while
            i j mod 0= if
                count 1- to count
                i 1- to j
            endif
            j 1+ to j
        repeat
        i 1+ to i
    repeat

    count
;


\ Version using WHILE loops without local vars, everything is on the stack. It is faster than using local vars.
\ Execution time is 53.726s for n=304500 using a 64-bit Gforth.
: findPrimes_WhileNoVars ( n -- count )
                                        \                    (stack: n)
    0                                   \ count = 0          (stack: n count)
    2                                   \ i = 2              (stack: n count i)
    begin
        dup 3 pick <=                   \ While i <= n       (stack: n count i flag)
    while
        swap 1+ swap                    \ count += 1         (stack: n count i)
        2                               \ j = 2              (stack: n count i j)
        begin
            2dup swap <                 \ While j < i        (stack: n count i j flag)
        while
            2dup mod 0= if              \ if mod(i, j) == 0  (stack: n count i j)
                rot 1- rot rot          \ count -= 1         (stack: n count i j)
                drop dup 1-             \ j = i - 1          (stack: n count i j)
            endif
            1+                          \ j += 1             (stack: n count i j)
        repeat
        drop                            \                    (stack: n count i)
        1+                              \ i += 1             (stack: n count i)
    repeat
    drop                                \                    (stack: n count)
    swap drop                           \                    (stack: count)
;


: main ( -- )
    argc @ 2 <> if
        ." Quick and dirty single thread CPU benchmark - by JMC" cr
        ." Usage: " cr
        ."         Pass an argument up to which prime numbers will be searched with" cr
        ."         an inefficient algorithm, useful to compare the single thread performance" cr
        ."         of the CPU" cr
        ." Example: " cr
        ."         " sourcefilename type ."  304500" cr
        ." Notes: " cr
        ."         Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz" cr
        ."         with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3." cr
        ."         Gforth-32bits: it takes 21.916s using Gforth 0.7.0. 32bits with gforth-fast" cr
        ."         Gforth: it takes 43.760s using Gforth 0.7.3. 64bits with gforth-fast" cr
        cr
        1 (bye)
    endiF

    \ Convert string in argument 1 to number:
    0 0 1 arg >number           \ >number also returns count and address of unconvertible chars, should be 0.
    swap drop                   \ Drop the pointer to remaining unconvertible string chars.
    { n nHi remChars }          \ Put the values of the stack in local variables.

    \ Fail if 1 arg is not a number of n < 2:
    remChars 0 <>               \ If count of unconvertible chars is different than 0, it wasn't a completely numeric argument.
    nHi 0 <>                    \ If argument is bigger than single precision, fail.
    n 2 <                       \ If n < 2, fail.
    or                          \ OR the previous three booleans.
    or
    if
        \ Redirect to STDERR and print the error:
        outfile-id              \ Save stdout id in stack
        stderr to outfile-id    \ Store stderr in outfile-id
        ." ERROR: Argument '" 1 arg type ." ' not valid." cr
        to outfile-id           \ Restore stdout id from stack

        1 (bye)                 \ End with exit code 1
    endif


    0  0 0  0 0  0 0  { count  D: startTime  D: endTime  D: elapsedMs }
    utime to startTime                \ Store time in microseconds to 'startTime' local variable

    n findPrimes to count             \ count = findPrimes(n)
    \ n findPrimes_DoNoLocalVars to count
    \ n findPrimes_While to count
    \ n findPrimes_WhileNoVars to count

    utime to endTime                  \ Store time in microseconds to 'endTime'
    endTime startTime d-              \ Subtract doubles to get elapsed time in microseconds
    500. d+ 1 1000 m*/ to elapsedMs   \ Add 0.5ms for rounding, and divide by 1000 to get milliseconds
    ." Elapsed: "                     \ Print "Elapsed: "
    elapsedMs
    <#  # # #  [char] . hold  #s #>   \ String of three digits, then a dot, then the rest of the digits (specified in reverse order)
    dup 6 < if                        \ If string length is less than 6 chars, print one space for padding.
        space
    endif
    type                              \ Print number string present in stack
    ." s" cr                          \ Print "s" and a newline

    count . ." prime numbers were found between 2 and " n . cr
;


main
bye


