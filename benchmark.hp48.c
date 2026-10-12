/*
Benchmark in C for the HP48GX using the HP48xgcc C compiler - by JMC

Instructions:
============
    A. Install the C cross compiler
    B. Upload C libraries to the HP48
    C. Compile the benchmark
    D. Upload the benchmark
    E. Run the benchmark
    F. Install and run "timeeval" for measuring elapsed time.


A. Installing the HP48GX cross compiler:

    Version 1.0.1 is recommended over version 1.0.2. In the latest version, they removed
    the push() function from libc (who knows why?), and they added some files for the HP49
    that interfere.
    This benchmark works with both versions though.
    The compiler is old and doesn't work for Windows 7 64bits, or any modern version of Linux.
    It works in 32bit versions of Windows (I tested with both WinXP and Win7).

    For 32bit Windows (instructions for version 1.0.1):
        1. Download "hp48xgcc-1.0.1-win95.zip" from hpcalc.org:
                https://www.hpcalc.org/hp48/pc/programming/hp48xgcc-1.0.1-win95.zip
                https://www.hpcalc.org/details/3793
           Don't mind that it says "win95" in the filename; it works for Windows XP
           and Windows 7 32 bits, and probably any 32bit Windows or Virtual Machine.

        2. Unzip "hp48xgcc-1.0.1-win95.zip" to "C:\". A directory called "C:\usr" will be created.
           Don't unzip to a subdirectory because that doesn't work. The hp48xgcc compiler has \usr hardcoded.

        3. To test if it works, go to the samples directory and compile hello.c:
                cd c:\usr\saturn-local-hp48\samples\hello\
                c:\usr\bin\xgcc.exe -o hello -Wall -O2 -lcore hello.c
           No errors are expected. It should create a single file named "hello"
           without an extension.
        DONE


    For 32bit Windows (instructions for version 1.0.2):
        1. Download "hp48xgcc-1.0.2-win32-bin.zip" from:
                https://sourceforge.net/projects/hp48xgcc/files/
                http://hp48xgcc.sourceforge.net/hp48xgcc.htm

        2. Unzip "hp48xgcc-1.0.2-win32-bin.zip" to "C:\". A directory called "C:\usr" will be created.
           Don't unzip to a subdirectory because that doesn't work. The hp48xgcc compiler has \usr hardcoded.

        3. Version 1.0.2 includes both libraries for HP48 and HP49. The older version 1.0.1
           only included libraries for HP48.
           Go to the folder:
                c:\usr\lib\gcc-lib\saturn-local-hp48\2.7.2\
           The files "crt0.o" and "lib*.slo" that are there are for HP49 by default for version 1.0.2.
           Since I'm targetting the HP48GX, copy the files in the subdirectory:
                c:\usr\lib\gcc-lib\saturn-local-hp48\2.7.2\hp48\
           to that directory:
                copy hp48\*.* .
           This is important to avoid crashes and avoid the following error:
                MALFUNCTION:
                library not found: hp48/libm.slo

        4. To test that it works, go to the samples directory and compile hello.c:
                cd c:\usr\saturn-local-hp48\samples\hello\
                c:\usr\bin\xgcc.exe -o hello -Wall -O2 -lcore hello.c
           No errors should be displayed. It should create a single file named "hello"
           without an extension.
        DONE

    For Linux:
        The binary release for linux "hp48xgcc-1.0.1-linux_fromHpCalc.org.zip"
        doesn't work because it is from before 1998, when Linux used an alternative Libc called Libc5
        instead of GLibC. I haven't tried finding a virtual machine that can run it,
        but maybe an old Mandrake or RedHat distribution will do, since they kept supporting libc5
        for longer.
        It might be possible to create the compiler from source but I haven't tried.
        The source is a file named "hp48xgcc-1.0.2-source.zip" in sourceforge:
                https://sourceforge.net/projects/hp48xgcc/files/
        The tgz for GCC 2.7.2 is required and there is a link to it in HP48xgcc manual:
                http://hp48xgcc.sourceforge.net/hp48xgcc.htm

    For Windows 64bit:
        The compiler doesn't run in a 64bit Windows 7. Windows displays a message saying
        that it isn't compatible with 32bit applications when running xgcc.exe.
        It might be possible to recompile it from source for 64bits, I haven't tested that.


B. Upload C libraries to the HP48:
    1. Go to:
            c:\usr\saturn-local-hp48\download\       (for HP48xgcc version 1.0.1)
            c:\usr\saturn-local-hp48\download\hp48\  (for HP48xgcc version 1.0.2)
    2. Upload the following files to a directory in the calculator:
       These are not calculator libraries, they don't go to Port 0.
       They go into regular variables of a directory in the calculator.
            GCCLDD
            libgcc.sl
            libcore.sl
            libc.sl
            libm.sl
       The case must be respected. GCCLDD is all uppercase and the others are all lowercase.
       To enter lowercase letters, use ALPHA LSHIFT+ALPHA.
       For Emu48: Drag and drop the files one at a time to Emu48, for each one
                  type the name (ie: 'GCCLDD') then hit STO.

C. Compile the benchmark program:
    Run:
        c:\usr\bin\xgcc.exe -o benchmark -Wall -O2 -lcore -lm benchmark.hp48.c

    a file named "benchmark" is created. No errors or warnings should be expected.

D. Upload the benchmark:

    Upload the compiled file "benchmark" to the HP48 as a variable in the same directory
    as the libs were uplodaded ('GCCLDD', 'libc.sl', etc.).
    For Emu48: Drag and drop "benchmark" to Emu48. Type 'benchmark' then hit STO.
               make sure it goes in the same directory as the C libs.

E. Run:
    Type a number up to which to search prime numbers in level 1 of the stack. Example: 30.
    Hit the soft label key with the 'benchmark'.
    After a computation, the number of prime numbers shows up: Example: 10 (for n=30).

    The result is undefined if there is no number in level 1 before executing
    the program. (The C library only gives pop_real(), it doesn't allow to check the stack depth,
    and the User RPL or System RPL functions, like DEPTH, can't be called).

    To interrupt the program, hit ON+C. It cannot be interrupted by just repeatedly pressing ON.

F. Install and run "timeeval" for measuring elapsed time:

    A separate tool is needed to measure elapsed time, such as "timeeval", available from:
             https://www.hpcalc.org/details/2729
             https://www.hpcalc.org/hp48/utils/time/timeeval.zip
    Extract the ZIP file and upload "timeeval.bin" to a directory variable in the calculator,
    for best results do it in the same directory as the benchmark and the libs.
    For Emu48: Drag and drop "timeeval.bin" to Emu48, type 'timeeval' (or any name) and hit STO.

    It evaluates the program in stack level 1 and returns the elapsed time in milliseconds.
    The program "timeeval" is implemented in System RPL and it comes with the source.
    Example:
        Type a number (ie: 304), then type the name of the benchmark variable in
        quotes (ie: 'benchmark'), and then hit the key for timeeval:

        +----------------------+                   +----------------------+
        |4:                    |                   |4:                    |
        |3:                    |                   |3:                  62|
        |2:                 304|                   |2:              354452|
        |1:         'benchmark'|   -> timeeval ->  |1:        43268.066_ms|
        +----------------------+                   +----------------------+

    The number in level 1 is the elapsed time in milliseconds.
    The number in level 2 is the elapsed time in ticks that when divided
    by 8192 gives the same number of seconds as the milliseconds in level 1 (timeeval
    returns both numbers).
    The number in level 3, in this example, is the count of prime numbers up to n=304 that
    were found by the benchmark.

DONE
--


Tips and Notes:
==============

How to see the intermediate .s compiled file in assembly:
    Execute:
        c:\usr\bin\xgcc.exe -save-temps  -o benchmark -c -Wall -O2 -lcore -lm benchmark.hp48.c

    and a file named "benchmark.s" with the resulting assembly code shows up,
    and also a file named "benchmark.i" that is the output of the preprocessor.
    The key is in the "-save-temps" and "-c" arguments.

Assembly:
    The assembly language used by the HP48xgcc compiler is not the same syntax as taught in books
    for the HP48. The source code file "hp48xgcc-1.0.2-source.zip" contains the source
    and documentation for the special assembler used, which is called:
            "CLASS - The Clarke Assembler" - made by Lutz Vieweg in 1991
    It contains the documentation for that syntax in the file:
            "<hp48xgcc source dir>/saturn/class/class.doc"



Limitations and remarks for HP48xgcc compiler:
=============================================
    -See "benchmark.hp48.rpl" for more notes and limitations of the calculator.

    -The C compiler for the HP48 was a work in progress. HP48xgcc only implements a few C library
     functions and operators. It's sad that it stopped growing, I would have liked it a lot.
     In the end, the language in which all serious HP48 programs were written was System RPL.

    -This HP48xgcc compiler is not the same as the HP-GCC compiler. The first one is for HP48 and HP49
     (Saturn CPUs). The HP-GCC on the other hand, is for calculators with ARM CPUs like the HP49g+ and HP50g.

    -Can't call User RPL or System RPL code from C or assembly. This is the biggest limitation.
     I think that if they had found a way to do it, then this compiler would have been more
     popular and it would have grown a lot more.
     UPDATE: I found a discussion in comp.sys.hp48 that talks about calling GARBAGE from what
             looks like assembly language, but I'm not sure if it can be adapted to calling
             other functions:
                 "comp.sys.hp48 > Garbage Collection - a question to ML guru's"
                 https://groups.google.com/forum/#!topic/comp.sys.hp48/TooFgO_Hs3c/discussion

    -No clock() or printf() implemented in the C library. Neither are argv[], sprintf(), sscanf()
     nor scanf().

    -No elapsed time. Can't use TICKS (User RPL) or CLKTICKS (System RPL) from C or assembly.
     And since the C library that comes from the compiler doesn't implement clock(),
     that means that this benchmark won't measure elapsed time.
     A separate tool is needed to measure elapsed time, such as "timeeval" (see instructions above).

    -float and double are equivalent, both use 64bit HP48 floating point values
     with 12BCD digits mantissa. Enough to represent n=304500.
     float, double correspond to REALs and int corresponds to BININTs.

    -Cast from int to float doesn't work. Cast from float to int works.

    -There is no modulus for ints and no fmod() for floats (linker complains they
     don't exist and looking at the source, they aren't implemented):
         "ERROR: unable to resolve symbol '___moddi3'."
         "ERROR: unable to resolve symbol '_fmod'"
     There was a patch available in 2007 that seems to add the modulus operator
     for ints, but to use it, the whole HP48xgcc compiler needs to be compiled from source.
     I tried using it by embedding the ___moddi3 routine from the patch using
     the inline asm() into the source code, and it produced the same result as when dividing
     two ints: halts or crashes.

    -If I try to divide an int by another int, the program compiles but halts or crashes
     when running it. So I'm using floats instead for findPrimes().

    -The Saturn CPU of the HP48 series doesn't implement neither division nor multiplication
     as processor instructions.

    -No STDERR, no proper formatting of floats as strings, no cmd line arguments except
     for the stack (pop_real()), no program name (ie: no argv[0]), no program usage banner.

    -The C version is 2.6x faster than the UserRPL version. It's not as fast as the SysRPL
     version because I couldn't use ints and modulus in the C version due to problems in the
     HP48xgcc compiler.


Usage banner (doesn't fit in the calculator screen):
===================================================

       Quick and dirty single thread CPU benchmark - by JMC
       Usage:
               Pass an argument up to which prime numbers will be searched with
               an inefficient algorithm, useful to compare the single thread performance
               of the CPU
       Example:
               n=304
       Notes:
               Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz
               with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.
               HP48GX C: it takes an estimated 18097923s (209d 11h 12m) for n=304500
                         For n=30 it takes 0.696s
                         For n=304 it takes 40.562s
                         For n=3045 it takes 2935.017s (49m)
               Emu48 in Authentic Speed C: it takes an estimated 19348362s (223d 22h 33m) for n=304500
                                           For n=30 it takes 0.727s
                                           For n=304 it takes 43.268s
                                           For n=3045 it takes 3137.806s (52m)

*/


