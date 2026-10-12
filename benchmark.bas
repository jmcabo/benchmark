DECLARE FUNCTION findPrimes! (n&)
DECLARE FUNCTION findPrimesWhile! (n&)
DECLARE SUB main ()

'Made For QuickBasic 4.5
'
'Compile and run in command line:
'       bc bench.bas
'       link bench.obj
'       bench 30450
'Or use the menu "Run -> Make EXE file" and
'select "Stand-Alone EXE File" (BEST METHOD. The other option is 2% slower).
'
'Or run with F5 in QuickBasic interpreter (runs 30% slower),
'selecting "Options -> Full Menus" and inputting the number
'in "Run -> Modify COMMAND".
'
'For FreeBASIC:
'Compile and run:
'       fbc -lang qb -O 4 -o benchmark_tmp benchmark.bas && ./benchmark 304500
'
'Limitations of QuickBasic:
'   -Can't specify exit code in END statement.
'   -The TIMER function rolls back at midnight.
'   -No way to print the error to STDERR.
'   -Can't determine program name (ie: argv[0]).
'   -It prints 0xd 0xa instead of 0xa, of course, being DOS.
'   -The QBasic 1.1 interpreter (the one bundled with MSDOS)
'    lacks COMMAND$ args and compilation to .EXE.
'   -Filename is BENCH.BAS instead of benchmark.bas because of
'    DOS 8 char filenames.
'   -Help text message wrapped to 80-columns.
'   -Using "&" suffix in variables so that they are 32bits and can fit 304500.
'   -PRINT USING outputs a "%" sign prefix if the elapsed time number
'    is 3 integer digits or more, to indicate that there are more digits
'    than can fit in the "##.###" format string.
'   -Passing "+30" as an argument is not considered a valid 'n' because of
'    validating the integer against the string representation.
'


main

'NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
'that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
'but puts the function in a loop and counts 10000 calls).
'Returns how many prime numbers exist between 2 and n:
FUNCTION findPrimes (n&)
    count& = 0

    'For each number up to 'n':
    FOR i& = 2 TO n&  'NOT using the sqrt optimization (for easier benchmarking).
        FOR j& = 2 TO i& - 1
            'If i divisible by j, it wasn't a prime number:
            IF i& MOD j& = 0 THEN
                EXIT FOR
            END IF
        NEXT

        IF i& = j& THEN
            'The previous loop ended without divisors found. It is a prime number.
            count& = count& + 1
        END IF
    NEXT

    findPrimes = count&
END FUNCTION

'NOTE: It is exactly the same speed using WHILE loops instead of FOR:
FUNCTION findPrimesWhile! (n&)
    count& = 0

    'For each number up to 'n':
    i& = 2
    WHILE i& <= n&  'NOT using the sqrt optimization (for easier benchmarking).
        j& = 2
        WHILE j& < i&
            'If i divisible by j, it wasn't a prime number:
            IF i& MOD j& = 0 THEN
                GOTO breakWhile
            END IF
            j& = j& + 1
        WEND

breakWhile:
        IF i& = j& THEN
            'The previous loop ended without divisors found. It is a prime number.
            count& = count& + 1
        END IF
        i& = i& + 1
    WEND

    findPrimesWhile = count&
END FUNCTION

SUB main
    ARGS$ = COMMAND$
    'ARGS$ = "3045"
    IF ARGS$ = "" THEN
        PRINT "Quick and dirty single thread CPU benchmark - by JMC"
        PRINT "Usage: "
        PRINT "        Pass an argument up to which prime numbers will be searched with"
        PRINT "        an inefficient algorithm, useful to compare the single thread"
        PRINT "        performance of the CPU"
        PRINT "Example: "
        PRINT "        bench 304500"
        PRINT "Notes: "
        PRINT "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an"
        PRINT "        Intel i7 4770K @ 3.5GHz with benchmark.c compiled without optimizations"
        PRINT "        using GCC, and 8.85s with -O3."
        PRINT "        FreeBASIC: it takes 8.860s using fbc 1.05.0 on 64bit linux."
        PRINT "        QuickBasic: it takes 587.870s using QuickBasic 7.1 as standalone EXE."
        PRINT "        QuickBasic: it takes 692.391s using QuickBasic 4.5 as standalone EXE."
        PRINT "        QuickBasic: it takes 767.480s using QuickBasic 7.1 interpreted with F5."
        PRINT "        QuickBasic: it takes 853.160s using QuickBasic 4.5 interpreted with F5."
        PRINT "        QBasic: it takes 1187.098s using QBasic 1.1 DOS 6.0 interpreted with F5."
        PRINT ""
        END
    END IF

    n& = VAL(ARGS$)
    IF n& < 2 OR LTRIM$(STR$(n&)) <> ARGS$ THEN
        PRINT "ERROR: Argument '"; ARGS$; "' not valid."
        END
    END IF

    startTime# = TIMER

    count& = findPrimes(n&)
    'count& = findPrimesWhile(n&)

    endTime# = TIMER
    elapsed# = endTime# - startTime#
    PRINT "Elapsed: "; USING "##.###s"; elapsed#

    PRINT LTRIM$(STR$(count&)); " prime numbers were found between 2 and "; LTRIM$(STR$(n&))

END SUB

