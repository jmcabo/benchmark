#!/usr/bin/perl -w

#Benchmark in Perl 5 by JMC
#
#
#Run:
#    ./benchmark.pl 304500
#
#
#Notes:
#    -Perl was created in 1987 by the legendary Larry Wall. It started as a text processing and reporting
#     scripting programming language for Unix. In the late 90s it was used as web backend language in a
#     big number of websites through CGI. Nowadays it is used in many fields besides system administration
#     and webservers, like finance and bioinformatics. There is an impressive number of modules and libraries
#     in the CPAN perl repository.
#       Perl 5 is an interpreted programming language. Perl 6 is a completely separate language that can be
#     compiled to bytecode and then JITed to native code depending on the target virtual machine (like the
#     Parrot Virtual Machine or the JVM). Many Perl 5 modules and libraries are written in C so their
#     performance is good despite Perl 5 being an interpreter.
#
#    -There are two ways of parsing numbers: subtracting zero ('str - 0') or using int(). Subtracting
#     zero does accept floats, while int() truncates floats to integer. Both produce an error message
#     when the string is not numeric. One has to check with Scalar::Util::looks_like_number() prior
#     to conversion.
#
#
#Limitations:
#    -An extra test (reconverted integer != original string) is necessary after parsing the integer
#     argument to exclude strings like "123.", "123.0" or "12.3e1" (the Scalar::Util::looks_like_number()
#     function already returns false for strings like "123abc"). Because of this extra test, an integer
#     with a plus sign is not considered valid: "+123".
#     I had to use sprintf("%d", n) instead of "".$n to exclude "1e+20" too.
#

use strict;
use warnings;

use Time::HiRes;
use Scalar::Util;


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
sub findPrimes {
    my $n = $_[0];
    my $i;
    my $j;
    my $count = 0;

    #For each number up to 'n':
    for ($i=2; $i <= $n; ++$i) {
        for ($j=2; $j < $i; ++$j) {  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if ($i % $j == 0) {
                last;
            }
        }
        if ($i == $j) {
            #The previous loop ended without divisors found. It is a prime number.
            ++$count;
        }
    }

    return $count;
}


sub main() {
    my $numArgs = $#ARGV + 1;
    if ($numArgs != 1) {
        print "Quick and dirty single thread CPU benchmark - by JMC\n";
        print "Usage: \n";
        print "        Pass an argument up to which prime numbers will be searched with\n";
        print "        an inefficient algorithm, useful to compare the single thread performance\n";
        print "        of the CPU\n";
        print "Example: \n";
        printf("        %s 304500\n", $0);
        print "Notes: \n";
        print "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n";
        print "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n";
        print "        Perl: it takes 316.7s using Perl 5.18.2.\n";
        print "\n";
        exit 1;
    }

    my $n = "";
    if (Scalar::Util::looks_like_number($ARGV[0])) {
        $n = int($ARGV[0]);
    }
    if ($n eq "" || $ARGV[0] ne sprintf("%d", $n) || $n < 2) {
        printf STDERR ("ERROR: Argument '%s' not valid.\n", $ARGV[0]);
        exit 1;
    }

    my $startTime = Time::HiRes::time();

    my $count = findPrimes($n);

    my $endTime = Time::HiRes::time();
    my $elapsed = $endTime - $startTime;
    printf("Elapsed: %6.3fs\n", $elapsed);

    printf("%d prime numbers were found between 2 and %d\n", $count, $n);
}


main();

