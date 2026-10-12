#!/bin/sh
#POSIX version, compatible with DASH and BASH (not optimized for BASH).
#
#Requires external commands (for computing and printing elapsed time):
#    date, printf, awk or bc.
#
#For BusyBox it might be necessary to replace 'date' with '/bin/date' to have the milliseconds.
#
#Sometimes BusyBox is the only shell in a system, so this file is useful to compare
#performance of routers, android cellphones, kindles, etc. that can run BusyBox.

#Don't require Unicode Processing (faster) for the duration of this script:
export LC_ALL=C


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
findPrimes () {  #(n)
    n=$1
    count=0

    i=2
    #For each number up to 'n':
    while [ $i -le $n ]; do

        j=2
        #while [ $j -lt $i ]; do
        until [ $j = $i ]; do  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if [ $((i % j)) = 0 ]; then
                break
            fi
            j=$((j+1))
        done

        if [ $i = $j ]; then
            #The previous loop ended without divisors found. It is a prime number.
            count=$((count+1))
        fi

        i=$((i+1))
    done

    #Return count:
    echo $count
}

main () {
    if [ $# -ne 1 ]; then
        echo "Quick and dirty single thread CPU benchmark - by JMC"
        echo "Usage: "
        echo "        Pass an argument up to which prime numbers will be searched with"
        echo "        an inefficient algorithm, useful to compare the single thread performance"
        echo "        of the CPU"
        echo "Example: "
        echo "        $0 304500"
        echo "Notes: "
        echo "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        echo "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        echo "        Dash: it takes an estimated 8381s (2h 20m) using Dash 0.5.7."
        echo "              For n=3045 it takes 1.164s. For n=30450 it takes 103.328s."
        echo "        BusyBox: it takes an estimated 16812s (4h 40m) using BusyBox 1.22.1."
        echo "                 For n=3045 it takes 2.683s. For n=30450 it takes 207.256s."
        echo "        Bash: it takes an estimated 27077s (7h 31m) using Bash 4.3.11."
        echo "              For n=3045 it takes 4.368s. For n=30450 it takes 333.816s."
        echo ""
        exit 1
    fi

    n=$1
    [ "$n" -eq "$n" ] 2>/dev/null
    isNumeric=$?
    if [ $isNumeric -ne 0 ] || [ $n -lt 2 ]
    then
        #Argument is not numeric, or less than 2.
        >&2 echo "ERROR: Argument '$1' not valid."
        exit 1
    fi

    startTime=`date "+%s.%N"`

    count=$(findPrimes $n)

    endTime=`date "+%s.%N"`
    elapsed=`echo $endTime $startTime | awk '{printf("%f", $1 - $2)}'`    #Using awk to subtract with decimals
    #elapsed=`echo $endTime - $startTime | bc -l`                         #Using bc (not always available):
    printf "Elapsed: %6.3fs\n" $elapsed

    echo "$count prime numbers were found between 2 and $n"
}

main "$@"


