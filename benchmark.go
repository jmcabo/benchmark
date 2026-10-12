//bin/true  ;  go build -o benchmark "$0"  &&  exec -a "$0" ./benchmark "$@"  ;  exec /bin/false

//Run:
//    ./benchmark.go 304500
//Compile and run:
//    go build -o benchmark benchmark.go  &&  ./benchmark 304500
//Alternative shebang line:
//    /bin/true; exec /usr/bin/env go run "$0" "$@"
//but it has problems with exit code. It prints "exit status 42" when
//nonzero and doesn't forward it properly. At least it doesn't leave
//binaries around.


package main

import "fmt"
import "strconv"
import "time"
import "os"
import "path"


//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
func findPrimes(n int32) (int32) {
    //NOTE: With int and int64, it takes more than double the time, since IDIV asm instruction is slower on 64 bits (modulo % operation).
    var i, j int32
    var count int32 = 0

    //For each number up to 'n':
    for i=2; i <= n; i++ {
        for j=2; j < i; j++ {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if i % j == 0 {
                break
            }
        }
        if i == j {
            //The previous loop ended without divisors found. It is a prime number.
            count++
        }
    }

    return count
}


func main() {
    if len(os.Args) != 2 {
        fmt.Println("Quick and dirty single thread CPU benchmark - by JMC");
        fmt.Println("Usage: ");
        fmt.Println("        Pass an argument up to which prime numbers will be searched with");
        fmt.Println("        an inefficient algorithm, useful to compare the single thread performance");
        fmt.Println("        of the CPU");
        fmt.Println("Example: ");
        fmt.Println("        " + path.Base(os.Args[0]) + " 304500")
        fmt.Println("Notes: ");
        fmt.Println("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        fmt.Println("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        fmt.Println("        GO: it takes 9.502s using golang 1.6.2 and 9.509s using golang 1.2.1.");
        fmt.Println("");
        os.Exit(1)
    }

    v, err := strconv.ParseInt(os.Args[1], 10, 32)
    var n int32 = int32(v)
    if err != nil || n < 2 {
        fmt.Fprintf(os.Stderr, "ERROR: Argument '%s' not valid.\n", os.Args[1]);
        os.Exit(1)
    }

    startTime := time.Now()

    count := findPrimes(n)

    endTime := time.Now()
    elapsed := endTime.Sub(startTime).Seconds()
    fmt.Printf("Elapsed: %6.3fs\n", elapsed)

    fmt.Printf("%d prime numbers were found between 2 and %d\n", count, n);
}

