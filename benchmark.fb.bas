#ifdef shell_shebang
fbc -O 4 -x benchmark.fb "$0"  &&  exec -a "$0" ./benchmark.fb "$@"  ;  exec /bin/false
#endif
DECLARE FUNCTION findPrimes (n As Long) As Long
DECLARE FUNCTION findPrimesWhile (n As Long) As Long
DECLARE SUB main ()

'For FreeBASIC
'Compile and run:
'       fbc -O 4 benchmark.fb.bas && ./benchmark.fb 304500
'
'Limitations of FreeBASIC:
'   -Despite using Long (32bit) variables, the modulus computation is done
'    in 64 bits (slower machine code instruction).
'    Unless the mode is "-lang qb". Then it is 32 bits.
'    This explains the difference in 8s vs 28s with or without "-lang qb" (see "benchmark.bas")
'    The following line is from the generated .c code (with -R option). It casts to (int64):
'       if( ((int64)I$1 % (int64)J$1) != 0ll ) goto label$13;
'
'   -PRINT USING outputs a "%" sign prefix if the elapsed time number
'    is 3 integer digits or more, to indicate that there is more digits
'    than can fit in the "##.###" format string.


main

'NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
'that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
'but puts the function in a loop and counts 10000 calls).
'Returns how many prime numbers exist between 2 and n:
FUNCTION findPrimes (n As Long) As Long
    Dim count As Long, i As Long, j As Long
    count = 0

    'For each number up to 'n':
    FOR i = 2 TO n  'NOT using the sqrt optimization (for easier benchmarking).
        FOR j = 2 TO i - 1
            'If i divisible by j, it wasn't a prime number:
            IF i MOD j = 0 THEN
                EXIT FOR
            END IF
        NEXT

        IF i = j THEN
            'The previous loop ended without divisors found. It is a prime number.
            count = count + 1
        END IF
    NEXT

    findPrimes = count
END FUNCTION

'NOTE: It is almost exactly the same speed using WHILE loops instead of FOR:
FUNCTION findPrimesWhile (n As Long) As Long
    Dim count As Long, i As Long, j As Long
    count = 0

    'For each number up to 'n':
    i = 2
    WHILE i <= n  'NOT using the sqrt optimization (for easier benchmarking).
        j = 2
        WHILE j < i
            'If i divisible by j, it wasn't a prime number:
            IF i MOD j = 0 THEN
                Exit While
            END IF
            j = j + 1
        WEND

        IF i = j THEN
            'The previous loop ended without divisors found. It is a prime number.
            count = count + 1
        END IF
        i = i + 1
    WEND

    findPrimesWhile = count
END FUNCTION

SUB main
    Dim PROGNAME As String, argc As Long, n As Long, count As Long, startTime As Double, endTime As Double, elapsed As Double
    PROGNAME = COMMAND$(0)

    argc = 0
    While Len(COMMAND$(argc)) <> 0
        argc = argc + 1
    Wend

    IF argc <> 2 THEN
        PRINT "Quick and dirty single thread CPU benchmark - by JMC"
        PRINT "Usage: "
        PRINT "        Pass an argument up to which prime numbers will be searched with"
        PRINT "        an inefficient algorithm, useful to compare the single thread performance"
        PRINT "        of the CPU"
        PRINT "Example: "
        PRINT "        "; PROGNAME; " 304500"
        PRINT "Notes: "
        PRINT "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        PRINT "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        PRINT "        FreeBASIC: it takes 28.614s using fbc 1.05.0 on 64bit linux."
        PRINT ""
        END 1
    END IF

    n = VAL(COMMAND$(1))
    IF n < 2 OR LTRIM$(STR$(n)) <> COMMAND$(1) THEN
        Open Err For Output As #1
            PRINT #1, "ERROR: Argument '"; COMMAND$(1); "' not valid."
        Close #1
        END 1
    END IF

    startTime = TIMER

    count = findPrimes(n)
    'count = findPrimesWhile(n)

    endTime = TIMER
    elapsed = endTime - startTime
    PRINT "Elapsed: "; USING "##.###s"; elapsed

    PRINT LTRIM$(STR$(count)); " prime numbers were found between 2 and "; LTRIM$(STR$(n))

END SUB

