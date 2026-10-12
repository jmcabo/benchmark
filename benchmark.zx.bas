10 rem Benchmark for ZX Spectrum BASIC by JMC
20 rem go to main
30 go to 240
40
50 rem NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
60 rem that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
70 rem but puts the function in a loop and counts 10000 calls).
80 rem Returns how many prime numbers exist between 2 and n:
90
100 rem findPrimes
110 let c = 0
120 rem For each number up to 'n':
130 for i = 2 to n
140     rem NOT using the sqrt optimization (for easier benchmarking).
150     for j = 2 to i-1
160         rem If i divisible by j, it wasn't a prime number:
170         if i = j * int(i/j) then go to 200
180     next j
190     rem If the previous loop ended without divisors found, it is a prime number.
200     if i = j then let c = c + 1
210 next i
220 return
230
240 rem main
250 cls: rem Clear the ZX screen of text written during tape load.
260 print "Quick and dirty single thread"
270 print "CPU benchmark - by JMC"
280 print "Usage: "
290 print "  Pass an argument up to which"
300 print "  prime numbers will be searched"
310 print "Example: "
320 print "  n=304"
330 print "Notes: "
340 print "  Searching up to 304500 in C is"
350 print "  almost exactly 10s on Intel i7"
360 print "  4770K 3.5Ghz"
370 print ""
380 print "  ZX: it takes an estimated 66107414s (765d 3h 10m) for n=304500"
390 print "  For n=304 it takes 153.780s"
400 print "  For n=3045 it takes 10720.920s (2h 59m)"
410 print ""
420
430 input "Search primes up to? "; n
440 if n < 2 then print "ERROR: Argument '"; n; "' not valid." : stop
450
460 def fn t() = 65536 * peek 23674 + 256 * peek 23673 + peek 23672 : rem Number of ticks since computer is on
470 let startTime = fn t()
480 go sub 100
490 let endTime = fn t()
500 print "Elapsed: "; (endTime - startTime) / 50; "s"
510 print c; " primes between 2 and "; n


#Routine without rem comments and gosubs. It is the fastest version. It takes 142.140s for n=304, and 9914.780s for n=3045:
#
#10 rem Benchmark for ZX Spectrum BASIC by JMC
#20 input "Search primes up to? "; n
#30 if n < 2 then print "ERROR: Argument '"; n; "' not valid." : stop
#40 def fn t() = 65536 * peek 23674 + 256 * peek 23673 + peek 23672 : rem Number of ticks since computer is on
#50 let s = fn t()
#60 let c = 0
#70 for i = 2 to n
#80     for j = 2 to i-1
#90         if i = j * int(i/j) then go to 110
#100    next j
#110    if i = j then let c = c + 1
#120 next i
#130 let e = fn t()
#140 print "Elapsed:"; (e - s) / 50; "s"
#150 print c; " primes between 2 and "; n


#Routine without nested FOR. This routine is slower. It takes 185.480s for n=304:
#
#10 rem Benchmark for ZX Spectrum BASIC by JMC
#20 input "Search primes up to? "; n
#30 if n < 2 then print "ERROR: Argument '"; n; "' not valid." : stop
#40 def fn t() = 65536 * peek 23674 + 256 * peek 23673 + peek 23672 : rem Number of ticks since computer is on
#50 let s = fn t()
#60 let c = 0
#70 for i = 2 to n
#80     let j = 2
#90     if j >= i then go to 130
#100        if i = j * int(i/j) then go to 130
#110        let j = j + 1
#120    go to 90
#130    if i = j then let c = c + 1
#140 next i
#150 let e = fn t()
#160 print "Elapsed:"; (e - s) / 50; "s"
#170 print c; " primes between 2 and "; n

