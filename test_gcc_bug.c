#include <stdio.h>

//NOTES:
//This is a bug that I discovered while implementing the Sieve of Eratosthenes to compare CPUs.
//I forgot to limit the outer loop to sqrt(n), and that produced an overflow, but the overflow
//behaviour was different when compiling without optimizations versus -O2 with GCC.

//Compile with
//     gcc -o test_gcc_bug test_gcc_bug.c
//AND:
//     gcc -O2 -o test_gcc_bug test_gcc_bug.c
//to observe the bug.


int main (int argc, char** argv) {
    int i=0;
    int p=0;

    //GCC bug:
    //   When compiling normally, it prints "ZERO".
    //   When compiling with -O2 to -O3, it prints nothing!
    //Looking at the disassembly (objdump -D -d), it seems that gcc removes the entire if block, because
    //it seems it doesn't consider i to be ever be < 0 by multiplying two positive numbers.
    for (p=2; p < 50000; ++p) {
        //p = 46349;
        i = p * p;
        if (i < 0) {
            printf("i: %d\n", i);
            printf("ZERO\n");
            break;
        }
    }
}

