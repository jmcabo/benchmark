<?php

//Run as:
//   <site>/web_benchmark.php?n=304500
//
//Or force it to run from command line like (although there exists "benchmark.php" for that):
//   echo "" | php -F web_benchmark.php -B '$_REQUEST = array("n" => "304500");'


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

    header("Content-Type: text/plain; charset=UTF-8");

    if (count($_REQUEST) != 1 || !isset($_REQUEST["n"])) {
        printf("Quick and dirty single thread CPU benchmark - by JMC\n");
        printf("Usage: \n");
        printf("        Pass an argument up to which prime numbers will be searched with\n");
        printf("        an inefficient algorithm, useful to compare the single thread performance\n");
        printf("        of the CPU\n");
        printf("Example: \n");
        printf("        ${_SERVER["SCRIPT_NAME"]}?n=304500\n");
        printf("Notes: \n");
        printf("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n");
        printf("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n");
        printf("        PHP/Apache: it takes 60.672s using PHP 7.1.11 in a 64bit Ubuntu 17.10 VM.\n");
        printf("        PHP/Apache: it takes 112.763s using PHP 5.5.9 in a 32bit Ubuntu 14.04 VM.\n");
        printf("        PHP/Apache: it takes 123.470s using PHP 5.5.9.\n");
        printf("        PHP/Apache: it takes 243.866s using PHP 5.2.6 in a 32bit Ubuntu 9.04 VM.\n");
        printf("        PHP/Apache: it takes 405.952s using PHP 5.5.9 with Xdebug v2.2.3 in a 32bit Ubuntu 14.04 VM.\n");
        printf("\n");
        exit(1);
    }

    $n = filter_var($_REQUEST["n"], FILTER_VALIDATE_INT);
    if ($n === false || $n < 2) {
        echo "ERROR: Argument '${_REQUEST["n"]}' not valid.\n";
        exit(1);
    }

    @set_time_limit(0);  //Default is only 30 seconds.
    $startTime = microtime(true);

    $count = findPrimes($n);

    $endTime = microtime(true);
    $elapsed = $endTime - $startTime;
    echo "Elapsed: " . sprintf("%6.3f", $elapsed) . "s\n";

    echo("$count prime numbers were found between 2 and $n\n");
}


main();

