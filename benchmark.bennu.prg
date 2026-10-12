///bin/true && /usr/local/bgd/bin/bgdc benchmark.bennu.prg  ;  exec /usr/local/bgd/bin/bgdi benchmark.bennu.dcb "$@"

//Benchmark for the Bennu GD game development language - Made and Contributed By SplinterGU

//Compile and run:
//     bgdc benchmark.bennu.prg  ;  bgdi benchmark.bennu.dcb 304500
//
//(might need to "export LD_LIBRARY_PATH=/usr/local/bgd/lib")
//
//See http://www.bennugd.org/
//
//Note: No STDERR support yet.


#if __BGD__ == 2
import "mod_misc";
#else
import "mod_say";
import "mod_time";
import "mod_string";
#endif

//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes inter and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
function int findPrimes(int n)
private
    int i, j;
    int count = 0;
begin

    //For each number up to 'n':
    for (i=2; i <= n; i++)
        for (j=2; j < i; j++) //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if (i % j == 0)
                break;
            end
        end
        if (i == j)
            //The previous loop ended without divisors found. It is a prime number.
            count++;
        end
    end

    return count;
end


process main()
private
    int n = 0;
    int count;
    int startTime, endTime;
    float elapsed;
begin

    if (argc != 2)
        say("Quick and dirty single thread CPU benchmark - by JMC - Contributed by SplinterGU");
        say("Usage: ");
        say("        Pass an argument up to which prime numbers will be searched with");
        say("        an inefficient algorithm, useful to compare the single thread performance");
        say("        of the CPU");
        say("Example: ");
        say("        bgdi " + argv[0] + " 304500");
        say("Notes: ");
        say("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        say("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        say("        BennuGD: it takes 163.180s using bgd 1.0.0-r348.");
        say("");
        return 1;
    end

    n = atoi(argv[1]);

    if (n < 2)
        say("ERROR: Argument '" + argv[1] + "' not valid.");
        return 1;
    end

    startTime = get_timer();

    count = findPrimes(n);

    endTime = get_timer();
    elapsed = (endTime - startTime) / 1000.0;
    say("Elapsed: " + lpad( format(elapsed, 3),6) + "s");

    say("" + count + " prime numbers were found between 2 and " +  n);

    return 0;
end

