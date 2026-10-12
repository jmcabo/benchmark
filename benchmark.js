#!/usr/bin/nodejs

//Benchmark in JavaScript for NodeJS by JMC
//
//
//Run:
//    ./benchmark.js 304500
//
//
//Notes:
//    -JavaScript was created by Brendan Eich in 1995 for the Netscape Navigator browser. It was first
//     released as part of Netscape Navigator version 2.0. It started as a scripting language for
//     web pages in the browser, but nowadays it is included in other kinds of applications and thanks
//     to NodeJS can now run standalone and in the backend of servers.
//       With frameworks like the Electron framework (developed by GitHub), one can write standalone
//     desktop GUI applications in JavaScript. Electron uses both the Chromium browser and NodeJS.
//       JavaScript was standardized in 1997 in the ECMA-262 standard, at that point the version was 1.3.
//     The standard is still evolving and new editions come out every few years. ECMAScript 3rd Edition
//     came out in 1999 and it was an important milestone. It added regular expressions among other things
//     and it was the reference edition for 10 years, until the ECMAScript 5th edition came out in 2009.
//
//    -NodeJS was released in 2009. It uses the V8 engine developed by Google for the Google Chrome
//     browser. Applications written for NodeJS can run in the server (as opposed to in the client),
//     and in the command line.
//
//    -All numbers are represented as double precision floats, even integers.
//     The max and min doubles are:
//            1.7976931348623157e+308
//            -1.7976931348623157e+308
//     The max and min doubles that can work as "safe integers" ('n != n+1' and 'n != n-1') are:
//            9007199254740991    #2^53 - 1
//            -9007199254740991   #-2^53 + 1
//     The number '2^53 + 1 = 9007199254740993' cannot be represented exactly as double.
//
//    -Even though all numbers are supposed to be represented as doubles in JavaScript, I suspect that
//     most modern engines use integers, as in integer CPU registers, when it is safe and within the bounds.
//     In this 2012 talk, they explain that numbers up to signed 31 bits (not 32bits because of a tag bit)
//     are represented and handled efficiently in the V8 JavaScript engine:
//            "Google I/O 2012 - Breaking the JavaScript Speed Limit with V8"
//            https://www.youtube.com/watch?v=UJPdhx5zTaw&t=15m30s
//     That, in addition to JIT optimization, is how this NodeJS benchmark runs at close to C speeds.
//     It would be impossible to achieve such speed if NodeJS used float operations in the findPrimes()
//     function.
//
//
//Limitations:
//    -An extra test (reconverted integer != original string) is necessary after parsing the integer
//     argument to exclude strings like "123.", "123.0" or "12.3e1" (subtracting 0 already returns NaN
//     for strings like "123abc"). Because of this extra test, an integer with a plus sign
//     is not considered valid: "+123".
//       I also check against the maximum number that is the biggest float that doesn't loose
//     precision in the last digit and that still satisfies 'n != n+1'.
//       If the check for the max safe integer wasn't there, a check should be added to exclude
//     exponential notation from input because reconverting to string numbers >= 1e21 in JavaScript
//     invariably uses exponential notation for those numbers.
//     The following can be used in the linux/mac shell to test the cases:
//            for a in 123a 123. 123.0 123.5 123.9 12.3e1 1e+10 1e+21 9007199254740993 9007199254740994 Infinity -Infinity NaN -NaN; do ./benchmark.js $a; done
//


const path = require('path'); //For path.basename()


//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
function findPrimes(n) {
    var i, j;
    var count = 0;

    //For each number up to 'n':
    for (i=2; i <= n; ++i) {
        for (j=2; j < i; ++j) {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if (i % j == 0) {
                break;
            }
        }
        if (i == j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


function padLeft(s, toLength) {
    while (s.length < toLength) {
        s = String.fromCharCode(0x20) + s;
    }
    return s;
}


function main() {
    if (process.argv.length != 3) {
        console.log("Quick and dirty single thread CPU benchmark - by JMC");
        console.log("Usage: ");
        console.log("        Pass an argument up to which prime numbers will be searched with");
        console.log("        an inefficient algorithm, useful to compare the single thread performance");
        console.log("        of the CPU");
        console.log("Example: ");
        console.log("        %s 304500", path.basename(process.argv[1]));
        console.log("Notes: ");
        console.log("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        console.log("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        console.log("        NodeJS: it takes 8.361s using node.js 0.10.25 !! A hair FASTER than C for some reason! (JIT optimization?).");
        console.log("");
        process.exit(1);
    }

    var n = Math.floor(process.argv[2] - 0);
    //var MAX_SAFE_INTEGER = 9007199254740991;  //2^53 - 1. Max double that can act as a safe integer (n != n+1).
    if (isNaN(n) || Math.abs(n) > Number.MAX_SAFE_INTEGER || process.argv[2].trim() != n + "" || n < 2) {
        console.error("ERROR: Argument '%s' not valid.", process.argv[2]);
        process.exit(1);
    }

    var startTime = process.hrtime();

    var count = findPrimes(n);

    var diffTime = process.hrtime(startTime);
    var elapsed = diffTime[0] + diffTime[1] / 1e9;
    console.log("Elapsed: " + padLeft(elapsed.toFixed(3), 6) + "s");  //Padding up to 6 places, and rouding to 3 decimals.
    console.log("%d prime numbers were found between 2 and %d", count, n);
}

main();

