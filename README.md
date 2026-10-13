# BENCHMARK
Copyright (c) 2014, 2016, 2018, 2019, Juan Manuel Cabo. All Rights Reserved.

A simple Find Primes benchmark written in over 40 languages and run in C64, ZX Spectrum, routers, calculators, emulators, web browsers including Netscape, laptops and PCs.
The CPU mostly loops around the IDIV assembly language instruction, very simple, which implements the modulus operator. Each language has more or less overhead over that simple loop.
As simple as it gets, and yet, some languages add too much overhead.

Link to github:  https://github.com/jmcabo/benchmark


Link from here to 7zip containing the whole directory: https://zenstep.com.ar/wp-content/uploads/2026/10/benchmark_localgit_2026-10-13.7z


Timings of different languages
=========================

CPU: Intel i7 4770K 3.5GHz (3.9GHz Turbo)
RAM: 32GB DDR3 1333MHz
OS: Kubuntu 14.04.4 64 bits

        Language Time(s)
        ------------------ -------
        C (funroll) 8.075
        node.js 8.361
        C 8.846*
        C++ 8.849
        Assembly 8.849
        D 8.850
        Pascal (x86) 8.851
        Haskell(x86) 8.854
        Swift 8.857
        FreeBASIC 8.860
        Rust 8.865
        CommonLisp (ECL x86) 8.917
        CommonLisp (GCL x86) 8.939
        C# 9.017
        Go 9.502
        CommonLisp (SBCL x86) 9.924
        JavaScript (Chrome) 9.954
        VB.NET 10.015
        Julia 10.651
        Java 10.841
        OCaml (x86) 10.916
        Standard ML (MLton) 11.809
        Standard ML (SML/NJ) 11.818
        Lisp (Chicken x86) 11.912
        PyPy3 (x86) 12.807
        Standard ML (Poly/ML x86) 12.903
        Lisp (MIT Scheme x86) 14.431
        Lisp (TypedRacket x86) 15.781
        Lisp (Racket x86) 16.183
        Forth (Gforth x86) 21.916
        Lisp (Gambit x86) 22.966
        Pascal 27.653
        C (long x64) 28.554
        CommonLisp (GCL) 28.569
        CommonLisp (ECL) 28.573
        OCaml 28.602
        CommonLisp (SBCL) 29.537* (x64 newversion)
        Haskell 29.597
        PythonPyPy3 30.744
        Lisp (Chicken) 30.910
        Standard ML (Poly/ML) 31.863
        Lisp (MIT Scheme) 32.230
        Lisp (TypedRacket) 38.714
        Lisp (Racket) 38.733
        Excel 2007 VB 41.766
        Forth (Gforth) 43.760
        Lisp (Gambit) 44.373
        PHP 60.672
        Lua 95.018
        Ruby 127.2
        Lisp (Guile) 132.6
        AWK 145.7
        BennuGD 163.2 (Contributed by SplinterGU)
        CommonLisp (CLISP) 172.0
        Python2 201.4
        Tcl 235.2
        JavaScript (WSH) 281.1
        ASP Classic JS 305.1
        GAWK 309.0
        PowerShell 4 315.6
        Perl 316.7
        VBScript (WSH) 328.8
        Python3 377.3
        R (JIT) 439.7
        ASP Classic VB 457.6
        QuickBasic 7.1 587.9
        Emacs Lisp 692.6
        Calc calculator 832.8
        R 1088
        Genius calculator 1821
        bc calculator 1824
        HP50g in C (HPGCC2) 3938
        LibreOffice Basic 4080
        PowerShell 2 5296
        Dash 8381
        Vim 8603
        Octave 13559
        Bash 13936
        BusyBox 16812
        Batch (cmd) 143488
        DBase3Plus 215817
        HP50g SysRPL 3311710
        C128 in C (CC65) 7063390
        ZX Spectrum in C 7759555
        HP48GX SysRPL 13792221
        C64 in C (CC65) 14125646
        HP48GX in C xgcc 18097923
        HP50g UserRPL 19430360
        C128 Basic 33061353
        HP48GX UserRPL 47079103
        C64 Basic 49141280
        ZXSpectrum Basic 66107414

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
grep '\s*[a-zA-Z0-9_.#/ +-]*:\s*it takes' benchmark* | sed -e 's/.* \s*\([a-zA-Z0-9_.#/ +-]*\):[^0-9]*\([\.0-9]\+s\).*/\1: \2/' | sort -n -k2 -t:

