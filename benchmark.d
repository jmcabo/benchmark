#! /usr/bin/rdmd --shebang -O -inline -noboundscheck -release

//Benchmark in D by JMC
//
//
//Run:
//    ./benchmark.d 304500
//Compile and run:
//    dmd -O -inline -release -noboundscheck benchmark.d  &&  ./benchmark 304500
//
//
//Notes:
//    -D is a multi-paradigm programming language. It was first released in 2001.
//     Version 2.0 was released in 2007. It started as a better C++ but it has gone far beyond that.
//     It features Garbage Collection, which can be disabled. It supports the following paradigms/features:
//     imperative, object-oriented programming, metaprogramming, functional, parallel, concurrent, DSLs,
//     purity, immutability, etc.
//       It doesn't have C macros but instead it has CTFE, mixins, versioning statements, static ifs,
//     templates, etc.
//       Despite its great abstraction capabilities, it compiles to native code. I think that that is its
//     strength. D code can be as concise and expressive as Python code, while enjoying the speed of native
//     binaries. At the same time, it tries to be more memory-safe than other compiled languages.
//       Another great strength it has is VERY FAST compilation speeds. The author, Walter Bright,
//     made sure that the structure of the language, while he was formulating it, enabled to do
//     many parsing and compiling tasks in one pass. While C and C++ require many passes that cannot
//     be avoided (import vs #include, no C macros, and so on).
//       D has in my opinion the best implementation of templates of any language, thanks to Andrei
//     Alexandrescu who co-authored version 2.0 with Walter Bright.
//       D also features powerful CTFE (compile time function evaluation). Like LISP, it has almost the
//     whole language available at compile time.
//
//    -Ints are always 32 bits for both the 32-bit version of D as for the 64-bit version. Reals are
//     always 80-bits although for reasons of alignment can use 10, 12 or 16 bytes of storage (10 bytes
//     in Windows).
//            import std.stdio;
//            void main() {
//                writeln("int: ", int.sizeof, ", long: ", long.sizeof, ", size_t: ", size_t.sizeof,
//                        ", ptrdiff_t: ", ptrdiff_t.sizeof, ", float: ", float.sizeof,
//                        ", double: ", double.sizeof, ", real: ", real.sizeof);
//            }
//     Output using 64-bit DMD in Linux:
//            int: 4, long: 8, size_t: 8, ptrdiff_t: 8, float: 4, double: 8, real: 16
//     Output using 32-bit DMD in Linux:
//            int: 4, long: 8, size_t: 4, ptrdiff_t: 4, float: 4, double: 8, real: 12
//
//    -A design goal of D is that C code that is pasted in a D program and that compiles without errors,
//     must have the same semantics. It follows that things like the remainder operator '%' work the
//     same as they do in C.
//
//    -Using the 32-bit version of DMD gives the same speed as the 64-bit version in this test, since
//     ints are 32 bits in both versions. Both use the same IDIV assembly instruction. Other languages
//     use only 64-bit integers in their 64-bit versions, which make them slower for this test.
//     This happens because the remainder operator '%' is faster with smaller CPU registers (IDIV
//     assembly instruction of r32 operands instead of r64 operands).
//     See: https://www.agner.org/optimize/instruction_tables.pdf
//
//    -The percent operator '%' in D, C and C++ gives the remainder of a division for positive arguments.
//     It differs from the euclidean modulus for negative arguments. The remainder operator matches the
//     result of the Intel x86 IDIV instruction.
//

import std.stdio;
import std.conv;
import core.time;
import std.path;
import core.memory;


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


int main (string[] args) {
    int n = 0;
    int count;
    TickDuration startTime, endTime;
    double elapsed;

    if (args.length != 2) {
        writeln("Quick and dirty single thread CPU benchmark - by JMC");
        writeln("Usage: ");
        writeln("        Pass an argument up to which prime numbers will be searched with");
        writeln("        an inefficient algorithm, useful to compare the single thread performance");
        writeln("        of the CPU");
        writeln("Example: ");
        writefln("        %s 304500", baseName(args[0]));
        writeln("Notes: ");
        writeln("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        writeln("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        writeln("        D: it takes 8.850s using DMD 2.071.1 with flags -O -inline -release -noboundscheck.");
        writeln("");
        return 1;
    }

    try {
        n = to!int(args[1]);
    } catch (ConvException) {
        n = -1;
    }
    if (n < 2) {
        stderr.writefln("ERROR: Argument '%s' not valid.", args[1]);
        return 1;
    }

    GC.collect();
    startTime = TickDuration.currSystemTick();

    count = findPrimes(n);

    endTime = TickDuration.currSystemTick();
    elapsed = (endTime - startTime).msecs() / 1000.0;
    writefln("Elapsed: %6.3fs", elapsed);

    writefln("%d prime numbers were found between 2 and %d", count, n);

    return 0;
}

