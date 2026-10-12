#ifdef shell_shebang
#Compile and run when invoked as ./benchmark.c (Note: shell stops at first exec call):
gcc -O3 -o benchmark "$0"  &&  exec -a "$0" ./benchmark $@  ;  exec /bin/false
#endif

//Quick and dirty single thread CPU benchmark - by JMC
//
//
//Run:
//    ./benchmark.c 304500
//Compile and run (as used to compare CPUs):
//    gcc -O3 -o benchmark benchmark.c  &&  ./benchmark 304500
//More optimization:
//    gcc -static -O2 -funroll-loops -o benchmark benchmark.c
//More options, but not better than above:
//    gcc -static -O3 -fforce-addr -falign-loops=2 -falign-functions=2 -falign-jumps=2 -funroll-loops -o benchmark benchmark.c
//
//
//Notes:
//    -This is the reference Quick And Dirty Benchmark file and the first one. I created it in June 2014
//     when I needed to quickly compare in 10 minutes a throttled virtual cloud CPU to my real CPU, and there
//     was a GCC compiler available. I later added these notes, the shebang line, and the "Sieve of
//     Eratosthenes" implementation to this file.
//       I originally wanted to make something that would take 10 seconds to run in my CPU. The server
//     virtual CPU took 62.1 seconds to run the same code. That meant that at this particular task,
//     that virtual CPU was roughly 6.21 times slower than my bare metal desktop i7 CPU. My laptop i5 took
//     14.2 seconds. This allowed me to make some back of the envelope calculations on how much we needed to
//     optimize some server code. And for Xeon lovers, this quick and dirty benchmark easily showed that
//     not all Xeons are faster than all i7's and that it is even worse if they are throttled, and by how much.
//       The n=304500 number is easy to remember (3,4,5). If I used 300000 it would be harder to see if one
//     is off by one zero with some tiny terminal fonts.
//       That day in June 2014 I wanted a simple loop with no accesses to memory, if possible having
//     everything in registers and the whole loop in the CPU instruction cache. I just wanted to measure the
//     throttled virtual CPU we had in that cloud service.
//       As a benchmark, is not too useful. It only measures a taste of single-thread core performance.
//     And it mostly measures looping and the IDIV assembly instruction (the '%' remainder operator).
//     Comparing different architectures is like comparing apples to oranges. For instance, in some
//     AMD processors, the IDIV instruction takes MUCH more cycles than in Intel CPUs, but there are other
//     instructions that run faster in AMD CPUs. So a real benchmark would try to cover more ground and be
//     more balanced. This of course doesn't prevent me from comparing apples to oranges if I wanted to for
//     the sake of it, with full knowledge of what I'm doing.
//       In the following years, every time I got hold of a computer I tried this non-benchmark on it. Please
//     note that Passmark CPU Benchmark in https://www.cpubenchmark.net/cpu_list.php is better suited to
//     compare AMD and Intel CPUs. But I tested my little C file in an ARM router and cell phones too which
//     that Passmark table won't have entries for. For comparing wildly different architectures, 'nbench' is
//     better suited. But again, there is no nbench implementation for HP48 calculators or Commodore 64 computers.
//       One day, in June 2016, I wondered if a D implementation would be the same speed as the C version
//     and tried it. I quickly then tried PHP, Python, Perl and Ruby in that order for the sake of it.
//     The benchmark is just looping and modulus operations, it doesn't get any simpler than that. So if
//     some programming language is slower than other in just looping and some integer math, the language is
//     slower, period (actually not entirely true: Octave is slow to loop, but is fast in matrix operations,
//     since those are implemented in C, so there are ways to rewrite stuff to take advantage of optimized cases).
//       I then wondered if I could implement the same program in a BASH shell script. Two languages don't get
//     any more different than BASH and C, and the fact that I'm comparing them is bizarre and maybe pointless.
//     But fun nevertheless. When I got to BASH, it wasn't anymore about comparing speed of looping but it
//     became about "could I make the same program, the same benchmark hello world in this other language".
//     Then followed other languages including AWK, TCL, VIM script, Emacs ELisp, LISPs, Windows BATch files,
//     etc. First it was anything for which I had a compiler or interpreter preinstalled in my computer.
//     Then it was anything that was available in the Ubuntu repository, and then more. It became a collection.
//     Something to do in my free time. I grew the collection slowly over the course of the years since 2016.
//     The simplicity of this benchmark makes it extremely portable. If one has a shell prompt to an ebook
//     reader, and all one has is BusyBox as a language, one can use the "benchmark.sh" or "benchmark.awk"
//     files to get a rough idea of the speed of the CPU of that ebook reader.
//
//    -C is THE systems programming language. It was introduced in 1972 by Dennis Ritchie.
//     It is one of the most used programming languages in the world. Almost every platform
//     has a C compiler for it, even for microcontrollers with 16KB of RAM. C is defined in both ANSI
//     and ISO standards (ANSI C99 and ISO C18).
//       C has very low overhead for talking to the machine, although memory and strings need
//     to be manually managed by the developer. Low overhead and manual memory management
//     go well together. But running time comes at the expense of developer time. And although
//     automatic memory management may hide performance issues, manual memory management makes some
//     classes of serious bugs easy to be introduced.
//       C is the language of the first UNIX OS, and both were developed together at Bell Labs in the 70s.
//       C is ideal for writing operating system kernels and drivers.
//       Today, the GNU/Linux kernel is written entirely in C (and most of the GNU user programs),
//     and the Windows kernel and drivers are written in C and a subset of C++.
//     C++ is backwards compatible with C, meaning that many C programs (not all) can be compiled with a
//     C++ compiler (but not vice-versa).
//
//    -Because of its low overhead, C is the language that usually leads benchmark results, and
//     this one is no exception. It's the language to beat (actually, to try to match).
//     Consider the mere existence of the phrase "C like performance".
//     Some languages compile to C instead of assembly.
//
//    -For the 64-bit version of the GCC compiler, int's are 32 bits and long's and size_t
//     are 64 bits wide:
//            #include <stdio.h>
//            int main (int argc, char** argv) {
//                printf("int: %d, long: %d, long long: %d, size_t: %d, float: %d, double: %d, long double: %d\n",
//                       (int) sizeof(int), (int) sizeof(long), (int) sizeof(long long), (int) sizeof(size_t),
//                       (int) sizeof(float), (int) sizeof(double), (int) sizeof(long double));
//                return 0;
//            }
//     Output using 64-bit GCC in Linux:
//            int: 4, long: 8, long long: 8, size_t: 8, float: 4, double: 8, long double: 16
//     Output using 32-bit GCC in Linux:
//            int: 4, long: 4, long long: 8, size_t: 4, float: 4, double: 8, long double: 12
//     In Windows, as opposed to GCC in Linux, 'long' is 32bits even in 64bit Windows.
//
//    -Using the 32-bit version of GCC gives the same speed as the 64-bit version in this test, since
//     ints are 32 bits in both versions. Both use the same IDIV assembly instruction. Other languages
//     use only 64-bit integers in their 64-bit versions, which make them slower for this test.
//     This happens because the remainder operator '%' is faster with smaller CPU registers (IDIV
//     assembly instruction of r32 operands instead of r64 operands).
//     See: https://www.agner.org/optimize/instruction_tables.pdf
//
//    -The percent operator '%' in C and C++ gives the remainder of a division for positive arguments.
//     It differs from the euclidean modulus for negative arguments. The remainder operator in C matches the
//     result of the Intel x86 IDIV instruction.
//
//    -The clock() function measures process CPU time. For Linux in particular, it is implemented using the
//     CLOCK_PROCESS_CPUTIME_ID clock with the clock_gettime() function. That means that clock() will
//     not measure the time spent in sleep functions or child processes. It also means that if the process
//     has multiple threads running, clock() moves faster than a real time clock. When measuring wall clock time
//     is desired, then it is recommended to use clock_gettime() directly, and choosing the
//     CLOCK_MONOTONIC clock for that function. In addition, clock_gettime() can have up to nanosecond
//     precision while clock() is limited to microsecond precision by POSIX and can have even less precision
//     in other OSs. See "man clock" and "man clock_gettime" for more details.
//       The downside of clock_gettime() is that it is POSIX only and not as portable as clock() which
//     is defined by the C standard. The clock() function, as it is, is appropiate for the use given
//     here (timing a computation which doesn't block, do I/O, sleep or spawn child threads or processes).
//
//    -Some compilers are noughty and reorder the call to findPrime() around the calls to clock().
//     The values of 'startTime', 'endTime' and 'elapsed' don't depend on 'count', so the result can
//     be that "Elapsed:  0.000s" is printed even before the computation begins!. That is why I declared
//     the 'startTime', 'count' and 'endTime' variables as volatile, so that the compiler doesn't reorder
//     around volatile writes.
//       This didn't happen to me with GCC but did happen with a different compiler with optimization
//     switches on. I found a very interesting discussion at:
//            "Is it legal for a C++ optimizer to reorder calls to clock()?"
//            https://stackoverflow.com/questions/26190364/is-it-legal-for-a-c-optimizer-to-reorder-calls-to-clock
//     It is not a bug in the compiler and it is allowed by the standard, when the compiler can prove
//     that the code between the clock() calls doesn't have any side effects (no I/O, etc.).
//       The volatile declarations fixed the problem. Adding them didn't change the assembly code
//     generated by GCC for the findPrimes() function and also didn't have any measurable
//     performance impact.
//
//    -With -O3 (and -O2), GCC "cheats" and avoids the IDIV instruction when j == 2, instead first testing
//     the least significant bit and starting the 'j' loop from j == 3 if 'i' wasn't divisible by 2. Thus
//     it avoids executing the IDIV instruction for testing 'i % 2 == 0' and instead tests the LSB bit
//     of 'i'. Pretty smart. Although in my measurements the savings are only about 1ms of a total of
//     about 8.8s for n=304500, which is close to only 0.01%.
//     GCC also does other things with -O3 such as keeping everything in CPU registers and aligning the
//     JMP targets to 16-byte boundaries.
//


