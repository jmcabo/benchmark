//Run as:
//    c:\Windows\Microsoft.NET\Framework\v4.0.30319\csc.exe /o /nologo benchmark.cs  &&  benchmark.exe 304500

using System;


class benchmark
{
    //NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
    //that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
    //but puts the function in a loop and counts 10000 calls).
    //Returns how many prime numbers exist between 2 and n:
    static int findPrimes(int n) {
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


    static int Main(string[] args) {
        if (args.Length != 1) {
            string programName = Environment.GetCommandLineArgs()[0];
            Console.WriteLine("Quick and dirty single thread CPU benchmark - by JMC");
            Console.WriteLine("Usage: ");
            Console.WriteLine("        Pass an argument up to which prime numbers will be searched with");
            Console.WriteLine("        an inefficient algorithm, useful to compare the single thread performance");
            Console.WriteLine("        of the CPU");
            Console.WriteLine("Example: ");
            Console.WriteLine("        " + programName + " 304500");
            Console.WriteLine("Notes: ");
            Console.WriteLine("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
            Console.WriteLine("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
            Console.WriteLine("        C#: it takes 9.017s using .NET 4.0.30319 with /o flag in a 32bit Win7 SP1 VM.");
            Console.WriteLine("");
            return 1;
        }

        int n = -1;
        if (!Int32.TryParse(args[0], out n) || n < 2) {
            Console.Error.WriteLine("ERROR: Argument '" + args[0] + "' not valid.");
            return 1;
        }

        DateTime startTime = DateTime.Now;

        int count = findPrimes(n);

        DateTime endTime = DateTime.Now;
        TimeSpan elapsed = endTime - startTime;
        Console.WriteLine("Elapsed: {0,6:f3}s", elapsed.TotalSeconds);

        Console.WriteLine("{0} prime numbers were found between 2 and {1}", count, n);
        return 0;
    }
}

