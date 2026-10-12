#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <time.h>


//const size_t N = 256 * 1024;
const size_t N = 1 * 1024 * 1024;
const size_t COUNT = 10000;


int main (int argc, char** argv) {
    clock_t start, stop;
    int i;
    int iter;
    double elapsed;
    double bytes_sec;

    unsigned char* src = (unsigned char*) malloc(sizeof(unsigned char) * N);
    unsigned char* dest = (unsigned char*) malloc(sizeof(unsigned char) * N);

    for (i = 0; i < N; ++i) {
        src[i] = rand();
    }

    start = clock();

    for (iter = 0; iter < COUNT; iter++) {
        memcpy(dest, src, (size_t) (N* sizeof(unsigned char)));
    }

    stop = clock();

    elapsed = (stop - start) / (double)CLOCKS_PER_SEC;

    bytes_sec = (COUNT * (N / (double) 1024 / 1024) * sizeof(unsigned char)) / elapsed;

    printf("Duration: %.5lfs for %ld iterations, %.3lfMB/sec\n", elapsed, COUNT, bytes_sec);

    free(src);
    free(dest);

    return 0;
}

