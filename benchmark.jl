#!/usr/bin/julia

#Benchmark for the Julia programming language - by JMC
#
#Notes:
#   -Julia is a programming language created in 2009 and released in 2012 geared for scientific
#    modeling, but good for general purpose usage.
#
#   -The syntax is very reminiscent of Octave. But it has nothing to do when it comes
#    to performance. Julia wins by a large margin and is close to C speeds.
#
#   -There is some startup delay of about 400ms. I suppose because of on the fly compilation.
#    Sadly, that means that it isn't practical for applications where fast startup is important
#    (like a rudimentary CGI web service that must deliver many requests per second, but it
#    could work if the process is loaded only once, like FastCGI).
#    After the startup delay, it runs very fast at C like speeds.
#
#   -In Julia, the values are typed and the type of the variables is whatever their
#    values have (unless they are declared):
#       julia> a = Int32(4)
#       4
#       julia> typeof(a)
#       Int32
#       julia> a += 1
#       5
#       julia> typeof(a)
#       Int64
#       julia>
#    Variables can be declared Int32 but the values involving operations with those variables
#    must be forced to Int32 too for those operations to be fast.
#    This is important since modulus (or remainder) is faster in 32bits since the x86 assembly
#    instruction IDIV is much slower for 64-bit registers.
#
#   -Using FOR loops is faster than WHILE loops with the default int type. When forcing the
#    loop counter type to Int32, it reverts and the WHILE loops here are faster than FOR loops.
#
#   -For modulus there are %, rem() and mod(). They all work the same for positive arguments.
#    For negative numbers, rem() and '%' give the same result as the percent '%' operator in C.
#


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
#Execution time is 0.005s for n=3045 and 0.136s for n=30450 and 10.651s for n=304500.
function findPrimes(n :: Int32)
    count :: Int32 = Int32(0)
    j = Int32(0)

    #For each number up to 'n':
    i = Int32(2)
    while i <= n
        j = Int32(2)
        while j < i  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if i % j == Int32(0)
                break
            end
            j += Int32(1)
        end
        if i == j
            #The previous loop ended without divisors found. It is a prime number.
            count += Int32(1)
        end
        i += Int32(1)
    end

    return count
end


#Version without specifying Int32 as the type. In 64-bit julia, it will use 64-bit integers and
#will be slower, becose the '%' remainder is slower with 64-bit operands.
#Execution time is 0.009s for n=3045 and 0.381s for n=30450 and 30.611s for n=304500.
function findPrimes_WhileDefaultInt(n)
    count = 0
    j = 0

    #For each number up to 'n':
    i = 2
    while i <= n
        j = 2
        while j < i  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if i % j == 0
                break
            end
            j += 1
        end
        if i == j
            #The previous loop ended without divisors found. It is a prime number.
            count += 1
        end
        i += 1
    end

    return count
end


#Version using FOR loops. A tiny bit slower than WHILE loops for Int32.
#Execution time is 0.008s for n=3045 and 0.140s for n=30450 and 10.919s for n=304500.
function findPrimes_For(n :: Int32)
    count = Int32(0)

    #For each number up to 'n':
    for i = Int32(2) : n
        noDivisors = true
        for j = Int32(2) : i - Int32(1)  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if i % j == Int32(0)
                noDivisors = false
                break
            end
        end
        if noDivisors
            #The previous loop ended without divisors found. It is a prime number.
            count += Int32(1)
        end
    end

    return count
end


#Version without specifying Int32 as the type. In 64-bit julia, it will use 64-bit integers and
#will be slower, as the % remainder is slower with 64-bit operands.
#Faster than WHILE loops when the type is the default.
#Execution time is 0.010s for n=3045 and 0.368s for n=30450 and 28.831s for n=304500.
function findPrimes_ForDefaultInt(n)
    count = 0

    #For each number up to 'n':
    for i = 2 : n
        noDivisors = true
        for j = 2 : i-1  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if i % j == 0
                noDivisors = false
                break
            end
        end
        if noDivisors
            #The previous loop ended without divisors found. It is a prime number.
            count += 1
        end
    end

    return count
end


function main()
    if length(ARGS) != 1
        programName = basename(Base.source_path())
        println("Quick and dirty single thread CPU benchmark - by JMC")
        println("Usage: ")
        println("        Pass an argument up to which prime numbers will be searched with")
        println("        an inefficient algorithm, useful to compare the single thread performance")
        println("        of the CPU")
        println("Example: ")
        println("        " * programName * " 304500")
        println("Notes: ")
        println("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
        println("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
        println("        Julia: it takes 10.651s using Julia 0.4.7.")
        println("               For n=30450 it takes 0.136s.")
        println("")
        exit(1)
    end

    n = -1
    try
        n = parse(Int32, ARGS[1])
    catch err
    end
    if n < 2
        println(STDERR, "ERROR: Argument '", ARGS[1], "' not valid.")
        exit(1)
    end

    startTime = time()

    count = findPrimes(n)
    #count = findPrimes_WhileDefaultInt(n)
    #count = findPrimes_For(n)
    #count = findPrimes_ForDefaultInt(n)

    endTime = time()
    elapsed = (endTime - startTime)
    @printf("Elapsed: %6.3fs\n", elapsed)

    println("$count prime numbers were found between 2 and $n")
end


main()

