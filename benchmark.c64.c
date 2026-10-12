/*
Benchmark in C for the Commodore 64 using the CC65 C compiler.

Compile:
    /usr/local/cc65/bin/cl65 -O -t c64 benchmark.c64.c

Run:
    Drag and drop "benchmark.c64" to a running VICE emulator.

    Or start the emulator like this:
        x64 benchmark.c64

    Or go to "File -> Smart-attach disk/tape..." menu and select "benchmark.c64". Then execute RUN.

ReRun:
    Drag and drop again, or execute:
        LOAD "BENCHMARK.C64", 8
        RUN

See the comments and tips in "benchmark.c64.bas" for more details about the Commodore 64.


Limitations of CC65 for Commodore 64:

    -ints are 16bits.
    -longs are 32bits. Only longs can fit n=304500.
    -No float or double support in this compiler.
    -If main is declared with argc and argv, then argc == 1 and
     argv[0] == "*" or "benchmark.c64" depending on how it was LOADed.
    -Although stderr has a different descriptor than stdout, they
     behave the same for this use case.
    -I can exit main() with different exit codes, but I don't know how
     to retrieve the exit code once the program finishes, for this use case.
    -The clock() will reset at 24hs of the computer/emulator being ON.
     It uses the same clock source as the special Basic variable "TIME",
     (RDTIM C64 kernel function) with a resolution of 60 jiffies per second.

To install the C64 CC65 compiler do:

        git clone https://github.com/cc65/cc65.git
        cd cc65
        make
        #Move it to /usr/local/cc65 if not already there.

*/


#include <stdio.h>
#include <time.h>


//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
long findPrimes(long n) {
    long i, j;
    long count = 0;

    //For each number up to 'n':
    for (i=2; i <= n; ++i) {
        for (j=2; j < i; ++j) {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if (i % j == 0) {
                break;
            }
        }
        if (i == j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


//Version that uses "int" 16bit integers. It is 4x faster than the 32bit "long" version.
//It takes 8.133s for n=304, while the "long"'s version takes 32.316s.
//Can't use this version for speed measurements since it would be cheating,
//because CC65 int's can't fit n=304500.
int findPrimesInts(int n) {
    int i, j;
    int count = 0;

    //For each number up to 'n':
    for (i=2; i <= n; ++i) {
        for (j=2; j < i; ++j) {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if (i % j == 0) {
                break;
            }
        }
        if (i == j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


int main (void) {
    long n = 0;
    long count;
    clock_t startTime, endTime;
    clock_t elapsedSecs, elapsedMsecs;
    int r;

    printf("\n");
    printf("Quick and dirty single thread\n");
    printf("CPU benchmark - by JMC\n");
    printf("\n");
    printf("Usage: \n");
    printf("  Pass an argument up to which prime\n");
    printf("  numbers will be searched with an inef-");
    printf("  ficient algorithm, useful to compare\n");
    printf("  single thread performance of the CPU\n");
    printf("\n");
    printf("Example: \n");
    printf("  n=304\n");
    printf("\n");
    printf("Notes: \n");
    printf("  Searching up to 304500 in C is almost\n");
    printf("  exactly 10s on Intel i7 4770K 3.5Ghz\n");
    printf("\n");
    printf("  C64 C:it takes an estimated 14125646s\n");
    printf("       (163d 11h 47m) for n=304500.\n");
    printf("  For n=304 it takes 32.316s\n");
    printf("  For n=3045 it takes 2290.816s (38m)\n");
    printf("\n");

    printf("Search primes up to? ");
    r = scanf("%ld", &n);
    if (r <= 0 || n < 2) {
        if (r <= 0) {
            //A newline is required when scanf() fails (non numeric input, etc.).
            fprintf(stderr, "\n");
        }
        fprintf(stderr, "ERROR: Argument '%ld' not valid.\n", n);
        return 1;
    }

    startTime = clock();

    count = findPrimes(n);
    //count = findPrimesInts(n);

    //Notes:
    //    -CLOCKS_PER_SEC is 60, the same as Basic's system variable TIME.
    //    -clock_t is unsigned long (32 bits)
    //    -No floats in CC65, so I have to calculate and print the Msecs separately.
    endTime = clock();
    elapsedSecs = (endTime - startTime) / CLOCKS_PER_SEC;
    elapsedMsecs = (endTime - startTime - elapsedSecs * CLOCKS_PER_SEC) * 1000 / CLOCKS_PER_SEC;
    printf("Elapsed: %2lu.%03lus\n", elapsedSecs, elapsedMsecs);

    printf("%ld primes found between 2 and %ld\n", count, n);

    return 0;
}
