#!/usr/bin/vim -nNesc:let&verbose=1|let&viminfo=""|source%|qall!

"Benchmark in Vimscript by JMC
"
"
"Run:
"    ./benchmark.vim 30450
"
"
"Notes:
"    -Vimscript is the extension language of the VIM editor. VIM was created by Bram Moolenaar in 1988 and
"     first released in 1991. Vimscript is also known as VimL. VIM works in Windows, Linux and Mac, and it
"     used to have versions for the Amiga and MSDOS. In fact, it was created by Bram Moolenaar in the Amiga.
"     VIM started as a clone of the Unix VI editor. VI is very basic and not much customizable. VI was
"     created by Bill Joy in 1976.
"       Beginners are scared away from VI and VIM due to them being modal editors. That is: the letter 'j'
"     means 'move the cursor down' in Normal mode, and 'type the letter j' in Insert mode. If you can get
"     past that initial learning curve, you might appreciate the advantages of using a modal editor.
"
"    -I started using VIM as my editor in 2002 and never looked back. I still love it. My 'vimrc' file is
"     full of customizations. I carry it everywhere I use VIM, and it has survived many computers and OSs.
"
"    -To pass negative numbers to a script, use "--". Example:
"            ./benchmark.vim -- -123
"     otherwise VIM says it's an unrecognized command line switch.
"
"    -'echon' doesn't prepend a newline, as opposed to 'echo'.
"
"
"Limitations:
"    -An extra test (reconverted integer != original string) is necessary after parsing the integer
"     argument to exclude strings like "123abc", otherwise VIM parses it as 123. Because of this extra
"     test, an integer with a plus sign is not considered valid: "+123".
"
"    -Can't use 'count' as variable name. It produces an error:
"            E46: Cannot change read-only variable "count"
"
"    -Output always goes to STDERR, not STDOUT.
"
"    -Can't specify exit code with 'cquit', it is always 1.
"


"NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
"that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
"but puts the function in a loop and counts 10000 calls).
"Returns how many prime numbers exist between 2 and n:
function! FindPrimes(n)
    let n = a:n
    let countP = 0

    "For each number up to 'n':
    let i = 2
    while i <= n
        let j = 2
        while j < i    "NOT using the sqrt optimization (for easier benchmarking).
            "If i divisible by j, it wasn't a prime number:
            if (i % j) == 0
                break
            endif
            let j += 1
        endwhile
        if i == j
            "The previous loop ended without divisors found. It is a prime number.
            let countP += 1
        endif
        let i += 1
    endwhile

    return countP
endfunction


function! Main()
    if len(argv()) != 2
        "NOTE: Output is always to STDERR with VimScript.
        echon "Quick and dirty single thread CPU benchmark - by JMC\n"
        echon "Usage: \n"
        echon "        Pass an argument up to which prime numbers will be searched with\n"
        echon "        an inefficient algorithm, useful to compare the single thread performance\n"
        echon "        of the CPU\n"
        echon "Example: \n"
        echon "        " . argv()[0] . " 304500\n"
        echon "Notes: \n"
        echon "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n"
        echon "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n"
        echon "        Vim: it takes an estimated 8603s (2h 23m) using Vim 7.4.052.\n"
        echon "              For './benchmark 30450' it takes 106.065s, which is 973 times slower than the C version at 0.109s.\n"
        echon "\n"
        "This cquit exits with error code 1:
        cquit
    endif

    let n = argv()[1] - 0
    if argv()[1] != n . "" || n < 2
        "NOTE: Output is always to STDERR with Vimscript.
        echon "ERROR: Argument '" . argv()[1] . "' not valid.\n"
        "This cquit exits with error code 1:
        cquit
    endif

    let startTime = reltime()

    let countP = FindPrimes(n)

    let endTime = reltime()
    let elapsed = str2float(reltimestr(reltime(startTime, endTime)))
    echon printf("Elapsed: %6.3fs\n", elapsed)

    echon printf("%d prime numbers were found between 2 and %d\n", countP, n)

endfunction


call Main()

