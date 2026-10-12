/*
Benchmark in C for the ZX Spectrum using the Z88DK C compiler. Thanks to SplinterGU for research on ZX Spectrum.

Compile:
        zcc +zx -lndos -create-app -o benchmark benchmark.zx.c

Run (for the FBZX emulator):
        fbzx -nosound benchmark.tap

        #Inside the emulator, type:
        LOAD ""
        #(Actually type J CTRL+P CTRL+P. The key for LOAD is J, and the
        #character for "" is CTRL+P)

        #Then hit F6 to tell it to start "playing the tape".
        #Once it finishes loading, hit F5 to return to normal speed (it
        #accelerates while "playing the tape").

Install emulator and compiler in Ubuntu 17.10:
        apt-get install fbzx z88dk

Limitations of Z88DK C for the ZX Spectrum:

    -Usable screen size is 64 columns by 22 rows (the actual bottom rows get erased
     when the program exists), thanks to the small font used by Z88DK.
    -ints are 16bits.
    -longs are 32bits. Only longs can fit n=304500.
    -No float or double support in this compiler.
    -If main is declared with argc and argv, then argc == 0.
    -Although stderr has a different descriptor than stdout, they
     behave the same for this use case.
    -I can exit main() with different exit codes, but I don't know how
     to retrieve the exit code once the program finishes, for this use case.
    -The clock() will reset at 24hs of the computer/emulator being ON.
     It has a resolution of 50 ticks per second (20ms).

*/

#include <stdio.h>
#include <time.h>
#include <stdlib.h> //for atol().


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


//Version that uses "int" 16bit integers. It is 3.7x faster than the 32bit "long" version.
//It takes 4.800s for n=304, while the "long"'s version takes 17.660s.
//Can't use this version for speed measurements since it would be cheating,
//because Z88DK int's can't fit n=304500.
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
    char buffer[30];

    printf("%c",12); //Clear the ZX screen of text written during tape load.

    printf("Quick and dirty single thread CPU benchmark - by JMC\n");
    printf("Usage: \n");
    printf("  Pass an argument up to which prime numbers will be searched\n");
    printf("  with an inefficient algorithm, useful to compare the single\n");
    printf("  thread performance of the CPU\n");
    printf("Example: \n");
    printf("  n=304\n");
    printf("Notes: \n");
    printf("  Searching up to 304500 takes almost exactly 10 seconds (9.7s)\n");
    printf("  on an Intel i7 4770K @ 3.5GHz with benchmark.c compiled\n");
    printf("  without optimizations using GCC, and 8.85s with -O3.\n");
    printf("  ZX C: it takes an estimated 7759555s\n");
    printf("        (89d 19h 26m) for n=304500.\n");
    printf("        For n=304 it takes 17.660s\n");
    printf("        For n=3045 it takes 1258.400s (21m)\n");
    printf("\n");

    printf("Search primes up to? ");
    //Note: Using fgets() and atol() since scanf %ld doesn't work properly in Z88DK that comes with Ubuntu 17.10.
    if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
        n = atol(buffer);
    }
    if (n < 2) {
        fprintf(stderr, "ERROR: Argument '%ld' not valid.\n", n);
        return 1;
    }

    startTime = clock();

    count = findPrimes(n);
    //count = findPrimesInts(n);

    //Notes:
    //    -CLOCKS_PER_SEC is 50, which gives 0.020s resolution.
    //    -clock_t is unsigned long (32 bits)
    //    -No floats in Z88DK, so I have to calculate and print the Msecs separately.
    endTime = clock();
    elapsedSecs = (endTime - startTime) / CLOCKS_PER_SEC;
    elapsedMsecs = (endTime - startTime - elapsedSecs * CLOCKS_PER_SEC) * 1000 / CLOCKS_PER_SEC;
    printf("Elapsed: %2lu.%03lus\n", elapsedSecs, elapsedMsecs);

    printf("%ld primes found between 2 and %ld\n", count, n);

    return 0;
}

