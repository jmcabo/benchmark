* Benchmark in System RPL for the HP48GX - by JMC
*
* Instructions:
* ============
*     A. Install the HPTools compiler (rplcomp, sasm and sload).
*     B. Download and compile an "entries.a" file to "entries.o".
*     C. Compile the benchmark
*     D. Upload the benchmark
*     E. Run the benchmark
*
*
* A. Install the HPTools compiler (rplcomp, sasm and sload).
*
*     We'll use version 3.0.8 which was the latest version. The older versions don't run
*     in modern 64bit Windows or post 1998 Linux with libc6.
*
*     The documentation of HPTools 3.0.8 is included only in the source download.
*
*     For Windows:
*         1. Download HPTools 3.0.8 from hpcalc.org:
*                 "HP Tools for Win32 3.0.8"
*                 https://www.hpcalc.org/details/4264
*                 https://www.hpcalc.org/hp48/pc/programming/hptools-3.0.8-win32.zip
*         2. Uncompress it to "C:\hptools"
*         3. Test if it runs:
*                 C:\hptools\rplcomp --help
*         DONE
*
*     For Linux:
*         1. Download HPTools 3.0.8 from hpcalc.org:
*                 "HP Tools for Linux 3.0.8"
*                 https://www.hpcalc.org/details/4265
*                 https://www.hpcalc.org/hp48/pc/programming/hptools-3.0.8-linux-i586.tar.gz
*            For example:
*                 cd /tmp
*                 wget https://www.hpcalc.org/hp48/pc/programming/hptools-3.0.8-linux-i586.tar.gz
*         2. Uncompress it to /opt/hptools
*                 sudo mkdir /opt/hptools
*                 cd /opt/hptools
*                 sudo tar xvzf /tmp/hptools-3.0.8-linux-i586.tar.gz
*            The following binary files show up:
*                 makerom  rplcomp  sasm  sload
*         3. If you are using a 64bit version of Linux, you need to install the 32bit libc6.
*                 sudo apt-get install libc6:i386
*            You can tell if you need libc6:i386 because the ldd command shows this:
*                 $ ldd rplcomp
*                 not a dynamic executable
*            Instead of something like this (ldd gives the list of required libraries):
*                 $ ldd rplcomp
*                 linux-gate.so.1 =>  (0xf7f43000)
*                 libc.so.6 => /lib/i386-linux-gnu/libc.so.6 (0xf7d45000)
*                 /lib/ld-linux.so.2 (0xf7f45000)
*          4. Test rplcomp to see if it runs:
*                 /opt/hptools/rplcomp --help
*          DONE!
*          If you want a different path than "/opt/hptools" that's up to you, but
*          the rest of these instructions assume that directory. You could copy the compilers
*          to "/usr/local/bin" or "/usr/bin", for instance, to have them in the PATH.
*
*     From source (for 64bit binaries or for MacOS):
*
*         1. Download HPTools 3.0.8 source code from hpcalc.org:
*                 "HP Tools Source Code 3.0.8"
*                 https://www.hpcalc.org/details/4263
*                 https://www.hpcalc.org/hp48/pc/programming/hptools-src-3.0.8.tar.gz
*            The source also contains the documentation.
*            For example:
*                 cd /tmp
*                 wget https://www.hpcalc.org/hp48/pc/programming/hptools-src-3.0.8.tar.gz
*         2. Uncompress the source:
*                 cd /tmp
*                 tar xvzf hptools-src-3.0.8.tar.gz
*            A subdirectory named "Hptools" is extracted.
*         3. For 64bit Linux and for MacOS, download and apply this patch:
*                 "HP Tools Source Code Patch"
*                 https://www.hpcalc.org/details/7860
*                 https://www.hpcalc.org/hp48/pc/programming/hptools-src-3.0.8-patch.zip
*            For example:
*                 cd /tmp
*                 wget https://www.hpcalc.org/hp48/pc/programming/hptools-src-3.0.8-patch.zip
*                 unzip hptools-src-3.0.8-patch.zip
*                 #A file named "hptools-pdo-20150503.patch" is extracted
*                 #Now change dir to the extracted sources:
*                 cd Hptools
*                 #Apply the patch:
*                 patch -p1 < ../hptools-pdo-20150503.patch
*         4. Compile the source:
*                 #Change dir to the extracted source:
*                 cd /tmp/Hptools
*                 #We have to call make twice. Once on the source dir, and another in a subdirectory:
*                 make
*                 #The subdirectory that we need is listed in the last line of the output of the first make.
*                 cd x86_64-unknown-linux-gnu
*                 make
*             Binary files rplcomp, sasm, sload and makerom show up in the subdirectory.
*         5. Copy to /opt/hptools:
*                 sudo mkdir /opt/hptools
*                 sudo cp rplcomp sasm sload makerom /opt/hptools/
*            DONE!
*         6. Optional: Copy the documentation
*                 cd /tmp/Hptools
*                 sudo cp -r doc /opt/hptools/
*
* B. Download and compile an "entries.a" file to "entries.o".
*
*     The entries file contains the list of pointers to functions that you can call from SysRPL.
*     It is specific to the calculator version. For HP50g it would be a different file than for HP48GX.
*
*     Don't try to use an old existing "ENTRIES.O" file because the .o object files have a different
*     format in HPTools 3.0.8. We must get an "entries.a" file and compile it with sasm to "entries.o".
*
*     1. Download entries.a from HpCalc.org:
*
*            ".a Entry Points" For HP48
*            Description: Complete supported ROM entry point list (supromentr.a) and
*                         User RPL entry point list (userentr.a) in .a files for use
*                         with HP Tools or GNU Tools.
*            https://www.hpcalc.org/details/1785
*            https://www.hpcalc.org/hp48/programming/entries/entriesa.zip
*
*     2. Extract the "entriesa.zip" file. Two files show up: "SupRomEntr.a" and "UserEntr.a".
*        We can ignore "UserEntr.a".
*     3. Rename "SupRomEntr.a" to "entries.a".
*     4. Obtain "entries.o" by compiling with sasm:
*            Windows:
*                c:\hptools\sasm entries.a
*            Linux:
*                /opt/hptools/sasm entries.a
*     5. Copy "entries.o" to C:\hptools (for Windows) or /opt/hptools/ (for Linux).
*            Linux:
*                sudo cp entries.o /opt/hptools/
*     DONE
*
* C. Compile the benchmark program:
*
*     Make sure you have both "benchmark.hp48.s" and "benchmark.hp48.m".
*
*     Windows:
*            c:\hptools\rplcomp benchmark.hp48.s
*            c:\hptools\sasm benchmark.hp48.a
*            c:\hptools\sload -H benchmark.hp48.m
*
*         It's easier if you put those commands in a .bat file for single click compilation.
*
*     Linux:
*           /opt/hptools/rplcomp benchmark.hp48.s
*           /opt/hptools/sasm benchmark.hp48.a
*           /opt/hptools/sload -H benchmark.hp48.m
*
*         In linux you can put them in a single line for practicality:
*           /opt/hptools/rplcomp benchmark.hp48.s && /opt/hptools/sasm benchmark.hp48.a && /opt/hptools/sload -H benchmark.hp48.m
*
*     The output is in "benchmark.bin".
*     Don't forget to pass the -H option to sload or the result won't be a true HP48 binary.
*     To check, open benchmark.bin with a text editor, and the first characters should be "HPHP48".
*
*     If you are missing the file "benchmark.hp48.m", the contents is the following:
*
*         -- CUT HERE -------------------------------------
*         ** Benchmark in System RPL for the HP48GX - by JMC
*         **
*         ** This .m file accompanies "benchmark.hp48.s". It contains directions for the linker (sload)
*         ** to generate "benchmark.bin".
*         ** Unfortunately these directions cannot be passed as command line arguments, and this extra file is required.
*         ** See "SLOAD.DOC" inside "HP Tools Source Code 3.0.8" for its syntax.
*         ** NOTE: make sure to pass -H to sload:
*         **       sload -H benchmark.hp48.m
*         **
*         TITLE Benchmark for HP48 in SysRPL
*         OUTPUT benchmark.bin
*         ** Uncomment LLIST to supress printed output of SLOAD and have it written to the timeeval.lr file:
*         **   LLIST benchmark.hp48.lr
*         SUPPRESS XREF
*         ** Put here the correct path to your entries.o:
*         **   SEARCH /opt/hptools/entries.o
*         SEARCH c:\hptools\entries.o
*         REL benchmark.hp48.o
*         END
*         -- CUT HERE -------------------------------------
*
* D. Upload the benchmark:
*
*     Upload the compiled file "benchmark.bin" to the HP48 as a variable in a directory.
*     For Emu48: Drag and drop "benchmark.bin" to Emu48. Type 'benchmark' in single quotes then hit STO.
*
* E. Run:
*     Type a number up to which to search prime numbers in level 1 of the stack. Example: 30.
*     Then hit the soft label key with the 'benchmark'.
*     After the computation, the number of prime numbers shows up in level 1 (Example: 10 for n=30).
*     and the elapsed time in seconds in level 2.
*
*     Example:
*            +----------------------+                   +----------------------+
*            |4:                    |                   |4:                    |
*            |3:                    |                   |3:                    |
*            |2:                    |                   |2:     Elapsed: 24.871|
*            |1:                 304|  -> benchmark ->  |1:                  62|
*            +----------------------+                   +----------------------+
*
*     To interrupt the program, hit ON+C. It cannot be interrupted by just repeatedly pressing ON.
*
*
*
* Limitations and remarks for HP48 System RPL:
* ===========================================
*
*     -See "benchmark.hp48.rpl" for more notes and limitations of the calculator.
*
*     -This language is a lot of fun. It's made up from simple concepts: the stack and commands.
*      It has a somewhat high barrier to entry because there is a lot of notation to learn.
*      The Kalinowski and Dominik book is excellent ("Programming in System RPL" 2nd Edition).
*      It is freely available on the web.
*        What's incredible is that SysRPL can manipulate code objects like data. Few languages
*      can do that. Not only we can assign a code block to a variable and call it, we can
*      decompose it and change it at runtime, then glue it together again.
*
*     -There are two types of comments: (1) Whole line comments, in which the first character
*      of the line needs to be an asterisk. (2) Inline comments with parentheses, for which
*      there needs to be space surrounding the parentheses.
*
*     -System RPL was invented by HP to have a high level language in which to write OS level
*      code. The biggest cited difference between System RPL and User RPL is that commands in
*      System RPL are faster because they don't do so much argument and type checking
*      of their inputs from the stack.
*
*     -A SysRPL program is a sequence of commands and immediate values. Each pointer to a command
*      takes 2.5 bytes (5 nibbles, 20 bits). Immediate values take more space.
*      Even control flow changing commands like IT (if-then), case and DO LOOP are pointers to
*      commands.
*      Commands are executed. Immediate values are pushed on the stack.
*      The immediate values are preceeded by a prologue command like DOREAL or DOBINT. But that's
*      only visible in the generated ".A" file.
*      Commands can manipulate the instruction pointer and the return stack, that is how
*      control flow and loops are implemented. Everything is a command.
*      Command implementations exist in the ROM.
*      The "Entries.A" file, contains a big list of commands in the form of 5 nibble constants. They
*      are actually pointers in the ROM to implementations in machine code.
*      That is why SysRPL for HP48 is almost source compatible with SysRPL for HP50g but not
*      binary compatible (they may have the same routines in the ROM but they are not at the
*      same offsets).
*
*     -The Saturn CPU addresses memory by nibbles (half bytes). Pointers can address up to 20bits.
*      2^20 is 1048576, but instead of 1MBytes, it can address only 512KB, since its pointers
*      target nibbles. There is bank switching going on to address more.
*
*     -The types of numeric variables are a bit different from User RPL. In User RPL we only
*      had Reals and Binary Integers. In System RPL we have:
*            -Reals
*            -BINTs  (20 bit integers)
*            -HXS    ("hexadecimal strings", equivalent to User RPL's Binary Integers but can have more digits).
*            -Flags: TRUE or FALSE  (ie: Booleans. In User RPLs we just used 1 or 0)
*      The most interesting type is BINT. It has 20bits, goes from 0 to 1048576. It is unsigned.
*      Most System RPL functions deal with BINTs. For instance, the parameter to PICK must
*      be a BINT. The version of the DEPTH command for System RPL returns a BINT, while the User RPL
*      version returned a real.
*         If a BINT is left in the stack by a SysRPL program, it is shown between angular brackets
*      like <2h> or <0h>. There is no way in UserRPL to convert those to reals (but there is in
*      SysRPL or with a SYSEVAL). The TYPE command returns 20 for BINTs. Looking up 20 in the
*      "HP48 User's Guide" manual, the type 20 means "System Binary Integer".
*
*     -I'm able to use BINTs for the algorithm since 20bit BINTs can represent n=304500.
*
*     -BINTs are entered with a hash sign and are always hexadecimal: # 1C
*
*     -Reals are entered with a percent sign: % 1.2
*
*     -There are shortcuts for entering immediate numbers. Entering a real number like this % 2.0
*      takes 10.5 bytes (8 bytes plus the prolog). Entering it like this %2 occupies 2.5 bytes in
*      the executable. What it is is actually a pointer to somewhere in the ROM where there
*      is an object with prolog and value 2.0. There are many like this.
*
*     -There are shortcuts for some operations and that may affect readability at first.
*      For instance the object #2<> is the same as the two objects #2 #<> together.
*      Another example is the shortcut %1+ for %1 %+ (increment real in the stack by one).
*      One takes 2.5 bytes while the other two take 5 bytes.
*      They take half the space in the executable, and sometimes may be faster because one saves
*      one or two pushes to the stack.
*
*     -DO LOOPs are faster than WHILEs. Maybe because there are more operations left for the ROM
*      routines in assembly to do, like loop guard and counter increment.
*
*     -DO LOOPS are almost like FOR NEXT loops in User RPL except for a couple of things:
*          -The START and STOP limits of iteration are inverted. The first one is the STOP and
*           the second one is the START.
*          -DO LOOPs need the STOP and START values to be expressed as BINTs. Also, the loop
*           counter is a BINT. (In User RPL, FOR's used reals).
*          -DO LOOPs iterate up to and including STOP-1. That means that to put 1 2 3 in the stack,
*           you have to do the following:
*               4 1 DO  INDEX@  LOOP
*           But in User RPL's FOR NEXT it was just:
*               1 3 FOR I  I  NEXT
*          -They still iterate at least once no matter the STOP START range, same as FORs.
*           I think that that's because the loop condition is checked in the LOOP command.
*           The following:
*               3 3 DO  INDEX@  LOOP
*           Produces a 3 in the stack. No matter the STOP limit, the loop is executed at least
*           once with INDEX@ being equal to START.
*          -We still don't have a BREAK command to exit early from DO LOOPs. We have options
*           though: (A) Exit with ERRJMP/ERRTRAP, (B) Overwrite the loop counter with INDEXSTO,
*           or (C) change the STOP limit with ISTOPSTO or ZEROISTOPSTO.
*           It is said there is no BREAK command because it is a structured language, but the
*           reality is that this is so because of the way in which everything is a command object
*           in System RPL, even control structures. DO is a function and LOOP is another,
*           and a BREAK function wouldn't have enough context to do its thing (it wouldn't "know"
*           where the LOOP function is, so as to jump after it. At least not during the first iteration).
*
*     -In System RPL, code blocks are called "secondaries". They start with a :: and end with ;
*      Actually, the :: represents the DOCOL command and the ; represents the SEMI command.
*      To push a secondary to the stack instead of executing it, use the ' command.
*      The single quote command pushes the following object and advances execution past it.
*      This is how the findPrimes subroutine is defined so that it can be bound to a variable,
*      and then later called by EVALuating that variable.
*
*     -I found that the number of objects in the stack affects the speed of RPL programs (both
*      UserRPL and SystemRPL programs).
*      When measuring the speed of the program, I always clear the stack except for the argument.
*      Also, I found that the presence of a Stack Replacement program running in the calculator
*      also affected the speed of RPL programs. I had the "Java Cappuccino 3.6a" stack replacement
*      running (it gives you one extra visible stack level) and by disabling it the RPL code got
*      about 4% faster.
*      The C (HP48xgcc) version doesn't seem to be affected, maybe because it doesn't use the stack
*      inside the 'for' loops.
*
*     -The SysRPL version is 3.4x faster than the UserRPL version.
*
*
* Useful links - Books and References
* ===================================
*
* The Kalinowski and Dominik SysRPL "bible":
*
*         "Programming in System RPL" 2nd Edition by Kalinowski and Dominik
*         https://www.hpcalc.org/details/5142
*         https://www.hpcalc.org/hp49/docs/programming/progsysrpl_pdf.zip
*
* Entry Reference for SysRPL and UserRPL:
*
*     This one contains a list of all the functions you can call using SysRPL with a short description:
*
*         "HP48G Entry Reference" by Dominik and Rast and Kalinowski 2005
*         https://staff.fnwi.uva.nl/c.dominik/hpcalc/entries/hp48g/entries.pdf
*
*     The same exact PDF is also found in hpcalc.org under the title:
*
*         "HP 48 entries, PDF extract from the Database 2.11" by Dominik and Rast and Kalinowski
*         https://www.hpcalc.org/details/5475
*         https://www.hpcalc.org/hp48/programming/entries/entriesdb48pdf.zip
*
* The Donnelly book:
*
*         Full title: "An Introduction to HP 48 System RPL and Assembly Language Programming"
*         "Introduction to System RPL and Assembly Language" by James Donnelly 2009
*         https://www.hpcalc.org/details/7114
*         https://www.hpcalc.org/hp48/docs/programming/jdsysasm.zip
*
*     The jdsysasm.zip file contains the PDF and then a "disk.zip" file. In it there are many
*     example SysRPL source files.
*
* The User Manual of the HP48 calculator:
*
*         "HP 48G Series User's Guide"
*         https://www.hpcalc.org/details/3937
*         https://support.hp.com/us-en/product/hp-48gx-graphing-calculator/33566/manuals
*
*     Appendix G contains a list of all User RPL commands (but no SysRPL).
*
* Programacion en System RPL Con Debug4x:
*
*         "Manual System RPL con Debug 4x" by Cesar Vasquez Alvarado 2012
*         Filename: "System RPL con Debug 4x 18 de enero de 2012.zip"
*         https://sites.google.com/site/cesarv1821/manual-system-rpl-con-debug-4x
*         https://cesarv.jimdo.com/manual-system-rpl-con-debug-4x/
*
*     A spanish version of the Kalinowski and Dominik book, but with extra
*     chapters and library creation with Debug4x.
*     That website also has emulators for the HP50g and connectivity tools and very
*     interesting stuff.
*
*
* Usage banner (doesn't fit in the calculator screen):
* ===================================================
*
*        Quick and dirty single thread CPU benchmark - by JMC
*        Usage:
*                Pass an argument up to which prime numbers will be searched with
*                an inefficient algorithm, useful to compare the single thread performance
*                of the CPU
*        Example:
*                n=304
*        Notes:
*                Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz
*                with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.
*                HP48GX SysRPL: it takes an estimated 13792221s (159d 15h 10m) for n=304500
*                               For n=30 it takes 0.592s
*                               For n=304 it takes 28.270s
*                               For n=3045 it takes 2236.743s (37m)
*                Emu48 in Authentic Speed SysRPL: it takes an estimated 13281233s (153d 17h 14m) for n=304500
*                                                 For n=30 it takes 0.573s
*                                                 For n=304 it takes 24.871s
*                                                 For n=3045 it takes 2153.874s (36m)
*
*


TITLE Benchmark for HP48 in SysRPL

* Best routine in the file. The one used for measurements.
*
*    Real HP48GX: Execution time is 0.592s for n=30 and 28.270s for n=304 and 2236.743s (37m) for n=3045.
*
*    Emu48: Execution time is 0.573s for n=30 and 24.871s for n=304 and 2153.874s (36m) for n=3045.
*
*    Using:
*        -Argument checking: Program message when empty arguments, and error message when n<2 or not Real.
*        -Named local variables for main, but no extra variables for findPrimes.
*        -Subroutines (BIND code object to LAM findPrimes and EVAL)
*        -DO LOOPS
*        -Early exit of inner DO LOOP with ERRJMP/ERRTRAP.
*        -BINTs (Faster than reals)
*        -BINT modulus (actually it's the division #/ which also returns the modulus (remainder)).

ASSEMBLE
    NIBASC /HPHP48-Z/
RPL
::
    CK0NOLASTWD         ( Don't require any argument in the stack. Not sure if necessary )
    DEPTH #0=           ( TRUE if depth is zero )
    case ::             ( Execute block if stack depth is zero and then skip rest of the program )
        $ "Benchmark for HP48\0ain SysRPL by JMC"
        DO$EXIT         ( Exit displaying error string. Similar to DOERR )
    ;

    CK1NOLASTWD         ( Check if at least one argument, else fail. Not sure if necessary )


*   NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
*   that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
*   but puts the function in a loop and counts 10000 calls).
*   Returns how many prime numbers exist between 2 and n:
    ( findPrimes )
    ' ::
        ( Initial count 0: )
        #0 SWAP
        ( For each number up to 'n': )
        %1 %+ COERCE #2 DO
            ERRSET ::
                ( This IF-THEN is necessary because RPL's "DO" always performs at )
                ( least one iteration. It checks the exit condition at LOOP: )
                INDEX@ #2<> IT ::
                    INDEX@
                    INDEX@ #2 DO   ( NOT using the sqrt optimization for easier benchmarking )
                        ( If i divisible by j, it wasn't a prime number: )
                        DUP
                        INDEX@
                        #/                  ( BINT division returns both the modulus and the quotient, like Intel's IDIV )
                        DROP                ( DROP the quotient )
                        #0=                 ( TRUE if modulus is 0 )
                        IT ::
                            ( Jump to "ERRTRAP" )
                            DROP            ( Remove i from the stack before jumping )
                            ERRJMP
                        ;
                    LOOP
                    DROP
                ;
                ( The previous loop ended without divisors found. It is a prime number. )
                ( Increment prime count present in the stack: )
                #1+
            ;
            ERRTRAP ::
                ( Do nothing if number wasn't prime )
            ;
        LOOP
        UNCOERCE            ( Convert count to real )
    ;

    ( main )
    %0 %0 { LAM n  LAM findPrimes  LAM startTime  LAM count }
    BIND
        TRUE                ( Push argumentNotValid flag as TRUE to stack )
        LAM n TYPEREAL?     ( TRUE if argument is a Real )
        IT ::
            LAM n %2 %>=    ( TRUE if argument >= 2 )
            IT ::
                DROP FALSE  ( Change argumentNotValid flag to FALSE )
            ;
        ;
        case ::             ( Execute block if argumentNotValid and then skip rest of the program )
            LAM n
            $ "ERROR:\0aArgument not valid"
            DO$EXIT         ( Exit displaying error string. Similar to DOERR )
        ;

        GARBAGE
        CLKTICKS ' LAM startTime STO   ( Measure startTime )

        LAM n
        LAM findPrimes EVAL            ( Execute findPrimes on n )
        ' LAM count STO

        CLKTICKS            ( Measure endTime )
        LAM startTime       ( Recall startTime )
        bit-                ( Subtract endTime and startTime as HXS )
        #>%                 ( Convert ticks as HXS to real )
        % 8192              ( Push real 8192.0 to the stack )
        %/                  ( Divide TICKS by 8192 to obtain it in seconds )
        %3                  ( Push real 3.0 )
        RNDXY               ( Round the seconds to three decimal places )
        $ "Elapsed"         ( Push string "Elapsed" to the stack )
        >TAG                ( Tag number of seconds with "Elapsed" string )

        LAM count           ( Prime count result in level 1 )
    ABND                    ( Remove local variables )
;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using DO LOOPS and early exit with ERRJMP/ERRTRAP.
* This is the same as the first one in the file, but it is a simplified version without complicated
* argument handling, without subroutines, and with less comments. Easier for typing on an actual
* calculator when there is no link cable available.
*
*    Emu48: Execution time is 0.550s for n=30 and 24.615s for n=304 and 2146.781s (36m) for n=3045.
*
* It is still the same horribly slow O(n^2) algorithm as usual. To make it a bit faster
* for actual use in the calculator, use the SQRT(i) loop limit by changing this line:
*                 INDEX@ #2 DO
* to:
*                 INDEX@ UNCOERCE %SQRT COERCE #1+ #2 DO
* That would make it O(n * sqrt(n)).
* But remember that the point of these benchmarks is the comparison of performance
* of raw iteration among different languages by using always the same horrible algorithm.
* And also, how to do the same basic programming tasks across all of them (measuring time,
* looping, calling functions, printing errors, etc.). Nothing else.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    #0 SWAP
*    %1 %+ COERCE #2 DO
*        ERRSET ::
*            ( This IF-THEN is necessary because RPL's "DO" always performs at )
*            ( least one iteration. It checks the exit condition at LOOP: )
*            INDEX@ #2<> IT ::
*                INDEX@
*                INDEX@ #2 DO
*                    DUP
*                    INDEX@
*                    #/                  ( BINT division returns both the modulus and the quotient, like Intel's IDIV )
*                    DROP                ( DROP the quotient )
*                    #0=                 ( TRUE if modulus is 0 )
*                    IT ::
*                        DROP            ( Remove i from the stack before jumping )
*                        ERRJMP
*                    ;
*                LOOP
*                DROP
*            ;
*            #1+                         ( Increment prime count )
*        ;
*        ERRTRAP ::
*        ;
*    LOOP
*    UNCOERCE
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using DO LOOPS and early exit through assignment of the STOP limit (ZEROISTOPSTO).
* It is easier to follow than the ERRJMP/ERRTRAP version.
* It is faster for smaller n's but get slower at n=3045.
*    Emu48: Execution time is 0.451s for n=30 and 24.196s for n=304 and 2199.836s (37m) for n=3045.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    #0 SWAP
*    %1 %+ COERCE #2 DO
*        TRUE
*        ( This IF-THEN is necessary because RPL's "DO" always performs at )
*        ( least one iteration. It checks the exit condition at LOOP: )
*        INDEX@ #2<> IT ::
*            INDEX@
*            INDEX@ #2 DO
*                DUP
*                INDEX@
*                #/                  ( BINT division returns both the modulus and the quotient, like Intel's IDIV )
*                DROP                ( DROP the quotient )
*                #0=                 ( TRUE if modulus is 0 )
*                IT ::
*                    ZEROISTOPSTO
*                    SWAP NOT SWAP
*                ;
*            LOOP
*            DROP
*        ;
*        IT ::
*            #1+                     ( Increment prime count )
*        ;
*    LOOP
*    UNCOERCE
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using REALs instead of BINTs to perform the modulus. The rest is the
* same as above: DO LOOPS and early exit through assignment of the STOP limit (ZEROISTOPSTO).
* It's much slower than using BINTs.
* Can't use reals as loop counters for DO LOOPS, so they have to have an UNCOERCE conversion every time.
*    Emu48: Execution time is 0.688s for n=30 and 47.635s for n=304.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    #0 SWAP
*    %1 %+ COERCE #2 DO
*        TRUE
*        ( This IF-THEN is necessary because RPL's "DO" always performs at )
*        ( least one iteration. It checks the exit condition at LOOP: )
*        INDEX@ #2<> IT ::
*            INDEX@
*            UNCOERCE
*            INDEX@ #2 DO
*                DUP
*                INDEX@ UNCOERCE
*                %MOD
*                %0=
*                IT ::
*                    DUP COERCE INDEXSTO
*                    SWAP NOT SWAP
*                ;
*            LOOP
*            DROP
*        ;
*        IT ::
*            #1+                     ( Increment prime count )
*        ;
*    LOOP
*    UNCOERCE
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using DO LOOPS and JINDEX@ instead of the stack for the outer loop variable. Slower than using the stack.
*    Emu48: Execution time is 0.453s for n=30 and 34.302s for n=304 and 2820.704s (47m) for n=3045.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    #0 SWAP
*    %1 %+ COERCE #2 DO
*        TRUE  ( Push noDivisorsFound flag to the stack as true )
*        ( This IF-THEN is necessary because RPL's "DO" always performs at )
*        ( least one iteration. It checks the exit condition at LOOP: )
*        INDEX@ #2<>
*        IT ::
*            INDEX@ #2 DO
*                JINDEX@
*                INDEX@
*                #/                  ( BINT division returns both the modulus and the quotient, like Intel's IDIV )
*                DROP                ( DROP the quotient )
*                #0=                 ( TRUE if modulus is 0 )
*                IT ::
*                    ZEROISTOPSTO
*                    NOT
*                ;
*            LOOP
*        ;
*        IT ::
*            #1+                     ( Increment prime count )
*        ;
*    LOOP
*    UNCOERCE
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using WHILEs and local variables. Slow because of the named local variables.
*    Emu48: Execution time is 2.408s for n=30 and 122.211s for n=304.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    COERCE #0 #0 #0 TRUE { LAM n LAM i LAM j LAM count LAM noDiv } BIND
*    #2 ' LAM i STO
*    BEGIN
*      LAM i LAM n #> NOT
*    WHILE ::
*        TRUE ' LAM noDiv STO
*        #2 ' LAM j STO
*        BEGIN
*          LAM j LAM i #<
*          LAM noDiv
*          AND
*        WHILE ::
*            LAM i LAM j #/ DROP #0=
*            IT ::
*                FALSE ' LAM noDiv STO
*            ;
*            LAM j #1+ ' LAM j STO
*        ;
*        REPEAT
*        LAM noDiv
*        IT ::
*            LAM count #1+ ' LAM count STO
*        ;
*        LAM i #1+ ' LAM i STO
*    ;
*    REPEAT
*    LAM count
*    UNCOERCE
*    ABND
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using WHILEs and unnamed local variables. Better than named variables.
*    Emu48: Execution time is 0.954s for n=30 and 50.893s for n=304.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    COERCE #0 #0 #0 TRUE { NULLLAM NULLLAM NULLLAM NULLLAM NULLLAM } BIND
*                         ( n       i       j       count   noDiv   )
*                         ( 5       4       3       2       1       )
*    #2 4PUTLAM
*    BEGIN
*      4GETLAM 5GETLAM #> NOT
*    WHILE ::
*        TRUE 1PUTLAM
*        #2 3PUTLAM
*        BEGIN
*          3GETLAM 4GETLAM #<
*          1GETLAM
*          AND
*        WHILE ::
*            4GETLAM 3GETLAM #/ DROP #0=
*            IT ::
*                FALSE 1PUTLAM
*            ;
*            3GETLAM #1+ 3PUTLAM
*        ;
*        REPEAT
*        1GETLAM
*        IT ::
*            2GETLAM #1+ 2PUTLAM
*        ;
*        4GETLAM #1+ 4PUTLAM
*    ;
*    REPEAT
*    2GETLAM
*    UNCOERCE
*    ABND
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using WHILEs and less local variables. Not much difference for count and noDiv in the stack.
*    Emu48: Execution time is 0.916s for n=30 and 49.945s for n=304.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    COERCE #0 #0 { NULLLAM NULLLAM NULLLAM } BIND
*                 ( n       i       j       )
*                 ( 3       2       1       )
*    #0                       ( count = 0 )
*    #2 2PUTLAM
*    BEGIN
*      2GETLAM 3GETLAM #> NOT
*    WHILE ::
*        TRUE                 ( noDiv = TRUE )
*        #2 1PUTLAM
*        BEGIN
*          DUP
*          1GETLAM 2GETLAM #<
*          AND
*        WHILE ::
*            2GETLAM 1GETLAM #/ DROP #0=
*            IT ::
*                DROP FALSE   ( noDiv = FALSE )
*            ;
*            1GETLAM #1+ 1PUTLAM
*        ;
*        REPEAT
*        IT ::
*            #1+              ( count = count + 1 )
*        ;
*        2GETLAM #1+ 2PUTLAM
*    ;
*    REPEAT
*    UNCOERCE
*    ABND
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using WHILEs and without local variables (everything in the stack).
* Some difference from using local variables, but still slower than DO LOOPS.
*    Emu48: Execution time is 0.884s for n=30 and 48.326s for n=304.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    COERCE                             ( n to BINT )
*    #0                                 ( count = 0 )
*    #2                                 ( i = 2 ) ( stack: n count i )
*    BEGIN
*      DUP 4PICK #> NOT                 ( While i <= n )
*    WHILE ::                           ( stack: n count i )
*        TRUE                           ( noDiv = TRUE )
*        #2                             ( j = 2 )
*        BEGIN                          ( stack: n count i noDiv j )
*          DUP 4PICK #<                 ( stack: n count i noDiv j isLess )
*          3PICK                        ( stack: n count i noDiv j isLess noDiv )
*          AND
*        WHILE ::                       ( While j < i ) ( stack: n count i noDiv j )
*            3PICK OVER #/ DROP #0=
*            IT ::                      ( stack: n count i noDiv j )
*                SWAP DROP FALSE SWAP   ( noDiv = FALSE )
*            ;
*            #1+                        ( stack: n count i noDiv j )
*        ;
*        REPEAT
*        DROP                           ( stack: n count i noDiv )
*        IT ::                          ( stack: n count i )
*            SWAP #1+ SWAP              ( count = count + 1 )
*        ;
*                                       ( stack: n count i )
*        #1+                            ( i = i + 1 )
*    ;
*    REPEAT
*    DROP                               ( stack: n count )
*    SWAP DROP                          ( stack: count )
*    UNCOERCE                           ( count to REAL )
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------


* Routine using reals, ie: floats, instead of BINTs, and WHILEs and without using local
* variables (everything in the stack).  Slower than using BINTS.
*    Emu48: Execution time is 1.154s for n=30 and 65.980s for n=304.

*ASSEMBLE
*    NIBASC /HPHP48-Z/
*RPL
*::
*    CK1NOLASTWD CKREAL
*
*    ( startTime )
*    GARBAGE CLKTICKS SWAP
*
*    ( findPrimes )
*    ( For each number up to 'n': )
*    %0                                 ( count = 0 )
*    %2                                 ( i = 2 ) ( stack: n count i )
*    BEGIN
*      DUP 4PICK %<=                    ( While i <= n )
*    WHILE ::                           ( stack: n count i )
*        TRUE                           ( noDiv = TRUE )
*        %2                             ( j = 2 )
*        BEGIN                          ( stack: n count i noDiv j )
*          DUP 4PICK %<                 ( stack: n count i noDiv j isLess )
*          3PICK                        ( stack: n count i noDiv j isLess noDiv )
*          AND
*        WHILE ::                       ( While j < i ) ( stack: n count i noDiv j )
*            3PICK OVER %MOD %0=
*            IT ::                      ( stack: n count i noDiv j )
*                SWAP DROP FALSE SWAP   ( noDiv = FALSE )
*            ;
*            %1+                        ( stack: n count i noDiv j )
*        ;
*        REPEAT
*        DROP                           ( stack: n count i noDiv )
*        IT ::                          ( stack: n count i )
*            SWAP %1+ SWAP              ( count = count + 1 )
*        ;
*                                       ( stack: n count i )
*        %1+                            ( i = i + 1 )
*    ;
*    REPEAT
*    DROP                               ( stack: n count )
*    SWAP DROP                          ( stack: count )
*
*    ( Elapsed time with tag in level 2 )
*    SWAP CLKTICKS SWAP bit- #>% % 8192 %/ %3 RNDXY
*    $ "Elapsed" >TAG
*    SWAP
*;

*-- CUT HERE -- --------------------------------------------------------------

