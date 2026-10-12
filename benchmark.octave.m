#! /usr/bin/octave -fq
%Benchmark in Octave by JMC
%
%Remarks:
%    -The Octave scripting language is similar to Matlab. It has some additions like printf()
%     (besides already existing fprintf()), operators like ++, --, += etc.
%     And it adds comments that start with # (besides %).
%     Octave also adds "endfor" "endif", etc. instead of just "end" to end blocks of code.
%     The function argv() is also specific to Octave.
%
%    -For modulus there are rem() and mod(). They work the same for positive arguments.
%     For negative numbers, rem() gives the same result as the percent '%' operator in C.
%
%    -By default, all numeric values are double precision floating point values.
%     I tried casting values to int32() everywhere and the result is not faster, since probably
%     operations like mod() only work with float values and cast back to float.
%
%    -Max integer that can be represented without loss of precision with an Octave
%     double is 2^53 (9007199254740992). This is with 64-bit Octave 4.2.1.
%
%Limitations:
%    -No exit code: I couldn't get exit() or quit() to work as intended. For some reason, they don't
%     forward the exit code to the shell. Also, Octave prints some messages when calling exit()
%     or quit(). And the workspace is saved on shutdown by creating a file called "octave-workspace"
%     in the current directory.
%     UPDATE: It seems it is a known bug in Octave 4.2.1 and it shouldn't happen in version 4.3.
%     I tried Octave 4.2.2 and it was the same. Version 4.3 hasn't been released yet as of April 2018.
%
%    -No JIT Compiler: when calling jit_enable(1) I get the following message with Octave 4.2.1 in Kubuntu 17.10:
%         warning: jit_enable: support for JIT was unavailable or disabled when Octave was built
%     I tried Octave 4.2.2 and it was the same.
%


%NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
%that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
%but puts the function in a loop and counts 10000 calls).
%Returns how many prime numbers exist between 2 and n:
%Execution time is 2.207s for n=3045 and 167.159s for n=30450 and an estimated 13559s (3h 46m) for n=304500.
function count = findPrimes (n)
    count = 0;
    i = 0;
    j = 0;
    %For each number up to 'n':
    for i = 2 : n
        noDivisors = 1;
        for j = 2 : i-1  %NOT using the sqrt optimization (for easier benchmarking).
            %If i divisible by j, it wasn't a prime number:
            if rem(i, j) == 0
                noDivisors = 0;
                break;
            end
        end
        if noDivisors
            %The previous loop ended without divisors found. It is a prime number.
            count = count + 1;
        end
    end
end


%Version using WHILE loops. It is slower than using FOR loops.
%Execution time is 2.971s for n=3045 and 226.311s for n=30450 and an estimated 18357s (5h 6m) for n=304500.
function count = findPrimes_While (n)
    count = 0;
    i = 0;
    j = 0;

    %For each number up to 'n':
    i = 2;
    while i <= n
        j = 2;
        while j < i  %NOT using the sqrt optimization (for easier benchmarking).
            %If i divisible by j, it wasn't a prime number:
            if mod(i, j) == 0
                break;
            end
            j = j + 1;
        end
        if i == j
            %The previous loop ended without divisors found. It is a prime number.
            count = count + 1;
        end
        i = i + 1;
    end
end


%Version using vectorized operations:
%I don't like this vectorized version because it doesn't halt at first divisor found, so the number
%of modulus operations is bigger than all the other benchmarks. But being vectorized it
%is faster than the FOR and WHILE versions in this file, at least without a JIT compiler available.
%I also don't like it because it is O(n) in memory, although it still is O(n^2) in time.
%
%I include this version only for completeness. I don't consider that it implements the same algorithm as
%all the other benchmark files, so I'm not using it for representing the file (it's O(n) in memory and
%has a different number of modulus operations than the same benchmark for all the other languages).
%
%Execution time is 0.077s for n=3045 and 5.420s for n=30450 and 536.712s for n=304500.
function count = findPrimes_Vectorized (n)
    count = 0;
    i = 0;
    %For each number up to 'n':
    for i = 2 : n
        J = 2 : i-1;  %NOT using the sqrt optimization (for easier benchmarking).
        %If i divisible by j, it wasn't a prime number:
        %Get the remainder of scalar 'i' over each element of vector 'J':
        %The all() function returns true if all elements are non-zero in the result vector:
        if all(mod(i, J))
            %The previous vectorized operation ended without divisors found. It is a prime number.
            count = count + 1;
        end
    end
end


%Version using vectorized operations, as above, but preallocating and reusing the J vector by slicing it:
%Same considerations apply for this version as for the findPrimes_Vectorized() version.
%Execution time is 0.078s for n=3045 and 5.150s for n=30450 and 497.128s for n=304500.
function count = findPrimes_VectorizedCreateOnce (n)
    count = 0;
    i = 0;
    %Pre-create the J vector:
    J = 1 : n-1;
    %For each number up to 'n':
    for i = 2 : n
        %If i divisible by j, it wasn't a prime number:
        %Get the remainder of scalar 'i' over each element of vector 'J':
        %The all() function returns true if all elements are non-zero in the result vector:
        if all(mod(i, J(2:i-1)))  %NOT using the sqrt optimization (for easier benchmarking).
            %The previous vectorized operation ended without divisors found. It is a prime number.
            count = count + 1;
        end
    end
end


function main ()
    if length(argv()) != 1
        disp("Quick and dirty single thread CPU benchmark - by JMC");
        disp("Usage: ");
        disp("        Pass an argument up to which prime numbers will be searched with");
        disp("        an inefficient algorithm, useful to compare the single thread performance");
        disp("        of the CPU");
        disp("Example: ");
        disp(["        ", program_invocation_name(), " 304500"]);
        disp("Notes: ");
        disp("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        disp("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        disp("        Octave: it takes an estimated 13559s (3h 46m) for n=304500 using Octave 4.2.1 without JIT enabled.");
        disp("                For n=3045 it takes 2.207s. For n=30450 it takes 167.159s.");
        disp("");
        %exit(1);   %Note: exit() Causes crash in Octave 4.2.1
        return;
    end

    [n, count, errmsg, pos] = sscanf(argv(){1}, "%d");
    if count != 1 || pos != length(argv(){1}) + 1 || typeinfo(n) != "scalar" || n < 2
        fprintf(stderr, "ERROR: Argument '%s' not valid.\n", argv(){1});
        %exit(1);   %Note: exit() Causes crash in Octave 4.2.1
        return;
    end

    %jit_enable(1);  %Note: Octave 4.2.1 in Ubuntu says "support for JIT unavailable" and halts.
    startTime = clock();

    count = findPrimes(n);
    %count = findPrimes_While(n);
    %count = findPrimes_Vectorized(n);
    %count = findPrimes_VectorizedCreateOnce(n);

    endTime = clock();
    elapsed = etime(endTime, startTime);
    printf("Elapsed: %6.3fs\n", elapsed);

    printf("%d prime numbers were found between 2 and %d\n", count, n);
end


main();

