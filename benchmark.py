#! /usr/bin/python
from __future__ import print_function
import sys
import time
import gc


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
def findPrimes(n):
    count = 0
    #For each number up to 'n':
    i = 2
    while i <= n:
        j = 2
        while j < i:    #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if (i % j) == 0:
                break
            j += 1
        if i == j:
            #The previous loop ended without divisors found. It is a prime number.
            count += 1
        i += 1
    return count;


def main():
    if len(sys.argv) == 1:
        print("Quick and dirty single thread CPU benchmark - by JMC")
        print("Usage: ")
        print("        Pass an argument up to which prime numbers will be searched with")
        print("        an inefficient algorithm, useful to compare the single thread performance")
        print("        of the CPU")
        print("Example: ")
        print("       ", sys.argv[0], "304500")
        print("Notes: ")
        print("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
        print("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
        print("        PyPy32bits: it takes 12.807s using PyPy3 5.2.0 32bits.")
        print("        PyPy: it takes 30.744s using PyPy3 5.2.0, 34.069s using PyPy 5.3.1 and 31.787s using PyPy 2.2.1.")
        print("        Python: it takes 377.3s using Python 3.4.3, and 201.4s using Python 2.7.6.")
        print("")
        exit(1)

    try:
        n = int(sys.argv[1])
    except ValueError:
        n = -1
    if n < 2:
        sys.stderr.write("ERROR: Argument '" + sys.argv[1] + "' not valid.\n");
        exit(1)

    gc.collect()
    startTime = time.time()

    count = findPrimes(n)

    endTime = time.time()
    elapsed = endTime - startTime
    print("Elapsed: %6.3fs" % (elapsed))
    #print("Elapsed: {0:6.3f}s".format(elapsed))

    print(count, "prime numbers were found between 2 and", n)


main()