#include <stdio.h>
#include <stdlib.h>
#include <time.h>


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
        if (i==j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


//FAST implementation using the Sieve of Eratosthenes algorithm, which is:
//      O(n log(log n))
//but uses lots of RAM: it's O(n) for space.
//
//Notes:
//    -It's crazy fast in comparison to the naive O(n^2) algorithm. But so much that it's
//     harder to use for this simple benchmark (I want something that takes 10 seconds),
//     and one would be benchmarking RAM in addition to CPU. Though I could loop it until
//     it takes 10s, and print how many repetitions it took to get to 10s.
//
//    -Memory consumption can be reduced 8x by using an array of bits instead of bytes.
//
//Execution time is 0.001s for n=304500 and 0.007s for n=3045000 and 0.221s for n=30450000
//and 2.894s for n=304500000.
int findPrimes_SieveOfEratosthenes(int n) {
    char* a;
    int i, p, count;

    //Validate 'n':
    if (n <= 0) {
        return 0;
    }
    if (n > 1024*1024*1024) {
        //Don't want to allocate more than 1GB for this test
        fprintf(stderr, "ERROR: 'n' too big for Sieve of Eratosthenes method (too much RAM required).\n");
        exit(1);
    }

    //Allocate array (cast to char* avoids error with g++):
    a = (char*) malloc((size_t) n+1);
    if (a == NULL) {
        fprintf(stderr, "ERROR: couldn't allocate RAM for Sieve of Eratosthenes.\n");
        exit(1);
    }

    //Initialize as if all numbers are prime (1), except 0 and 1:
    for (i=0; i <= n; ++i) {
        a[i] = 1;
    }
    a[0] = 0;
    a[1] = 0;

    //Iterate up to sqrt(n). Numbers don't have divisors greater than sqrt(n):
    for (p=2; p*p <= n; ) {
        //Eliminate multiples of prime 'p' by eliminating p+p, p+p+p, p+p+p+p, etc.
        //Start from p*p, since we can assume numbers less than p^2 are already covered.
        for (i=p*p; i <= n; i += p) {
            a[i] = 0;
        }
        //Get next prime:
        do {
            ++p;
        } while (p <= n && a[p] == 0);
    }

    //Count prime elements in array:
    count = 0;
    for (i=0; i <= n; ++i) {
        count += a[i];
    }

    free(a);
    return count;
}


int main(int argc, char** argv) {
    int n = 0;
    volatile int count;                   //Using 'volatile' to prevent some compilers from reordering
    volatile clock_t startTime, endTime;  //the call to findPrimes() around the calls to clock().
    double elapsed;

    if (argc != 2) {
        printf("Quick and dirty single thread CPU benchmark - by JMC\n");
        printf("Usage: \n");
        printf("        Pass an argument up to which prime numbers will be searched with\n");
        printf("        an inefficient algorithm, useful to compare the single thread performance\n");
        printf("        of the CPU\n");
        printf("Example: \n");
        printf("        %s 304500\n", argv[0]);
        printf("Notes: \n");
        printf("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n");
        printf("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n");
        printf("        C: it takes 8.075s using GCC 4.8.4 with flags -static -O2 -funroll-loops.\n");
        printf("        C: it takes 8.846s using GCC 4.8.4 with flag -O3 (best time so far with -O3).\n");
        printf("\n");
        return 1;
    }

    n = atoi(argv[1]);
    if (n < 2) {
        fprintf(stderr, "ERROR: Argument '%s' not valid.\n", argv[1]);
        return 1;
    }

    startTime = clock();

    //Naive method:
    count = findPrimes(n);
    //"Sieve of Eratosthenes" method:
    //count = findPrimes_SieveOfEratosthenes(n);

    endTime = clock();
    elapsed = (endTime - startTime) / (double) CLOCKS_PER_SEC;
    printf("Elapsed: %6.3fs\n", elapsed);

    printf("%d prime numbers were found between 2 and %d\n", count, n);

    return 0;
}