#include <string.h>
#include <math.h>

#include <hp48/object.h>
#include <hp48/core.h>
#include <hp48/stack.h>


//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
double findPrimes(double n) {
    double i, j;
    double count = 0;

    //For each number up to 'n':
    for (i=2; i <= n; ++i) {
        for (j=2; j < i; ++j) {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if (i == j * floor(i / j)) {
                break;
            }
            //This doesn't compile/link:
            //if (fmod(i, j) == 0) {
            //    break;
            //}
        }
        if (i == j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


//Pushes a REAL to the stack and exits the program:
void exitWithFloat(double r) {
    hp_object* obj;

    //Request memory for object:
    obj = sys_malloc(5 + 2 * sizeof (double));
    if (!obj) {
        exit(1);
    }
    //Fill in object type (prolog):
    obj->prolog = 0x2933;
    //Fill real (double):
    obj->_hide.real = r;

    sys_exit(obj);
}


//Pushes a string to the stack and exits the program:
void exitWithString(char* s) {
    int length = strlen(s);
    hp_object* obj;

    //Request memory for object:
    obj = sys_malloc(length * 2 + 10);
    if (obj == 0) {
        exit(1);
    }
    //Fill in object type (prolog):
    obj->prolog = 0x02A2C;
    //Fill length:
    obj->_hide.string.length = length * 2 + 5;
    //Fill string contents not including \0 terminator:
    memcpy(obj->_hide.string.body, s, length);

    sys_exit(obj);
}


int main (int argc, char* argv[]) {
    double n;
    double count;

    //Get n from the stack.
    //The result is undefined if there isn't a number in stack level 1. There
    //are no C library functions available to determine the size of the stack or the
    //type of object in level 1. And we can't call DEPTH (User RPL) from C or assembly.
    n = pop_real();
    if (n < 2) {
        //Can't call DOERR to display an error from C. So pushing a string to
        //the stack is the only way:
        exitWithString("ERROR: Argument not valid.");
    }

    count = findPrimes(n);

    exitWithFloat(count);

    //If exiting this way, the exit code is pushed to the stack as a BININT:
    //  exit(0);
    //
    //The return value of main is pushed in the stack as a BININT.
    //If main is declared returning void, then garbage is pushed to the stack.
    //Better exit with something else with exitWithFloat() before return.
    return 0;
}


