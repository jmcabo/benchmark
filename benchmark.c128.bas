10 rem benchmark for commodore 128 by jmc
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
250 graphic 5
260 fast
270 print "quick and dirty single thread cpu benchmark - by jmc"
280 print "usage: "
290 print "        pass an argument up to which prime numbers will be searched with"
300 print "        an inefficient algorithm, useful to compare the single thread"
310 print "        performance of the cpu"
320 print "example: "
330 print "        n=304"
340 print "notes: "
350 print "        searching up to 304500 takes almost exactly 10 seconds (9.7s) on an"
360 print "        intel i7 4770k @ 3.5ghz with benchmark.c compiled without optimizations"
370 print "        using gcc, and 8.85s with -o3."
380 print "        c128: it takes an estimated 33061353s (382d 15h 43m) for n=304500."
390 print "              for n=304 it takes 77.233s"
400 print "              for n=3045 it takes 5361.700s (1h 29m)"
410 print ""
420 input "search primes up to"; n
430 if n < 2 then print "error: argument '"; n; "' not valid." : end
440 s = time
450 gosub 100
460 e = time
470 print "elapsed:"; (e - s) / 60; "s"
480 print c; "prime numbers were found between 2 and"; n
-- CUT HERE --


Routine without rem comments and gosubs, and using floats. It is the fastest version. It takes 65.567s for n=304 and 4563.817s for n=3045 (in C128 FAST mode):

10 rem benchmark for commodore 128 by jmc
20 graphic 5
30 fast
40 input "search primes up to"; n
50 if n < 2 then print "error: argument '"; n; "' not valid." : end
60 s = time
70 c = 0
80 for i = 2 to n
90     for j = 2 to i-1
100        if i = j * int(i/j) then goto 120
110    next j
120    if i = j then c = c + 1
130 next i
140 e = time
150 print "elapsed:"; (e - s) / 60; "s"
160 print c; "prime numbers were found between 2 and"; n


Routine with BASIC 7.0 DO loop as inner loop. It slower than using FOR. It takes 90.200s for n=304 (in C128 FAST mode):

10 rem benchmark for commodore 128 by jmc
20 graphic 5
30 fast
40 input "search primes up to"; n
50 if n < 2 then print "error: argument '"; n; "' not valid." : end
60 s = time
70 c = 0
80 for i = 2 to n
90     j = 2
100    do while j < i
110        if i = j * int(i/j) then exit
120        j = j + 1
130    loop
140    if i = j then c = c + 1
150 next
160 e = time
170 print "elapsed:"; (e - s) / 60; "s"
180 print c; "prime numbers were found between 2 and"; n


Routine using all integer variables. Surprisingly slower! it takes 97.967s for n=304 (in C128 FAST mode):

10 rem benchmark for commodore 128 by jmc
20 graphic 5
30 fast
40 input "search primes up to"; n%
50 if n% < 2 then print "error: argument '"; n%; "' not valid." : end
60 s = time
70 c% = 0
80 i% = 2
90 do while i% <= n%
100     j% = 2
110     do while j% < i%
120         if i% = j% * int(i%/j%) then exit
130         j% = j% + 1
140     loop
150     if i% = j% then c% = c% + 1
160     i% = i% + 1
170 loop
180 e = time
190 print "elapsed:"; (e - s) / 60; "s"
200 print c%; "prime numbers were found between 2 and"; n%


Routine without nested FORs using an IF/GOTO inner loop. It is slower than using FOR or DO WHILE. It takes 105.200s for n=304 (in C128 FAST mode):

10 rem benchmark for commodore 128 by jmc
20 graphic 5
30 fast
40 input "search primes up to"; n
50 if n < 2 then print "error: argument '"; n; "' not valid." : end
60 s = time
70 c = 0
80 for i = 2 to n
90     j = 2
100    if j >= i goto 140
110        if i = j * int(i/j) then goto 140
120        j = j + 1
130    goto 100
140    if i = j then c = c + 1
150 next
160 e = time
170 print "elapsed:"; (e - s) / 60; "s"
180 print c; "prime numbers were found between 2 and"; n

------------------------------------------------------------------------------

Compile (tokenize) to .PRG:

        head -c `grep -b '\-\- CUT HERE \-\-' benchmark.c128.bas | cut -d':' -f1` benchmark.c128.bas | petcat -w70 -o BENCH.PRG

Run by dragging the file BENCH.PRG and dropping it to a running VICE emulator,
or start the emulator like this:

        x128 BENCH.PRG

Run and Re-Run with the RUN command.

Another way to transfer the routines is to copy them, execute "NEW" (to clear the previous program),
and click "Edit -> Paste" in the VICE emulator. Then execute "RUN".


Differences from C64 Basic:
    -The commands "GRAPHIC 5" and "FAST" are used to switch to 80 column mode
     and FAST mode (double the clock speed to 2MHz).

    -C64 Basic doesn't have DO loops. Although they are not faster than FOR loops, maybe because
     of the extra variable increment line.

    -The usage banner and the result message have been extended to take advantage of the 80 columns.

    -The C128 has PRINT USING, but I can't use it to format elapsed time because when it is
     bigger than the desired "##.###", it prints "******" instead, to show that the
     number is bigger than the format string.


C64 Mode:
    -The routines from the other file "benchmark.c64.bas" can be run in C64 mode. Measurements
     are the same.
    -To enter 64 Mode type:
        GO 64


