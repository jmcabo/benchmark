/*
Benchmark for HP50g Programmable Calculator in C using the HPGCC 2.0SP2 compiler - by JMC

Instructions:
============
    A. Installing the HPGCC2 C cross compiler
    B. Compile the benchmark
    C. Install the ARMToolbox in the HP50g
    D. Upload cbench.hp and convert to standalone executable
    E. Run the benchmark


A. Installing the HPGCC2 C cross compiler:

    Version 2.0 ServicePack 2 was the last version of the HPGCC2 compiler that could target
    calculators with normal ROMs. There is a newer project called HPGCC3 that targets
    calculators with a custom ROM. HPGCC3 requires you to use a custom ROM while HPGCC2 doesn't.
       HPGCC2 can create standalone binaries, with the help of the ARMToolbox, that don't
    require anything to be installed in the calculator. But I'll need the ARMToolbox to
    be installed in the calculator to convert the resulting HPGCC binary to standalone.
       The produced binaries run directly over the ARM CPU of the HP48Gii, HP49G+ and HP50g
    calculators, skipping the Saturn CPU emulation layer. That is why code made with HPGCC
    runs orders of magnitude faster than System RPL code.

    The compiler is from 2007 and although no more development was done on HPGCC2, it is
    far far more complete and mature than HP48XGCC was for the HP48 series.
    The official website is dead:
            http://hpgcc.org
    but can still be accessed through the Internet Archive:
            https://web.archive.org/web/20080807162446/http://hpgcc.org/

    These instructions are for Linux but it also works in Windows and MacOS.
    For instructions for Windows and MacOS see:

            http://sense.net/~egan/hpgcc/

    I'm not going to use the Sourceforge/HpCalc.org files of the compiler:

            https://sourceforge.net/projects/hpgcc/files/hpgcc/

            https://www.hpcalc.org/details/6384
            https://www.hpcalc.org/hp49/pc/programming/hpgcc-2.0-sp2-linux.tar.bz2

    because Egan Ford prepared a much more complete package:

            http://sense.net/~egan/hpgcc/hpgcc-linux.tgz

    that contains the ARM GCC compiler and linker already there (arm-elf-gcc, arm-elf-ld), ready to go,
    with libraries and examples.
    Otherwise, the HPGCC2 from sourceforge comes with the ARM to HP translator ("elf2hp"),
    and the libraries, but doesn't include the ARM GCC compiler.

    For Linux:
         1. Download HPGCC 2.0SP2 from sense.net:
                 cd /opt
                 sudo wget http://sense.net/~egan/hpgcc/hpgcc-linux.tgz
                 sudo tar xvzf hpgcc-linux.tgz
            A subdirectory called "hpgcc" is created when uncompressing.
            I'll assume it goes in:
                 /opt/hpgcc
            for the rest of these instructions.
         2. The compiler binaries are 32bits, so we need to install libc6:i386 for 64bit Linux:
                 sudo apt-get install libc6:i386
            You can tell if you need libc6:i386 because then the ldd command would show this:
                 $ ldd /opt/hpgcc/2.0SP2/bin/elf2hp
                 not a dynamic executable
         3. Test the compiler:
                 cd /opt/hpgcc
                 . hpgccenv
                 cd test
                 make clean
                 make
            The hpgccenv command needs to be executed with a "." dot so that it sets up
            some environment variables for that terminal session with paths.
            If "make" is successful, then several .hp files are created.
         DONE!
         If you want a different path than "/opt/hpgcc" that's up to you, but
         the rest of these instructions assume that directory.

B. Compile the benchmark

    The following steps create "cbench.hp". They generate intermediate files .o and .exe that can be deleted.
    The output file "cbench.hp" is an HP string that contains inside the ARM instructions in a layout
    suitable for converting to a program with the ARMToolbox library with its S->EXE command in the calculator.
    The ARMToolbox can also run from this string directly, with its PrRUN command.

         #Compile benchmark.hp50.c to cbench.hp (Assuming that HPGCC is at /opt/hpgcc):
         /opt/hpgcc/2.0SP2/cc/bin/arm-elf-gcc -mtune=arm920t -mcpu=arm920t -mlittle-endian -fomit-frame-pointer -msoft-float -Wall -Os -I/opt/hpgcc/2.0SP2/include -L/opt/hpgcc/2.0SP2/lib -mthumb-interwork -mthumb  -c benchmark.hp50.c
         /opt/hpgcc/2.0SP2/cc/bin/arm-elf-ld -L/opt/hpgcc/2.0SP2/lib -T VCld.script /opt/hpgcc/2.0SP2/lib/crt0.o  benchmark.hp50.o -lhpg -lhplib -lgcc -o benchmark.hp50.exe
         /opt/hpgcc/2.0SP2/bin/elf2hp benchmark.hp50.exe cbench.hp

         #Remove intermediate files:
         rm benchmark.hp50.o benchmark.hp50.exe

C. Install the ARMToolbox in the HP50g

    To run "cbench.hp" we first need to install the ARMToolbox library in the calculator to either
    run the the program directly or convert it to stand alone executable.

         1. Upload to the calculator the file:
             /opt/hpgcc/2.0SP2/sources/ARMToolbox/SETUP.BIN
         2. Put number 2 in the stack.
         3. Put the contents of SETUP.BIN in the stack, with
                'SETUP.BIN' RCL  (LSHIFT+K)
            or RSHIFT+NameInSoftMenu
         4. Hit EVAL.
         5. Hit ON+C to warmstart the calculator. The ARMToolbox library is now installed in port 2.

         NOTE: This is not installed like a usual library. Instead of STOring to 2 it must be evaluated
         with the number 2 in the level 2 of the stack.

    It can be uninstalled later by going to the FILER (LSHIFT+G) and then to port 2 and hitting PURGE.

D. Upload cbench.hp and convert to standalone executable

        1. Upload the "cbench.hp" file to the calculator.
        2. Put its content in the stack.
                'cbench.hp' RCL
           or RSHIFT+NameInSoftMenu
           It looks like a string object with binary contents.
        3. Go to ARMToolbox library:
                RSHIFT+2
                ARMTo
        4. Hit NXT menu and run the command:
                S->EXE
           The string object is now converted to a program object.
        5. Store the program object in a variable:
                'CBENCHMARK' STO
        DONE.
        The program can now be run from 'CBENCHMARK'.

    Upload or type in the following launcher, which will time the benchmark:

        (HPGCC C library doesn't have a clock() function with milliseconds).

        %%HP: T(3)A(R)F(.);
        \<<
            I\->R    @Convert to REAL if argument was ZINT.
            TICKS SWAP

            CBENCHMARK

            SWAP TICKS SWAP - B\->R 8192. / 3. RND "Elapsed" \->TAG
            SWAP
        \>>

        Put this in a file (removing indentation) it has to begin with the header "%%HP: T(3)A(R)F(.);"
        in the first line.
        Upload it with kermit to a variable named 'CLAUNCHER' or any name. Or it can be typed in.
        If uploaded with XModem, the ASCIIBIN.49 program that comes with Emu48 might need to be used
        to convert it from a string object to a program object.

E. Run the benchmark

        Type a number up to which to search prime numbers in level 1 of the stack. Example: 30.
        Then hit the soft label key with the 'CLAUNCHER'.
        After the computation, the number of prime numbers shows up in level 1 (Example: 10 for n=30).
        and the elapsed time in seconds in level 2.

        Example:
               +----------------------+                   +----------------------+
               |7:                    |                   |7:                    |
               |6:                    |                   |6:                    |
               |5:                    |                   |5:                    |
               |4:                    |                   |4:                    |
               |3:                    |                   |3:                    |
               |2:                    |                   |2:       Elapsed:0.639|
               |1:                3045|  -> CLAUNCHER ->  |1:                436.|
               +----------------------+                   +----------------------+

        The program cannot be interrupted hitting ON or ON+C, so don't use a very big argument as input.
        It can only be interrupted by inserting a paper clip end through the RESET hole in the back
        of the calculator. Memory is not lost when doing that.

        To see the usage banner with the known measured times, run CBENCHMARK directly with an empty stack.
DONE!


Instructions for Testing in the x49gp Emulator:
==============================================
    A. Introduction to the x49gp
    B. Download the x49gp emulator
    C. Compile the x49gp emulator
    D. Mount the sdcard and transfer "cbench.hp" and SETUP.BIN


A. Introduction to the x49gp

   -The x49gp emulator for Linux and MacOS is the only emulator that will execute C programs
    compiled with HPGCC2 or HPGCC3 because it emulates the underlying ARM CPU. The more established
    emulators like Emu48+ only emulate the Saturn CPU.

   -The author of x49gp is the same author of the x48 Linux emulator:

        "Christian Wendt (chwdt) The programmer previously known as 'Eddie C. Dost'."
        http://www.brainaid.de/people/ecd

   -x49gp Emulator pages:

        "x49gp - The HP49g+ Emulator"
        http://www.brainaid.de/people/ecd/x49gp/

        "HP49g+ Calculator Emulator"
        https://sourceforge.net/projects/x49gp/

   -The emulator doesn't support the clipboard copy/paste, or drag and drop. Files can't be
    transferred by kermit/xmodem I/O. Instead, files can be transferred by mounting
    the "sdcard" file in the filesystem and then transferring files from port 3 in the calculator.

   -The x49gp emulator crashes on new versions of GTK. I was able to make it run in a 32bit Kubuntu 14.04
    VMware virtual machine, but not in 64bit Kubuntu 16.04, Kubuntu 17.10, Arch, nor Debian Unstable. I'm
    not sure whether it is because the Kubuntu 14.04 was 32bits or if it was the version of GTK.
    While it compiles OK, when running it the error received in the distros is:

            $ ./x49gp config
            [...]
            x49gp_modules_init: phys_ram_base: 0x7f1c52f4b000

            (x49gp:2494): Gdk-CRITICAL **: IA__gdk_pixbuf_render_pixmap_and_mask_for_colormap: assertion 'GDK_IS_PIXBUF (pixbuf)' failed
            Segmentation fault (core dumped)

    It works perfectly in a 32bit Kubuntu 14.04 virtual machine.

   -The x49gp emulator runs as fast as it can without rate control, so the benchmark execution times
    in the emulator are not included in this file, because they depend on the host machine, not the
    calculator. This also means that it isn't useful for trying most games since they would go too fast
    (unless the game uses timers correctly for implementing delays). Emu48+ has rate control to
    simulate the actual speed of an HP50g but it can't run programs built with HPGCC because
    Emu48+ doesn't simulate the ARM CPU.

B. Download the x49gp emulator

    There are several forks in GitHub for the x49gp. The one that worked best for me
    was the fork made by the original author of the emulator (not the same person that first
    put it in GitHub, so he had to fork it):

        https://github.com/chwdt/x49gp

    Download:

            git clone https://github.com/chwdt/x49gp.git

C. Compile the x49gp emulator

            #Install prerequisites:
            sudo apt-get install libgtk2.0-dev

            #Compile:
            cd x49gp
            make
            make sdcard
            make config

   Test that it runs:

            ./x49gp config

   To close it, hit ALT+F4 or go to the terminal where x49gp was launched and hit CTRL+C.

D. Mount the sdcard and transfer "cbench.hp" and SETUP.BIN

    Note: Make sure that x49gp is not running before mounting the sdcard file as a directory in Linux.

            #Mount
            mkdir /tmp/mountsd
            sudo mount -o loop sdcard /tmp/mountsd

            #Copy. Note: Make sure all filenames are 8.3 characters
            cp cbench.hp /tmp/mountsd
            cp /opt/hpgcc/2.0SP2/sources/ARMToolbox/SETUP.BIN /tmp/mountsd

            #Unmount
            sudo umount /tmp/mountsd

    Now start x49gp:

            ./x49gp config

    and use the FILER (LSHIFT+G) to go into the SD (port 3) and recall the contents of SETUP.BIN
    and cbench.hp to the stack with the RCL command in the FILER soft label menu. Now you can follow
    the instructions for SETUP.BIN and cbench.hp elsewhere in this file.
    DONE!



Limitations and remarks for the HPGCC2 C cross compiler for HP49G+/HP50g:
========================================================================

    -C programs cannot be interrupted hitting ON or ON+C. When needed, they can only be interrupted by
     inserting a paper clip end through the RESET hole in the back of the calculator.
     The memory is not lost when doing that.

    -The C program doesn't work in Emu48+, only works in real calculators or the x49gp emulator.
     It can crash the emulated calculator if run in Emu48+.

    -Display is 33 columns by 13 rows, with the font that the C libraries use when displaying
     the output of printf(). It is enough for a brief version of the usage banner that will show
     up when no arguments are passed.

    -There is no clock() function, only sys_RTC_seconds() which returns seconds as an int.
     That means that we don't have milliseconds timing in HPGCC C.
        One alternative is to repeat the algorithm until X seconds have elapsed, then
     divide the number of seconds by the number of iterations. But I prefer to use a User RPL
     program as a wrapper that measures the time in TICKS, in this case, because the 'n' argument
     would make the algorithm take very different times for different 'n's.
        The time of the algorithm will have to be measured with 'timeeval', or with a small
     UserRPL program:

            %%HP: T(3)A(R)F(.);
            \<<
                I\->R    @Convert to REAL if argument was ZINT.
                TICKS SWAP

                CBENCHMARK

                SWAP TICKS SWAP - B\->R 8192. / 3. RND "Elapsed" \->TAG
                SWAP
            \>>

    -There is a function "sat_stack_pop_stdargs(&argv)" that can be called to "emulate" main's
     argc and argv but it wasn't what I was looking for. I just used stack functions to get the
     argument.

    -During the hour that the calculator executed the benchmark, its power consumption was
     around 80mA ~ 90mA (the same as when executing the RPL benchmarks). I kept it plugged
     to USB to save batteries, and measured the current with one of those mini USB Testers,
     like the "USB Charger Doctor".

    -By default, the CRT (C Runtime) of HPGCC2 slows down the processor to 12MHz before executing main().
     The speed of the CPU is normally 75MHz. The CRT does this because the CPU is never idle
     when running a C program, even when the program is waiting for a key to be pressed. So the
     downclock to 12MHz is useful for the non-intensive parts of the programs.
     This means that I have to call sys_slowOff() to restore the 75MHz normal clock speed before
     calling findPrimes() for the computation.

    -Of course, the following limitations were expected: no main exit codes in the stack, no STDERR,
     no cmd line arguments except for the stack, no program name (ie: no argv[0]).

    -The C version is 4934x faster than the User RPL version. It's not that User RPL is slow,
     it's actually because the C version is compiled to ARM code that skips the Saturn emulation
     layer (see "benchmark.hp50.rpl").

    -The C version is 841x faster than the System RPL version.

*/


