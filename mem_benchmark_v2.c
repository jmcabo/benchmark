//#include <stdio.h>
//#include <stdlib.h>
//#include <string.h>
//#include <time.h>
//
//int main() {
//    unsigned long n, r, i;
//    unsigned char *p;
//    clock_t c0, c1;
//    double elapsed;
//
//    n = 1000 * 1000 * 1000; /* GB */
//    r = 100; /* repeat */
//
//    p = calloc(n, 1);
//
//    c0 = clock();
//
//    for(i = 0; i < r; ++i) {
//        memset(p, (int)i, n);
//        printf("%4d/%4ld\r", p[0], r); /* "use" the result */
//        fflush(stdout);
//    }
//
//    c1 = clock();
//
//    elapsed = (c1 - c0) / (double)CLOCKS_PER_SEC;
//
//    printf("Bandwidth = %6.3f GB/s (Giga = 10^9)\n", (double)n * r / elapsed / 1e9);
//
//    free(p);
//}


#include <stdio.h>
#include <stdlib.h>
//#include <string.h>
#include <time.h>


unsigned long do_xor(const unsigned long* p, unsigned long n) {
    unsigned long i, x = 0;

    for(i = 0; i < n; ++i) {
        x ^= p[i];
    }

    return x;
}


int main() {
    unsigned long n, r, i;
    unsigned long uncacheSize;
    unsigned long *p;
    unsigned long *q;
    clock_t c0, c1;
    double elapsed;

    n = 420 * 1024 * 1024; /* GB */
    uncacheSize = 9 * 1024 * 1024; /* GB */
    r = 120; /* repeat */

    p = calloc(n/sizeof(unsigned long), sizeof(unsigned long));
    q = calloc(uncacheSize/sizeof(unsigned long), sizeof(unsigned long));


    clock_t min = 0;
    clock_t max = 0;
    clock_t sum = 0;

    for(i = 0; i < r; ++i) {
        q[0] = do_xor(q, uncacheSize / sizeof(unsigned long)); /* "use" the result */
        q[0] = do_xor(q, uncacheSize / sizeof(unsigned long)); /* "use" the result */
        c0 = clock();
        p[0] = do_xor(p, n / sizeof(unsigned long)); /* "use" the result */
        c1 = clock();
        sum += c1 - c0;
        if (max == 0 || max < (c1 - c0)) {
            max = c1 - c0;
        }
        if (min == 0 || min > (c1 - c0)) {
            min = c1 - c0;
        }

        //printf("%4ld/%4ld\r", i, r);
        //fflush(stdout);

        //printf("Bandwidth = %6.3f GB/s\n", (double)n / ((c1 - c0) / (double)CLOCKS_PER_SEC) / 1e9);
    }


    elapsed = sum / (double)CLOCKS_PER_SEC;
    //elapsed = (c1 - c0) / (double)CLOCKS_PER_SEC;
    //elapsed = min / (double)CLOCKS_PER_SEC;

    printf("Bandwidth = %6.3f GB/s (Giga = 10^9). Min=%6.3f Max=%6.3f\n",
            (double)n * r / elapsed / 1e9,
            (double)n / (max / (double)CLOCKS_PER_SEC) / 1e9,
            (double)n / (min / (double)CLOCKS_PER_SEC) / 1e9
    );
    //printf("Bandwidth = %6.3f GB/s (Giga = 10^9)\n", (double)n / elapsed / 1e9);
    //printf("Bandwidth = %6.3f GB/s (Giga = 10^9)\n", (double)1.0 / elapsed);

    free(p);
}