Sort by creation time (first git log):
ls benchmark* web_benchmark* | while read f; do echo $(date -d @$(git log --format="%at" --reverse "$f" | head -n1) +"%Y-%m-%d %H:%M:%SZ") "-->" $f; done | sort -n

Get list of languages (actually, unique file extensions):
ls benchmark* web_benchmark* | sed -e 's/^.*\.\([^.]*\)$/\1/' | sort -u

About this benchmark
==================

Iterations: 3823899402 (3.8BN iterations)
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
=============================

        n mod checks
        -------------------
        304 8658
        3045 620138
        30450 47141833
        304500 3823899402

Use this factor to estimate the number of seconds it would take to run with n=304500 knowing
how long it took to run with n=30450:

        t304500 ~= t30450 * 3823899402 / 47141833

or just:

        t304500 ~= t30450 * 81.11478

And to estimate from t3045:

        t304500 ~= t3045 * 3823899402 / 620138
        t304500 ~= t3045 * 6166.2072


SOME STATS
===========

Number of benchmark files I created: 78
Number of LANGUAGES, or actually, unique extensions: 44

Unique extensions:

        asm asp awk bas bash bat bc c calc cpp cs d fs gel go hs html java jl js lisp lua m ml pas php pl prg ps1 py R rb rkt rpl rs s scm sh sml swift tcl vb vbs vim

