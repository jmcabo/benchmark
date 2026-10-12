#!/bin/bash
#Version optimized for BASH. Not compatible with Dash (not posix).

#Requires external commands (for computing and printing elapsed time):
#    date, printf, awk or bc.

#Don't require Unicode Processing (faster) for the duration of this script:
export LC_ALL=C


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
function findPrimes {  #(n)
    local n=$1
    local i=2
    local j=2
    local count=0

    #For each number up to 'n':
    for((i=2;i<=n;++i)) do
        for((j=2;j<i;++j)) do  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if [[ $[i % j] = 0 ]]; then
                break
            fi
        done

        if [[ $i = $j ]]; then
            #The previous loop ended without divisors found. It is a prime number.
            ((++count))
        fi
    done

    #Return count:
    echo $count
}


#Alternative without using BASH special arithmetic c-like FOR loop.
#It's about 10% slower. It would be even slower if using single bracket "[" conditions in bash instead of double brackets "[[".
function findPrimesAlternative {  #(n)
    local n=$1
    local count=0

    local i=2
    #For each number up to 'n':
    while [[ $i -le $n ]]; do

        local j=2
        #while [[ $j -lt $i ]]; do
        until [[ $j = $i ]]; do  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if [[ $[i % j] = 0 ]]; then
                break
            fi
            ((++j))
        done

        if [[ $i = $j ]]; then
            #The previous loop ended without divisors found. It is a prime number.
            ((++count))
        fi

        ((++i))
    done

    #Return count:
    echo $count
}


function main {
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
        echo "        Bash: it takes an estimated 13936s (3h 52m) using Bash 4.3.11."
        echo "              For './benchmark 30450' it takes 171.8s, which is 1576 times slower than the C version at 0.109s."
        echo "        Dash: not compatible with dash."
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
    #count=$(findPrimesAlternative $n)

    endTime=`date "+%s.%N"`
    elapsed=`echo $endTime $startTime | awk '{printf("%f", $1 - $2)}'`    #Using awk to subtract with decimals
    #elapsed=`echo $endTime - $startTime | bc -l`                         #Using bc (not always available):
    printf "Elapsed: %6.3fs\n" $elapsed

    echo "$count prime numbers were found between 2 and $n"
}

main "$@"


