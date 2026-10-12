///bin/true; exec /usr/bin/env swift -Ounchecked "$0" "$@"

import Foundation


func findPrimes(_ n: Int32) -> Int32 {
    //NOTE: With i64, it takes more than double the time, since IDIV asm instruction is slower on 64 bits (modulo % operation).
    var i : Int32
    var j : Int32
    var count : Int32 = 0

    //For each number up to 'n':
    //Also: for i in 2...n {
    i = 2
    while i <= n {
        j = 2
        while j < i {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if i % j == 0 {
                break
            }
            j += 1
        }
        if i == j {
            //The previous loop ended without divisors found. It is a prime number.
            count += 1
        }
        i += 1
    }

    return count
}


func main() {
    if (Process.arguments.count != 2) {
        print("Quick and dirty single thread CPU benchmark - by JMC")
        print("Usage: ")
        print("        Pass an argument up to which prime numbers will be searched with")
        print("        an inefficient algorithm, useful to compare the single thread performance")
        print("        of the CPU")
        print("Example: ")
        print("       ", Process.arguments[0], "304500")
        print("Notes: ")
        print("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
        print("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
        print("        Swift: it takes 8.857s using swift-3.0-PREVIEW-2 with flag -Ounchecked.")
        print("")
        exit(1)
    }

    let n : Int32
    let parseResult = Int32(Process.arguments[1])
    if parseResult != nil {
        n = parseResult!
    } else {
        n = -1
    }
    if n < 2 {
        //Note: Doesn't work in linux:
        //  let stderr = NSFileHandle.fileHandleWithStandardError()
        //  let s = "ERROR: Argument '\(Process.arguments[1])' not valid."
        //  stderr.writeData(s.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false))

        //Using fputs() directly:
        fputs("ERROR: Argument '\(Process.arguments[1])' not valid.\n", stderr)
        exit(1)
    }

    let startTime = NSDate()

    let count = findPrimes(n)

    let endTime = NSDate()
    let elapsed = endTime.timeIntervalSince(startTime)   //Note: timeIntervalSinceDate() doesn't work on Swift3 preview 2 for Linux.
    print(String(format: "Elapsed: %6.3fs", elapsed))

    print("\(count) prime numbers were found between 2 and \(n)")
}


main()