Date in which each file was first committed to my local repo, which is different than the 2026 initial commit to the GITHUB server, which forgot the original dates:

        $ ls benchmark* web_benchmark* | while read f; do echo $(date -d @$(git log --form
        at="%at" --reverse "$f" | head -n1) +"%Y-%m-%d %H:%M:%SZ") "-->" $f; done | sort -n
        
        2014-06-18 11:23:40Z --> benchmark.c
        2016-06-27 14:39:02Z --> benchmark.d
        2016-06-27 14:39:02Z --> benchmark.php
        2016-06-27 14:39:02Z --> benchmark.py
        2016-07-03 20:08:31Z --> benchmark.pl
        2016-07-03 20:08:31Z --> benchmark.rb
        2016-07-04 19:14:43Z --> benchmark.sh
        2016-07-04 21:25:00Z --> benchmark.bash
        2016-07-04 22:28:43Z --> benchmark.js
        2016-07-05 18:19:11Z --> benchmark.java
        2016-07-05 22:59:44Z --> benchmark.awk
        2016-07-06 16:50:12Z --> benchmark.tcl
        2016-07-06 16:50:12Z --> benchmark.vim
        2016-07-06 17:59:39Z --> benchmark.lua
        2016-07-09 21:06:37Z --> benchmark.go
        2016-07-10 02:03:56Z --> benchmark.rs
        2016-07-10 17:07:08Z --> benchmark.swift
        2016-07-10 21:52:43Z --> benchmark.pas
        2016-07-12 14:43:19Z --> benchmark.R
        2016-07-13 01:59:58Z --> benchmark.hs
        2016-07-18 05:04:42Z --> benchmark.gambit.scm
        2016-07-18 05:04:42Z --> benchmark.guile.scm
        2016-07-25 02:19:36Z --> benchmark.rkt
        2016-07-29 02:29:27Z --> benchmark.sbcl.lisp
        2016-08-01 02:19:12Z --> benchmark.ecl.lisp
        2016-08-01 02:19:12Z --> benchmark.typed.rkt
        2016-08-16 01:47:08Z --> benchmark.clisp.lisp
        2016-08-16 01:47:08Z --> benchmark.gcl.lisp
        2016-09-01 15:10:13Z --> benchmark.wsh.js
        2016-09-01 15:10:13Z --> web_benchmark.js.asp
        2016-09-01 15:14:05Z --> benchmark.wsh.vbs
        2016-09-01 15:14:05Z --> web_benchmark.vb.asp
        2016-09-02 02:49:20Z --> web_benchmark.js.html
        2016-09-03 22:55:35Z --> benchmark.bat
        2016-09-07 10:34:37Z --> benchmark.ps1
        2016-09-08 02:27:23Z --> web_benchmark.php
        2016-09-18 19:43:09Z --> benchmark.cs
        2016-09-18 19:43:09Z --> benchmark.vb
        2018-03-14 20:26:26Z --> benchmark.bas
        2018-03-14 23:42:01Z --> benchmark.fb.bas
        2018-03-15 21:59:56Z --> benchmark.dbase3.prg
        2018-03-18 00:13:42Z --> benchmark.c64.bas
        2018-03-18 15:18:37Z --> benchmark.c64.c
        2018-03-20 11:19:23Z --> benchmark.zx.c
        2018-03-20 15:04:19Z --> benchmark.bennu.prg
        2018-03-21 17:25:30Z --> benchmark.c128.bas
        2018-03-21 17:25:30Z --> benchmark.c128.c
        2018-03-23 22:42:38Z --> benchmark.libreoffice.vb
        2018-03-24 19:23:13Z --> benchmark.zx.bas
        2018-03-28 15:29:17Z --> benchmark.hp48.rpl
        2018-03-30 05:43:44Z --> benchmark.hp48.c
        2018-03-30 10:29:58Z --> benchmark.excel.vb
        2018-04-02 01:27:05Z --> benchmark.hp48.m
        2018-04-02 01:27:05Z --> benchmark.hp48.s
        2018-04-10 12:57:32Z --> benchmark.hp50.m
        2018-04-10 12:57:32Z --> benchmark.hp50.rpl
        2018-04-10 12:57:32Z --> benchmark.hp50.s
        2018-04-13 16:01:31Z --> benchmark.hp50.c
        2018-04-24 00:14:20Z --> benchmark.emacs.lisp
        2018-04-24 19:29:14Z --> benchmark.chicken.scm
        2018-04-26 00:36:06Z --> benchmark.gforth.fs
        2018-04-26 12:45:39Z --> benchmark.octave.m
        2018-04-28 07:59:55Z --> benchmark.genius.gel
        2018-04-28 14:48:31Z --> benchmark.bc
        2018-04-28 14:49:12Z --> benchmark.calc
        2018-04-30 22:08:57Z --> benchmark.mitscheme.scm
        2018-05-01 20:05:21Z --> benchmark.jl
        2018-05-03 08:44:31Z --> benchmark.ocaml.ml
        2018-05-08 17:54:15Z --> benchmark.smlnj.sml
        2018-05-11 13:15:25Z --> benchmark.mlton.sml
        2018-05-13 13:01:05Z --> benchmark.polyml.sml
        2018-12-30 18:35:24Z --> benchmark.nasm.asm
        2019-01-01 20:07:17Z --> benchmark.nasmlibc.asm
        2019-01-03 21:22:08Z --> benchmark.nasm32.asm
        2019-01-04 18:22:06Z --> benchmark.nasm32libc.asm
        2019-01-05 19:45:38Z --> benchmark.gaslibc.s
        2019-01-06 00:00:27Z --> benchmark.gas.s
        2019-01-17 11:12:21Z --> benchmark.cpp