#include <hpgcc49.h>


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


int main(void) {
    double nReal;
    int n, count;

    if (sat_stack_depth() == 0) {
        clear_screen();
        printf("Quick and dirty single thread\n");
        printf("CPU benchmark - by JMC\n");
        printf("Usage: \n");
        printf("  Pass an argument up to which\n");
        printf("  prime numbers will be searched\n");
        printf("Example: \n");
        printf("  n=3045\n");
        printf("Notes: \n");
        printf("  HP50g in C: it takes 3938.247s (1h 6m) for n=304500\n");
        printf("  For n=3045 it takes 0.639s\n");
        printf("  For n=30450 it takes 47.916s");
        WAIT_CANCEL;    //Wait for user to press ON before returning
                        //(the printf's output is lost when the program ends).
        return 1;
    }

    nReal = sat_pop_real();  //Returns 0.0 when the argument is not a REAL or is not present.
    if (nReal < 2) {
        sat_stack_push_string("Error: Argument not valid");
        return 1;
    }
    n = nReal;
    sys_slowOff();      //Run at HP50g calculator factory speed of 75MHz

    count = findPrimes(n);

    sys_slowOn();       //Go back to 12MHz. Those 12MHz are the default in HPGCC for waiting
                        //on keys or doing non-intensive tasks so that the CPU doesn't waste battery.
                        //(CPU is always busy when executing C code).
    sat_push_real(count);
    return 0;
}


