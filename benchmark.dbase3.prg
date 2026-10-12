*For DBASE III Plus V1.1
*
*Run as:
*   dbase.exe bench.prg
*Or enter dbase.exe and run the command:
*   DO bench.prg
*Hit ESC to interrupt instead of CTRL+C.
*
*Limitations of DBASE III Plus programming language:
*   -The main limitation is that on each assignment, the value of
*    the variable is printed to the screen!. That makes everything
*    extremely slow. Also it adds indentation when printing variables.
*   -Too many others to list: no program name, no cmd line args, no printing to STDERR,
*    no proper clock with milliseconds, no exit code, no proper functions in the same file,
*    sometimes numeric variables are integer and sometimes they are floats
*    (ie: VAL() returns floats), etc. etc.
*   -DBase3 doesn't exit after running the script. And if the program ends with QUIT,
*    the screen contents is lost. WAIT could be used to pause before QUIT.
*    But since dbase shows a banner and asks to press a key before running the program,
*    it is more convenient to use "DO bench.prg" to repeatedly execute the program once
*    inside dbase.
*   -INPUT() returns either a string or a number, but converting with STR() or VAL()
*    requires you to know whether it is a string or a number (they fail otherwise).
*    And I didn't find a function to tell the type of a variable.
*   -MSDOS 80 columns of text limit.
*   -At least integer variables are 32 bits or more (Seems to be 46 bits. Maybe
*    the mantissa of an emulated float?)
*   -Comments can't start in the middle of a line. The line must start with asterisk.


* main:

? "Quick and dirty single thread CPU benchmark - by JMC"
? "Usage: "
? "        Pass an argument up to which prime numbers will be searched with"
? "        an inefficient algorithm, useful to compare the single thread"
? "        performance of the CPU"
? "Example: "
? "        dbase.exe bench.prg"
? "Notes: "
? "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an"
? "        Intel i7 4770K @ 3.5GHz with benchmark.c compiled without optimizations"
? "        using GCC, and 8.85s with -O3."
? "        dBase3: it takes an estimated 215817s (59h 57m) using DBase III Plus"
? "                V1.1 in a 32bit WinXP SP3 VM. For n=3045, it takes 35s."
? ""

INPUT "Search primes up to? " TO n
IF n < 2
    ? "ERROR: Argument '" + ltrim(str(n)) + "' not valid."
    EXIT
ENDIF
n = int(n)


startTime = time()

*findPrimes:
*NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
*that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
*but puts the function in a loop and counts 10000 calls).
*Returns how many prime numbers exist between 2 and n:
countPrimes = 0
i = 2
*For each number up to 'n':
do while i <= n
    j = 2
    do while j < i
*       If i divisible by j, it wasn't a prime number:
        if mod(i, j) = 0
            exit
        endif
        j = j + 1
    enddo
    if i = j
*       The previous loop ended without divisors found. It is a prime number.
        countPrimes = countPrimes + 1
    endif
    i = i + 1
enddo

endTime = time()


*Time difference in seconds. Sadly TIME() doesn't have milliseconds.
startSecs = val(left(startTime, 2)) * 3600 + val(substr(startTime, 4, 2)) * 60 + val(substr(startTime, 7, 2))
endSecs = val(left(endTime, 2)) * 3600 + val(substr(endTime, 4, 2)) * 60 + val(substr(endTime, 7, 2))
elapsed = endSecs - startSecs
*Is it across midnight? (more than 1 day difference won't work. Elapsed limit 24hs):
if elapsed < 0
    elapsed = elapsed + 24 * 3600
endif

? "----------------"
? "Elapsed: ", ltrim(str(elapsed)) + "s"
? LTRIM(STR(countPrimes)), "prime numbers were found between 2 and", LTRIM(STR(n))


