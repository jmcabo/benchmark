//Quick and dirty single thread CPU benchmark - by JMC

#include <stdio.h>
#include <time.h>

//For sieve of eratosthenes:
#include <stdlib.h>


//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
int findPrimes(int n) {
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


//FAST implementation,
//using the Sieve of Eratosthenes algorithm,
//which is O(n log(log n)),
//but uses lots of RAM (it's O(n) for space (RAM)).
//NOTE: It's CRAZY fast, but it's so fast, that it's harder to use for benchmarks
//      (want something that takes 10 seconds), and one would be benchmarking RAM
//      in addition to CPU.
int findPrimesSieveOfEratosthenes(int n) {
    char* a;
    int i;
    int p;
    int count;

    if (n <= 0) {
        return 0;
    }
    if (n > 1024*1024*1024) {
        //Don't want to allocate more than 100MB for this test
        printf("ERROR: n too big for Sieve of Eratosthenes method (too much RAM required).\n");
        return 0;
    }

    a = (char*) malloc(n+1);
    if (a == NULL) {
        printf("ERROR: couldn't allocate RAM for sieve of eratosthenes.\n");
        return 0;
    }

    //Assume all numbers are prime (1), except 0 and 1.
    for (i=0; i <= n; ++i) {
        a[i] = 1;
    }
    a[0] = 0;
    a[1] = 0;

    //Iterate up to sqrt(n). Numbers don't have divisors greater than sqrt(n).
    for (p=2; p*p <= n; ) {
        //Eliminate multiples of prime 'p' by eliminating p+p, p+p+p, p+p+p+p, etc.
        //Start from p*p, since we can assume numbers less than p**2 are already covered.
        for (i=p*p; i <= n; i += p) {
            a[i] = 0;
        }
        //Get next prime:
        do {
            ++p;
        } while (p <= n && a[p] == 0);
    }

    count = 0;
    for (i=0; i <= n; ++i) {
        count += a[i];
    }

    free(a);

    return count;
}


int main(int argc, char** argv) {
    int n = 0;
    int count;
    clock_t startTime, endTime;
    double elapsed;

    if (argc != 2) {
        printf("Quick and dirty single thread CPU benchmark - by JMC\n");
        printf("Usage: \n");
        printf("        Pass an argument up to which prime numbers will be searched with\n");
        printf("        an inefficient algorithm, useful to compare the single thread performance\n");
        printf("        of the CPU\n");
        printf("Example: \n");
        printf("        time %s 304500\n", argv[0]);
        printf("Notes: \n");
        printf("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n");
        printf("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n");
        printf("\n");
        return 1;
    }

    if (sscanf(argv[1], "%d", &n) <= 0 || n < 2) {
        fprintf(stderr, "ERROR: Argument '%s' not valid.\n", argv[1]);
        return 1;
    }

    startTime = clock();

    //Naive method:
    count = findPrimes(n);
    //"Sieve of Eratosthenes" method:
    //count = findPrimesSieveOfEratosthenes(n);

    endTime = clock();
    elapsed = (endTime - startTime) / (double) CLOCKS_PER_SEC;
    printf("Elapsed: %6.3fs\n", (double) elapsed);

    printf("%d prime numbers were found between 2 and %d\n", count, n);

    return 0;
}

