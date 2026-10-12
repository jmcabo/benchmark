10 rem benchmark for commodore 64 by jmc
20 rem go to main
30 goto 240
40
50 rem naive implementation. horribly o(n^2), and without using sqrt optimization (on purpose so
60 rem that it takes longer and is easier to benchmark. the 'sysbench' utility, uses the optimization
70 rem but puts the function in a loop and counts 10000 calls).
80 rem returns how many prime numbers exist between 2 and n:
90
100 rem findprimes
110 c = 0
120 rem for each number up to 'n':
130 for i = 2 to n
140     rem not using the sqrt optimization (for easier benchmarking).
150     for j = 2 to i-1
160         rem if i divisible by j, it wasn't a prime number:
170         if i = j * int(i/j) then goto 200
180     next j
190     rem if the previous loop ended without divisors found, it is a prime number.
200     if i = j then c = c + 1
210 next i
220 return
230
240 rem main
250 print ""
260 print "quick and dirty single thread"
270 print "cpu benchmark - by jmc"
280 print ""
290 print "usage: "
300 print "  pass an argument up to which prime"
310 print "  numbers will be searched with an inef-";
320 print "  ficient algorithm, useful to compare"
330 print "  single thread performance of the cpu"
340 print ""
350 print "example: "
360 print "  n=304"
370 print ""
380 print "notes: "
390 print "  searching up to 304500 in c is almost"
400 print "  exactly 10s on intel i7 4770k 3.5ghz"
410 print ""
420 print "  c64: it takes an estimated 49141280s"
430 print "       (568d 18h 21m) for n=304500."
440 print "  for n=304 it takes 114.667s"
450 print "  for n=3045 it takes 7969.450s(2h13m)"
460 print ""
470 input "search primes up to"; n
480 if n < 2 then print "error: argument '"; n; "' not valid." : end
490 s = time
500 gosub 100
510 e = time
520 print "elapsed:"; (e - s) / 60; "s"
530 print c; "primes found between 2 and"; n
-- CUT HERE --


Routine without rem comments and gosubs, and using floats. It is the fastest version. It takes 103.017s for n=304 and 7173.700s for n=3045:

10 rem benchmark for commodore 64 by jmc
20 input "search primes up to"; n
30 if n < 2 then print "error: argument '"; n; "' not valid." : end
40 s = time
50 c = 0
60 for i = 2 to n
70     for j = 2 to i-1
80         if i = j * int(i/j) then goto 100
90     next j
100    if i = j then c = c + 1
110 next i
120 e = time
130 print "elapsed:"; (e - s) / 60; "s"
140 print c; "primes found between 2 and"; n


Routine without nested FORs using an IF/GOTO inner loop. It is slower than using FOR. It takes 151.883s for n=304:

10 rem benchmark for commodore 64 by jmc
20 input "search primes up to"; n
30 if n < 2 then print "error: argument '"; n; "' not valid." : end
40 s = time
50 c = 0
60 for i = 2 to n
70     j = 2
80     if j >= i goto 120
90         if i = j * int(i/j) then goto 120
100        j = j + 1
110    goto 80
120    if i = j then c = c + 1
130 next
140 e = time
150 print "elapsed:"; (e - s) / 60; "s"
160 print c; "primes found between 2 and"; n


Routine using all integer variables (FORs only accept floats). Surprisingly slower! it takes 166.450s for n=304:

10 rem benchmark for commodore 64 by jmc
20 input "search primes up to"; n%
30 if n% < 2 then print "error: argument '"; n%; "' not valid." : end
40 s = time
50 c% = 0
60 i% = 2
70 if i% > n% goto 160
80      j% = 2
90      if j% >= i% goto 130
100         if i% = j% * int(i%/j%) goto 130
110         j% = j% + 1
120     goto 90
130     if i% = j% then c% = c% + 1
140     i% = i% + 1
150 goto 70
160 e = time
170 print "elapsed:"; (e - s) / 60; "s"
180 print c%; "primes found between 2 and"; n%

------------------------------------------------------------------------------

Compile (tokenize) to .PRG:

        head -c `grep -b '\-\- CUT HERE \-\-' benchmark.c64.bas | cut -d':' -f1` benchmark.c64.bas | petcat -w2 -o BENCH.PRG

Run by dragging the file BENCH.PRG and dropping it to a running VICE emulator,
or start the emulator like this:

        x64 BENCH.PRG

Re-Run with the RUN command.

Another way to transfer the routines is to copy them, execute "NEW" (to clear the previous program),
and click "Edit -> Paste" in the VICE emulator. Then execute "RUN".


