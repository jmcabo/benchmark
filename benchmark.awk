#!/usr/bin/awk -f

#Benchmark in AWK by JMC
#
#
#Run:
#    ./benchmark.awk 304500
#Requires external commands (for computing and printing elapsed time):
#    date
#
#
#Notes:
#    -AWK was created in 1977 by Alfred Aho, Peter Weinberger, and Brian Kernighan. AWK is a standard
#     part of Unix. It is a programming language for processing streams of text or text files, ideal
#     for quick reporting or gluing commands in the unix shell. It has regular expressions and
#     pioneered the use of slashes as delimiters.
#
#    -This is a POSIX compliant file, compatible with MAWK and GAWK and BusyBox AWK.
#
#    -To pass negative numbers to a script, use "--". Example:
#            ./benchmark.awk -- -123
#     otherwise AWK says it's an unrecognized command line switch.
#
#    -AWK should always be present wherever there is a unix shell (BASH, Dash, Busybox, etc.), since it is
#     a part of POSIX. BusyBox comes with a simple AWK implementation.
#
#    -All numbers are represented as double precision floats, even integers.
#     The max and min doubles are:
#            1.7976931348623157e+308
#            -1.7976931348623157e+308
#     The max and min doubles that can work as "safe integers" ('n != n+1' and 'n != n-1') are:
#            9007199254740991    #2^53 - 1
#            -9007199254740991   #-2^53 + 1
#     The number '2^53 + 1 = 9007199254740993' cannot be represented exactly as double.
#
#    -Forcing the parsing of an number from a string by subtracting zero ('str - 0') accepts floats. While
#     doing it by using 'int(str)' truncates floats to integer. Both return 0 when the string doesn't begin
#     with a number.
#
#
#Limitations:
#    -An extra test (reconverted integer != original string) is necessary after parsing the integer
#     argument to exclude strings like "123abc", "123.", "123.0" or "12.3e1". Because of this extra
#     test, an integer with a plus sign is not considered valid: "+123".
#     I had to use sprintf("%d", n) instead of n"" to exclude "1e+10" too, and exclude the range
#     of floats that are not safe integers.
#     The following can be used in the linux/mac shell to test the cases:
#            for a in 123a 123. 123.0 123.5 123.9 1e+10 1e+20 1e+21 9007199254740992 inf -inf nan; do ./benchmark.awk -- $a; done
#     Tested in: MAWK, GAWK, NAWK, BusyBox AWK.
#
#    -If the external 'date' command doesn't support %N, then it will not measure milliseconds and it
#     will always print ".000" as the decimal part of the elapsed time. The usual 'date' command that
#     comes with GNU coreutils does support milliseconds, but the 'date' command in some BusyBox
#     implementations does not. There is only a 2ms or 3ms overhead in my system for measuring time
#     with the external 'date' command.
#


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
function findPrimes(n) {
    count = 0;

    #For each number up to 'n':
    for (i=2; i <= n; ++i) {
        for (j=2; j < i; ++j) {  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if (i % j == 0) {
                break;
            }
        }
        if (i == j) {
            #The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


function main() {
    if (ARGC != 2) {
        print "Quick and dirty single thread CPU benchmark - by JMC"
        print "Usage: "
        print "        Pass an argument up to which prime numbers will be searched with"
        print "        an inefficient algorithm, useful to compare the single thread performance"
        print "        of the CPU"
        print "Example: "
        printf "        %s 304500\n", ENVIRON["_"]  #Because ARGV[0] is actually "awk".
        print "Notes: "
        print "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        print "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        print "        AWK: it takes 145.7s using MAWK 1.3.3, and 309.0s using GAWK 4.0.1."
        print ""
        exit 1
    }

    n = int(ARGV[1])
    MAX_SAFE_INTEGER = 9007199254740991  #2^53 - 1. Max double that can act as a safe integer (n != n+1).
    if (n > MAX_SAFE_INTEGER || n < -MAX_SAFE_INTEGER || ARGV[1] != sprintf("%d", n) || n < 2) {
        printf "ERROR: Argument '%s' not valid.\n", ARGV[1] > "/dev/stderr"
        exit 1
    }

    dateCommand = "date +\"%s.%N\""; dateCommand | getline startTime; close(dateCommand)

    count = findPrimes(n);

    dateCommand | getline endTime; close(dateCommand)
    elapsed = endTime - startTime
    printf "Elapsed: %6.3fs\n", elapsed

    printf "%d prime numbers were found between 2 and %d\n", count, n
}


BEGIN {
    main()
}

