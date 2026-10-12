//bin/true  ;  javac "$0"  &&  exec -a "$0" java benchmark "$@"  ;  exec /bin/false

//Benchmark in Java by JMC
//
//
//Run:
//    ./benchmark.java 304500
//Compile and run:
//      javac benchmark.java  &&  java benchmark 304500
//


//These imports are not necessary for this little program:
//import java.util.*;
//import java.io.*;
//import java.lang.*;


class benchmark {

    //NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
    //that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
    //but puts the function in a loop and counts 10000 calls).
    //Returns how many prime numbers exist between 2 and n:
    public static int findPrimes(int n) {
        int i, j;
        int count = 0;

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


    public static void main (String[] args) {
        int n = 0;
        int count;
        long startTime, endTime;
        double elapsed;

        if (args.length != 1) {
            System.out.println("Quick and dirty single thread CPU benchmark - by JMC");
            System.out.println("Usage: ");
            System.out.println("        Pass an argument up to which prime numbers will be searched with");
            System.out.println("        an inefficient algorithm, useful to compare the single thread performance");
            System.out.println("        of the CPU");
            System.out.println("Example: ");
            Class c = new Object(){}.getClass().getEnclosingClass();
            String programName = "java " + c.getName();
            System.out.printf("        %s 304500\n", programName);
            System.out.println("Notes: ");
            System.out.println("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
            System.out.println("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
            System.out.println("        JAVA: it takes 10.841s using OpenJDK 7u101-2.6.6, and 10.854s using OracleJDK 9-ea+123.");
            System.out.println("              The flag -XX:+AggressiveOpts makes no difference in both cases.");
            System.out.println("");
            System.exit(1);
        }

        try {
            n = Integer.parseInt(args[0]);
        } catch (NumberFormatException e) {
            n = -1;
        }
        if (n < 2) {
            System.err.printf("ERROR: Argument '%s' not valid.\n", args[0]);
            System.exit(1);
        }

        startTime = System.nanoTime();

        count = findPrimes(n);

        endTime = System.nanoTime();
        elapsed = (endTime - startTime) / 1e9;
        System.out.printf("Elapsed: %6.3fs\n", elapsed);

        System.out.printf("%d prime numbers were found between 2 and %d\n", count, n);
    }
}

