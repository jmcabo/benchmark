#!/usr/bin/tclsh
#(For Tcl 8.6)


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
proc findPrimes {n} {
    set count 0

    #For each number up to 'n':
    for {set i 2} {$i <= $n} {incr i} {
        for {set j 2} {$j < $i} {incr j} {  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if {$i % $j == 0} {
                break;
            }
        }
        if {$i == $j} {
            #The previous loop ended without divisors found. It is a prime number.
            incr count
        }
    }

    return $count;
}


proc main {} {
    if {$::argc != 1} {
        puts "Quick and dirty single thread CPU benchmark - by JMC"
        puts "Usage: "
        puts "        Pass an argument up to which prime numbers will be searched with"
        puts "        an inefficient algorithm, useful to compare the single thread performance"
        puts "        of the CPU"
        puts "Example: "
        puts "        $::argv0 304500"
        puts "Notes: "
        puts "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        puts "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        puts "        Tcl: it takes 235.2s using Tcl 8.6.1."
        puts ""
        exit 1;
    }

    set n [lindex $::argv 0]
    if {![string is integer $n] || $n < 2} {
        puts stderr [format "ERROR: Argument '%s' not valid." [lindex $::argv 0]]
        exit 1
    }

    set startTime [clock milliseconds]

    set count [findPrimes $n]

    set endTime [clock milliseconds]
    set elapsed [expr ($endTime - $startTime) / 1000.0]
    puts [format "Elapsed: %6.3fs" $elapsed]

    puts "$count prime numbers were found between 2 and $n"
}


main

