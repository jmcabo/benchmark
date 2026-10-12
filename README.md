# benchmark
A simple Find Primes benchmark written in over 40 languages and run in C64, ZX Spectrum, routers, calculators, emulators, web browsers including Netscape, laptops and PCs.


Timings of different languages
==============================

CPU: Intel i7 4770K 3.5GHz (3.9GHz Turbo)
RAM: 32GB DDR3 1333MHz
OS: Kubuntu 14.04.4 64 bits

        Language                  Time(s)
        ------------------        -------
        C (funroll)                8.075
        node.js                    8.361
        C                          8.846*
        C++                        8.849
        Assembly                   8.849
        D                          8.850
        Pascal (x86)               8.851
        Haskell(x86)               8.854
        Swift                      8.857
        FreeBASIC                  8.860
        Rust                       8.865
        CommonLisp (ECL x86)       8.917
        CommonLisp (GCL x86)       8.939
        C#                         9.017
        Go                         9.502
        CommonLisp (SBCL x86)      9.924
        JavaScript (Chrome)        9.954
        VB.NET                    10.015
        Julia                     10.651
        Java                      10.841
        OCaml (x86)               10.916
        Standard ML (MLton)       11.809
        Standard ML (SML/NJ)      11.818
        Lisp (Chicken x86)        11.912
        PyPy3 (x86)               12.807
        Standard ML (Poly/ML x86) 12.903
        Lisp (MIT Scheme x86)     14.431
        Lisp (TypedRacket x86)    15.781
        Lisp (Racket x86)         16.183
        Forth (Gforth x86)        21.916
        Lisp (Gambit x86)         22.966
        Pascal                    27.653
        C (long x64)              28.554
        CommonLisp (GCL)          28.569
        CommonLisp (ECL)          28.573
        OCaml                     28.602
        CommonLisp (SBCL)         29.537* (x64 newversion)
        Haskell                   29.597
        PythonPyPy3               30.744
        Lisp (Chicken)            30.910
        Standard ML (Poly/ML)     31.863
        Lisp (MIT Scheme)         32.230
        Lisp (TypedRacket)        38.714
        Lisp (Racket)             38.733
        Excel 2007 VB             41.766
        Forth (Gforth)            43.760
        Lisp (Gambit)             44.373
        PHP                       60.672
        Lua                       95.018
        Ruby                       127.2
        Lisp (Guile)               132.6
        AWK                        145.7
        BennuGD                    163.2 (Contributed by SplinterGU)
        CommonLisp (CLISP)         172.0
        Python2                    201.4
        Tcl                        235.2
        JavaScript (WSH)           281.1
        ASP Classic JS             305.1
        GAWK                       309.0
        PowerShell 4               315.6
        Perl                       316.7
        VBScript (WSH)             328.8
        Python3                    377.3
        R (JIT)                    439.7
        ASP Classic VB             457.6
        QuickBasic 7.1             587.9
        Emacs Lisp                 692.6
        Calc calculator            832.8
        R                           1088
        Genius calculator           1821
        bc calculator               1824
        HP50g in C (HPGCC2)         3938
        LibreOffice Basic           4080
        PowerShell 2                5296
        Dash                        8381
        Vim                         8603
        Octave                     13559
        Bash                       13936
        BusyBox                    16812
        Batch (cmd)               143488
        DBase3Plus                215817
        HP50g SysRPL             3311710
        C128 in C (CC65)         7063390
        ZX Spectrum in C         7759555
        HP48GX SysRPL           13792221
        C64 in C (CC65)         14125646
        HP48GX in C xgcc        18097923
        HP50g UserRPL           19430360
        C128 Basic              33061353
        HP48GX UserRPL          47079103
        C64 Basic               49141280
        ZXSpectrum Basic        66107414

Surprises and notes:

        1. node.js is a hair faster than C !! (due to JIT optimization).
        2. BASH is slow, really slow.
        3. BATCH (.BAT) files are almost slower than everything known, by orders of magnitude, except for DBase III Plus,
           which prints each variable assignment, and except for C64 Basic which runs as a 1MHz CPU.
        4. Python3 is slower than Python2 here (due to different integer implementation (arbitrary precision ints)).
        5. Python, Perl are slower than PHP, Ruby.
        6. DASH is faster than BASH.
        7. MAWK is faster than GAWK.
        8. FreePascal, Haskell, PyPy, Gambit-C and others run faster in a 32bits build (using Int32 types doesn't force 32bit modulus with a 64bit build).
           They would be comparable to C if built for 32bits.
           The problem is that they are using the 64bit machine code instruction to perform the modulus, which is slower than the 32bit instruction.
        9. Within ASP Classic, the JavaScript engine is a bit faster than VBScript (about 1.5x).
       10. Vim :echon doesn't write to STDOUT.
       11. QuickBasic compiled executable is faster than the interpreter (about 1.25x), but still very very far from C.
       12. The HP50g calculator is 2.4x faster than the HP48GX in UserRPL and 4.1x faster in System RPL. In C it is 4596x faster because
           it compiles directly to ARM code instead of Saturn assembly code.
       13. I can't believe how slow non-vectorized Octave can be. R is much faster. And it seems
           Octave dropped the JIT engine (I couldn't find a recent version with JIT Compiler support).



Note: Used this to summarize numbers from sources:
    grep '\s*[a-zA-Z0-9_.#/ +-]*:\s*it takes' benchmark* | sed -e 's/.*  \s*\([a-zA-Z0-9_.#/ +-]*\):[^0-9]*\([\.0-9]\+s\).*/\1: \2/' | sort -n -k2 -t:

Sort by creation time (first git log):
    ls benchmark* web_benchmark* | while read f; do echo $(date -d @$(git log --format="%at" --reverse "$f" | head -n1) +"%Y-%m-%d %H:%M:%SZ") "-->" $f; done | sort -n

Get list of languages (actually, unique file extensions):
    ls benchmark* web_benchmark* | sed -e 's/^.*\.\([^.]*\)$/\1/' | sort -u


About this benchmark
====================

Iterations: 3823899402   (3.8BN iterations)
(Iterations with SQRT optimization: 12850441 (12.9M))

It shows how to do these things in each language:

        -Create a standalone program.
        -Shebang or instructions on how to compile in comments at the top.
        -Comments.
        -Read command line arguments (ARGV, etc.)
        -Get the program name (ie: ARGV[0], $0, ENVIRON["_"], etc.)
        -Convert a string to integer and validate it.
        -Exit with a nonzero error code.
        -Print to STDERR.
        -Measure elapsed time in milliseconds.
        -Function declaration syntax, calling, passing arguments and returning a value.
        -Format a float with 3 decimals and space padding up to 6 chars.
        -A couple of loops and arithmetic.

It turned into a sort of "code kata". Something to do for each new language,
and to peruse when one forgets how to start coding a simple standalone program
in some language.


Modulus computations by size of n:
=================================

        n        mod checks
        -------------------
        304      8658
        3045     620138
        30450    47141833
        304500   3823899402

Use this factor to estimate the number of seconds it would take to run with n=304500 knowing
how long it took to run with n=30450:
        t304500  ~=  t30450 * 3823899402 / 47141833
or just:
        t304500  ~=  t30450 * 81.11478

And to estimate from t3045:

        t304500  ~=  t3045 * 3823899402 / 620138
        t304500  ~=  t3045 * 6166.2072


__

