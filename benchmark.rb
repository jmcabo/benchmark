#!/usr/bin/ruby -w


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
def findPrimes(n)
    count = 0

    #For each number up to 'n':
    i = 2
    while i <= n
        j = 2
        while j < i    #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if (i % j) == 0
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


def main()
    if ARGV.length != 1
        puts "Quick and dirty single thread CPU benchmark - by JMC"
        puts "Usage: "
        puts "        Pass an argument up to which prime numbers will be searched with"
        puts "        an inefficient algorithm, useful to compare the single thread performance"
        puts "        of the CPU"
        puts "Example: "
        printf "        %s 304500\n", $0
        puts "Notes: "
        puts "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        puts "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        puts "        Ruby: it takes 127.2s using Ruby 2.0.0 and 147.8s using Ruby 1.9.3."
        puts ""
        exit 1;
    end

    begin
        n = Integer(ARGV[0], 10)
    rescue ArgumentError
        n = -1
    end
    if n < 2
        $stderr.printf("ERROR: Argument '%s' not valid.\n", ARGV[0]);
        exit 1;
    end

    GC.start
    startTime = Time.now

    count = findPrimes(n)

    endTime = Time.now
    printf "Elapsed: %6.3fs\n", (endTime - startTime)

    printf "%d prime numbers were found between 2 and %d\n", count, n
end


main()