Limitations and remarks for the Commodore 64:

    -The Commodore 64 was the first computer I programmed for. I was 8 years old.
     This brings back me good memories. Although I can't believe how limited the language
     is in retrospective.

    -Display is 40 columns of text and 25 rows. Max for a line of program is
     two lines of the screen when input interactively.

    -Integers are 16bit (stored in 2 bytes). (Variables that end in "%" percent).

    -Floats are stored in 5 bytes. (Variables that don't end in "%" nor "$").
     Only floats can represent n=304500.

    -Although emulators achieve almost perfect speed accuracy, the result might
     not be the same as running in a physical C64 (I have one C64, but it's not in good shape).

    -No modulus operator.

    -The TIME system variable wraps to 0 at 24hs of the computer/emulator being ON.

    -Of course, the following were expected: no exit codes, no STDERR, no
     proper formatting of floats in PRINTs, no cmd line arguments, no program name (ie: no argv[0]).

    -Having the rem comments inside the loops makes it 11% slower. I chose to leave them there,
     all the benchmark files I made for other languages have them.
     There is also a faster version without rem comments in this file.

    -No WHILEs.

    -GOTO must be used to end a FOR loop early. There is a caveat at least for C64,
     and that is that there is a maximum number of FOR loops that can be going on at the same time
     (9 for the C64), and a GOTO to outside of the loop doesn't clear the FOR info from the
     interpreter's memory. It is no problem though for this program (tested), since the next time
     a FOR starts with the same variable name, the previous one is retired.
     FOR loops are faster than IF/GOTO loops, maybe because there are less instructions, but I
     suspect that it is because GOTOs make the interpreter perform perhaps a linear search for the line
     with the desired number.

    -No IF blocks: IFs are one line only. No ELSE either. There can be more than one command in
     the same line separated by ":".

    -Variable names are distinguished up to two characters. I can't use the variable
     name "STARTTIME" since its first two characters are the same as the system variable "STATUS".
     And I can't use a variable named "ENDTIME" since it contains the statement "END".

    -The loop counter in a FOR loop must be a floating point variable. Using an integer
     variable like I% results in a SYNTAX ERROR.

    -All variables are global.

    -The source file contents needs to be in all lowercase letters. Any uppercase letter is converted
     wrong by "petcat". I would have preferred to type the source in uppercase letters for this, matching
     how it looks by default in the C64. The same goes for copy/pasting into the VICE emulator.

    -C64 BASIC is SLOW. Even looping to N=3045 without doing anything inside the loop takes several
     seconds (FOR A=0 TO 3045: NEXT).
     The clock speed for those CPUs was about 1MHz (depending on whether it was the PAL or NTSC version).
     Time measurements were made with the VICE emulator in PAL mode.
     I'd like to try CC65 (a C cross compiler for the Commodore 64 and other machines).
     The 6502 assembly language is very limited: only 3 registers (8bit), and no division nor
     multiplication.
     UPDATE: I tried C in the C64 with the CC65 compiler!! It is about 3.5x
             faster than the Basic version.
             If I cheated and used 16bit integers in C (which can't hold n=304500),
             it would be 14x faster than the Basic version.


------------------------------------------------------------------------------
Editing tips:

    -Show color bar at column 40 in Vim:
            set cc=40
     Turn off:
            set cc=

    -Create or update line numbers with Vim:
            s/^\d*\s\?/\=printf("%d ", line(".") * 10)/


------------------------------------------------------------------------------
TIPS:

C64 Basic V2 reference:

        https://www.c64-wiki.com/wiki/BASIC

Install and run the VICE Commodore 64 emulator:

        sudo apt-get install vice

        #Download source tarball
        #       http://vice-emu.sourceforge.net/index.html#download
        #Copy ROMs from source .tgz, from the folder "data" to the installed folder "/usr/lib/vice/"

        #Start:
        x64

Convert a PC text file to a BASIC V2 PRG file:

        petcat -w2 -o bench.prg -- benchmark.c64.bas

        (The "petcat" command comes with VICE)

        * The file contents needs to be in lowercase. Any uppercase character is converted to the wrong code in PETSCII.
        * petcat can also be used to convert back PRG files to regular PC files with -2 instead of -w2:

        petcat -2 -o bench.txt -- bench.prg

Execute a .PRG file:

        Drag and drop it to VICE. It will load it and automatically RUN it too.

        Or start VICE with:

            x64 bench.prg

        Or go to "File -> Smart-attach disk/tape..." menu and select the .PRG. Then execute RUN.

Command to extract PRG files from a D64 disk image:

        c1541 -attach file.d64 -extract

        (The "c1541" command comes with VICE)

How to load and save BASIC programas in VICE to D64 disk images:

        https://formulanath.wordpress.com/2010/06/18/vice-c64-saving-programs-to-disk/

        Save to disk:
            First attach or create a D64 image in VICE.
            SAVE "BENCHMARK", 8

        Show list of files (overwrites program in C64 memory):
            LOAD "$", 8
            LIST

        Load from disk:
            LOAD "BENCHMARK", 8
            LIST
            RUN

--