Limitations and remarks for the Commodore 128:

    -Display can be 80x25 by running the "GRAPHIC 5" command. Run "GRAPHIC 0" to return.
     Otherwise display is 40 columns of text and 25 rows.
     The VICE emulator shows two screens: one for 80 columns mode and another for regular
     mode. This is because the original hardware had two video chips and two physical video
     outputs. The same TV or monitor cannot display both modes, unless an adapter with a
     switch is used.

    -The C128 can run at 2MHZ clock speed (versus about 1MHz of the C64) but that is not
     the default. To switch to that mode, it is required to run the "FAST" command.
     When running in FAST mode, the regular 40x25 screen output is disabled, and only
     the 80 column mode works ("GRAPHIC 5" command). Return to normal using the "SLOW" command.

    -All the speed measurements in this file were done in the "FAST" mode.

    -C128 Basic 7.0 is slower than C64 Basic 2.0 when running in the default mode. It is probably
     because of the added complexity and commands, and one can imagine it is probably using lots of linear
     searches for interpreting keywords. The same Basic program runs slower. This changes
     with the "FAST" command, where the C128 takes the lead, but not by double the speed.
     On the other hand, the C versions of this benchmark do run at almost exactly double the speed
     in C128 FAST mode when compared to the C64 C version.

    -Integers are 16bit (stored in 2 bytes). (Variables that end in "%" percent).

    -Floats are stored in 5 bytes. (Variables that don't end in "%" nor "$").
     Only floats can fit n=304500.

    -Although emulators achieve almost perfect speed accuracy, the result might
     not be the same as running in a physical C128 (I don't have a C128).

    -No modulus operator.

    -The TIME system variable wraps to 0 at 24hs of the computer/emulator being ON.

    -Of course, the following were expected: no exit codes, no STDERR, no
     proper formatting of floats in PRINTs, no cmd line arguments, no program name (ie: no argv[0]).

    -Having the rem comments inside the loops makes it 11% slower. I chose to leave them there,
     all the benchmark files I made for other languages have them.
     There is also a faster version without rem comments in this file.

    -GOTO must be used to end a FOR loop early. There is a caveat at least for C64,
     and that is that there is a maximum number of FOR loops that can be going on at the same time
     (9 for the C64), and a GOTO to outside of the loop doesn't clear the FOR info from the
     interpreter's memory. It is no problem though for this program (tested), since the next time
     a FOR starts with the same variable name, the previous one is retired.
     FOR loops are faster than IF/GOTO loops, maybe because there are less instructions, but I
     suspect that it is because GOTOs make the interpreter perform perhaps a linear search for the line
     with the desired number.

    -Variable names are distinguished up to two characters. I can't use the variable
     name "STARTTIME" since its first two characters are the same as the system variable "STATUS".
     And I can't use a variable named "ENDTIME" since it contains the statement "END".

    -The loop counter in a FOR loop must be a floating point variable. Using an integer
     variable like I% results in a SYNTAX ERROR.

    -All variables are global.

    -The source file contents needs to be in all lowercase letters. Any uppercase letter is converted
     wrong by "petcat". I would have preferred to type the source in uppercase letters for this, matching
     how it looks by default in the C128. The same goes for copy/pasting into the VICE emulator.

    -C128 BASIC is SLOW. Even looping to N=3045 without doing anything inside the loop takes several
     seconds (FOR A=0 TO 3045: NEXT).
     The clock speed for those CPUs was 2MHz.
     Time measurements were made with the VICE emulator in PAL mode.
     I tried CC65 (a C cross compiler for the Commodore 128 and other machines) and it is
     about 4.7x faster than the Basic version. If I cheated and used 16bit integers
     in C (which can't hold n=304500), it would be about 19x faster than the Basic version.


------------------------------------------------------------------------------
Editing tips:

    -Show color bar at column 80 in Vim:
            set cc=80
     Turn off:
            set cc=

    -Create or update line numbers with Vim:
            s/^\d*\s\?/\=printf("%d ", line(".") * 10)/


------------------------------------------------------------------------------
TIPS:

C128 Basic V7.0 reference:

        https://www.c64-wiki.com/wiki/BASIC
        http://www.commodore.ca/manuals/128_system_guide/toc.htm

Install and run the VICE Commodore 128 emulator:

        sudo apt-get install vice

        #Download source tarball
        #       http://vice-emu.sourceforge.net/index.html#download
        #Copy ROMs from source .tgz, from the folder "data" to the installed folder "/usr/lib/vice/"

        #Start:
        x128

Convert a PC text file to a BASIC V7.0 PRG file:

        petcat -w70 -o bench.prg -- benchmark.c128.bas

        (The "petcat" command comes with VICE)

        * The file contents needs to be in lowercase. Any uppercase character is converted to the wrong code in PETSCII.
        * petcat can also be used to convert back PRG files to regular PC files with -70 instead of -w70:

        petcat -70 -o bench.txt -- bench.prg

Execute a .PRG file:

        Drag and drop it to VICE. It will load it automatically. Then RUN it.

        Or start VICE with:

            x128 bench.prg

        Or go to "File -> Smart-attach disk/tape..." menu and select the .PRG. Then execute RUN.

Command to extract PRG files from a D64 disk image:

        c1541 -attach file.d64 -extract

        (The "c1541" command comes with VICE)

How to load and save BASIC programas in VICE to D64 disk images:

        https://formulanath.wordpress.com/2010/06/18/vice-c64-saving-programs-to-disk/

        Save to disk:
            First attach or create a D64 image in VICE.
            SAVE "BENCHMARK", 8

        Show list of files (overwrites program in C128 memory):
            LOAD "$", 8
            LIST

        Load from disk:
            LOAD "BENCHMARK", 8
            LIST
            RUN

--

