#!/usr/bin/php
<?php

//Benchmark in PHP by JMC
//
//
//Run:
//    ./benchmark.php 304500
//
//
//Notes:
//    -PHP is an interpreted language (now JIT optimized) released in 1995. It is one of the most
//     used web backend languages. It can be used outside of the webserver in the console.
//
//    -Integers in PHP are always 32 bits for the 32-bit version of PHP, and 64 bits in the 64-bit
//     version of PHP. In Windows, integers were 32-bits even in 64-bit PHP for versions older than 7.0,
//     but not anymore.
//     Numeric variables are either integers or floats (there is no byte/char/short/long, etc.)
//     Floats are always 64-bit (IEEE 754 double precision). The maximum non infinity float number
//     is approximately 1.79769e+308 but there is no PHP_FLOAT_MAX constant for that.
//            <?php
//            echo "Integer bytes: " . PHP_INT_SIZE . "\n";
//            echo "Max Integer: " . PHP_INT_MAX . "\n";
//     Output using 64-bit PHP in Linux:
//            Integer bytes: 8
//            Max Integer: 9223372036854775807
//     Output using 32-bit PHP in Linux:
//            Integer bytes: 4
//            Max Integer: 2147483647
//
//    -Integers are converted to floats when precision isn't enough. Division with the '/' operator
//     is always floating point division (which can be truncated to (int)), but the remainder
//     operator '%' works with ints (and works the same as the C '%' operator when given negative
//     arguments).
//            <?php
//            echo "5 is: " . gettype(5) . "\n";
//            echo "5.0 is: " . gettype(5.0) . "\n";
//            echo "5 / 2 is: " . gettype(5 / 2) . "\n";
//            echo "5 % 2 is: " . gettype(5 % 2) . "\n";
//     Output:
//            5 is: integer
//            5.0 is: double
//            5 / 2 is: double
//            5 % 2 is: integer
//
//    -Parsing an int by casting a string to int would allow junk characters after the digits:
//            (int) "30a"    -->    30
//     The best way to parse an int since PHP 5.2 is to use filter_var() and check the return value:
//            filter_var("30a", FILTER_VALIDATE_INT)    -->    false
//     The return value must be checked with the operator !== or === since false == 0 in PHP.
//


if (php_sapi_name() != "cli") {
    //This only runs under console/cli:
    return;
}

//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
function findPrimes($n) {
    $count = 0;

    //For each number up to 'n':
    for ($i=2; $i <= $n; ++$i) {
        for ($j=2; $j < $i; ++$j) {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if ($i % $j == 0) {
                break;
            }
        }
        if ($i==$j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++$count;
        }
    }

    return $count;
}


function main() {
    global $argc, $argv;

    if ($argc != 2) {
        printf("Quick and dirty single thread CPU benchmark - by JMC\n");
        printf("Usage: \n");
        printf("        Pass an argument up to which prime numbers will be searched with\n");
        printf("        an inefficient algorithm, useful to compare the single thread performance\n");
        printf("        of the CPU\n");
        printf("Example: \n");
        printf("        ${argv[0]} 304500\n");
        printf("Notes: \n");
        printf("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n");
        printf("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n");
        printf("        PHP: it takes 66.119s using PHP 7.1.11 in a 64bit Ubuntu 17.10 VM.\n");
        printf("        PHP: it takes 71.4s using PHP 7.0.8 in a 64bit Arch VM.\n");
        printf("        PHP: it takes 117.393s using PHP 5.5.9 in a 32bit Ubuntu 14.04 VM.\n");
        printf("        PHP: it takes 128.494s using PHP 5.5.9.\n");
        printf("        PHP: it takes 159.4s using PHP 5.6.4 in a 64bit VM.\n");
        printf("        PHP: it takes 238.159s using PHP 5.2.6 in a 32bit Ubuntu 9.04 VM.\n");
        printf("        PHP: it takes 426.929s using PHP 5.5.9 with Xdebug v2.2.3 in a 32bit VM.\n");
        printf("\n");
        exit(1);
    }

    $n = filter_var($argv[1], FILTER_VALIDATE_INT);
    if ($n === false || $n < 2) {
        fwrite(STDERR, "ERROR: Argument '${argv[1]}' not valid.\n");
        exit(1);
    }

    $startTime = microtime(true);

    $count = findPrimes($n);

    $endTime = microtime(true);
    $elapsed = $endTime - $startTime;
    echo "Elapsed: " . sprintf("%6.3f", $elapsed) . "s\n";

    echo("$count prime numbers were found between 2 and $n\n");
}

main();