#------------------------------------------------------------------------------
#
#Benchmark in BASIC for the ZX Spectrum. Thanks to SplinterGU for research on ZX Spectrum.
#
#Compile (tokenize) to .TAP:
#        zmakebas -a10 -o benchmark.tap benchmark.zx.bas
#
#        (the -a10 argument is for autostarting at line 10, saves having to type RUN.)
#
#Run (for the FBZX emulator):
#        fbzx -nosound benchmark.tap
#
#        #Inside the emulator, type:
#        LOAD ""
#        #(Actually type J CTRL+P CTRL+P. The key for LOAD is J, and the
#        #character for "" is CTRL+P)
#
#        #Then hit F6 to tell it to start "playing the tape".
#        #Once it finishes loading, hit F5 to return to normal speed (it
#        #accelerates while "playing the tape").
#
#Install emulator and basic tokenizer in Ubuntu 17.10:
#        apt-get install fbzx zmakebas
#
#Limitations of BASIC in the ZX Spectrum:
#
#    -Usable screen size is 32 columns by 22 rows (before it asks whether to SCROLL).
#     The usage banner had to be trimmed further from the C64 version (The C64 has 40 columns).
#
#    -The clock time resets every 3.88 days (2^24 / (24*3600*50)), since it's 24bits
#     with a resolution of 50 per second.
#
#    -There are no plain Integer variables (The Commodore 64 has % percent variables that are integer).
#     Variables are either floating point (a) or strings (a$).
#
#    -Floats are stored in 5 bytes. (Variables that don't end in "$").
#     These floats can represent n=304500.
#
#    -Although emulators achieve almost perfect speed accuracy, the result might
#     not be the same as running in a physical ZX Spectrum.
#
#    -No modulus operator.
#
#    -Of course, the following were expected: no exit codes, no STDERR, no
#     proper formatting of floats in PRINTs, no cmd line arguments, no program name (ie: no argv[0]).
#
#    -Having the rem comments inside the loops makes it about 7% slower. I chose to leave them there,
#     all the benchmark files I made for other languages have them.
#     There is also a faster version without rem comments in this file.
#
#    -No WHILEs.
#
#    -GOTO must be used to end a FOR loop early. There is a caveat at least for C64,
#     and that is that there is a maximum number of FOR loops that can be going on at the same time
#     (9 for the C64), and a GOTO to outside of the loop doesn't clear the FOR info from the
#     interpreter's memory. It is no problem though for this program (tested), since the next time
#     a FOR starts with the same variable name, the previous one is retired.
#     FOR loops are faster than IF/GOTO loops, maybe because there are less instructions, but I
#     suspect that it is because GOTOs make the interpreter perform perhaps a linear search for the line
#     with the desired number.
#
#    -No IF blocks: IFs are one line only. No ELSE either. There can be more than one command in
#     the same line separated by ":".
#
#    -The loop counter in a FOR loop must be a single letter floating point variable.
#     The NEXT statement variable is not optional (ie: "NEXT c").
#
#    -All variables are global.
#
#    -The "LET" statement for variable assignments is not optional.
#
#    -As opposed to my Commodore BASIC files, the source file contents doesn't need to be in all
#     lowercase letters. This was a limitation of the "petcat" tool used to compile to .PRG for commodore.
#     With "zmakebas" this problem doesn't exist for the Spectrum, but I chose to leave the commands
#     in lowercase for consistency. The ZX Spectrum has lowercase and uppercase characters by default,
#     although BASIC statements are all in uppercase.
#
#    -ZX Spectrum BASIC is SLOW. Even looping to N=3045 without doing anything inside the loop takes
#     several seconds:
#           FOR a=0 TO 3045: NEXT a
#     Note: To enter this FOR line in ZX Spectrum use the following keys:
#           F a CTRL+L 0 CTRL+F 3045 CTRL+Z N a
#     The clock speed for ZX Spectrum CPUs was 3.5MHz, which more than the 1MHz of the Commodore 64,
#     and in the C version it shows how fast the Spectrum can be. This means that the BASIC implementation
#     for the ZX Spectrum is slower than Microsoft BASIC implementation for the Commodore 64.
#        I tried Z88DK (a C cross compiler for the ZX Spectrum and other machines) and it is
#     about 8.5x faster than the BASIC version. If I cheated and used 16bit integers
#     in C (which can't hold n=304500), it would be about 32x faster than the BASIC version (smaller
#     integers are faster in C since the math operations have to be emulated for an 8bit processor).
#        The Z80 CPU assembly language is very limited: no division and no multiplication.
#     See:
#           "Z80 Assembly - Multiplication and Division"
#           http://sgate.emt.bme.hu/patai/publications/z80guide/part4.html
#     for routines in assembly that implement multiplication and division by hand.
#
#
#------------------------------------------------------------------------------
#Editing tips:
#
#    -Show color bar at column 32 in Vim:
#            set cc=32
#     Turn off:
#            set cc=
#
#    -Create or update line numbers with Vim:
#            s/^\d*\s\?/\=printf("%d ", line(".") * 10)/
#
#
#------------------------------------------------------------------------------
#Material:
#
#ZX Spectrum BASIC manual:
#
#        "SINCLAIR ZX SPECTRUM BASIC Programming"
#        http://www.worldofspectrum.org/ZXBasicManual/index.html
#
#ZX Spectrum Technical Data (speed, size of variables, etc.):
#
#        "ZX Spectrum Technical Data Sinclair Research leaflet, 1982"
#        http://rk.nvg.ntnu.no/sinclair/computers/zxspectrum/spec_technical.htm
#