SHELL PARALLEL RUN AND HYPERTHREADING DISCUSSION
===================================================
Run:

        for a in `seq 1 8`; do echo $a; (date +%T.%N; ./benchmark 304500; date +%T.%N) &  done

To have it run 8 times, displaying the date with nanoseconds before and after
each one completes.
So, to take the total time of the N processes, subtract the first date from the
last date printed.

The thing about this benchmark, is that it's PURE CPU.
It doesn't hit the RAM, it has very small cache utilization and won't invalidate it.
It doesn't use I/O or graphics or none of that.

This means that it doesn't provide much opportunities for HyperThreading to kick in,
and if two processes get scheduled to the same core, they will run at half speed.
Because it's pure CPU and there are no bottlenecks.
And hyperthreading only works by giving the shared execution unit to the other
thread in the same core, but only when the other thread was waiting on RAM,
invalidated cache, branch mis-prediction, or I/O.
Since there are no pauses or distractions for each of the benchmark processes,
they will compete rather than share the core's execution unit when two of the
processes get scheduled to the same core's hyperthreads.

The beauty of this is that one can clearly see how core scheduling works.

Illustration:
----------------

1)
In this i7 4770K, running a single instance of:
time ./benchmark 304500
takes 9 seconds.

2)
Running 4 simultaneous processes, sometimes takes 16 seconds in total, and sometimes
it takes 9 seconds. Why?
The answer can be seen graphicaly.
It depends on how the kernel assigns logical cores to each process:

3)
If all 4 processes end up in different physical cores, then it takes 9 seconds:

        1  [                         0%]      5  [|||||||||||||||||||||||100%]
        2  [|||||||||||||||||||||||100%]      6  [                         0%]
        3  [                         0%]      7  [|||||||||||||||||||||||100%]
        4  [                         0%]      8  [|||||||||||||||||||||||100%]

(cores on a horizontal line actually are logical cores that belong to the same
physical core, in the 'htop' graphic, for this i7 4770K. This can be verified in
/proc/cpuinfo with the 'core id'. Logical cores 1 and 5 are the two
threads of the first core)

4)
If only two processes share one core, and the other two are in different cores,
it takes 16 seconds for the first two, and only 9 seconds for the other
ones:

        1  [                         0%]      5  [                       100%]
        2  [|||||||||||||||||||||||100%]      6  [|||||||||||||||||||||||100%]
        3  [                         0%]      7  [|||||||||||||||||||||||100%]
        4  [                         0%]      8  [|||||||||||||||||||||||100%]

5)
If they are all sharing cores (two and two), they all take 16 seconds to complete (worst case):

        1  [                         0%]      5  [                       100%]
        2  [|||||||||||||||||||||||100%]      6  [|||||||||||||||||||||||100%]
        3  [|||||||||||||||||||||||100%]      7  [|||||||||||||||||||||||100%]
        4  [                         0%]      8  [                         0%]

All this illustrates how HyperThreading works (or rather doesn't).
Logical cores share a single execution unit.
If these processes were not PURE CPU, and instead accessed I/O or RAM, then the
interruption of one process while waiting for I/O would be used by hyperthreading
as a time to start running the other thread that was scheduled to that core.
But these are pure CPU bound processes, that never let go of the execution
units, and when scheduled to the same core, they compete for it, instead of
sharing it.

Final notes on hyperthreading:
-------------------------------------------
For some workloads, it might be good to disable hyper threading in the BIOS.
But those workloads would have to be at most 4 threads or processes (or N for N
real cores), and purely CPU bound.
For more running threads, it would be best to leave HyperThreading enabled
since it can balance better and squeeze the Execution Unit's time the most,
especially since this benchmark is a very artificial workload and most
real workloads will not be completely PURE CPU.

--JMC
Benchmark de 2014 a 2019,
Artículo de 2026-10-13.
Copyright (c) 2014, 2016, 2018, 2019, Juan Manuel Cabo. All Rights Reserved.
