'Run as:
'    c:\Windows\Microsoft.NET\Framework\v4.0.30319\vbc.exe /optimize /nologo benchmark.vb  &&  benchmark.exe 304500

Module benchmark
    'NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
    'that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
    'but puts the function in a loop and counts 10000 calls).
    'Returns how many prime numbers exist between 2 and n:
    Private Function findPrimes(ByVal n)
        Dim i, j, count As Int32
        count = 0

        'For each number up to 'n':
        For i=2 To n
            For j=2 To i-1  'NOT using the sqrt optimization (for easier benchmarking).
                'If i divisible by j, it wasn't a prime number:
                if i Mod j = 0 then
                    Exit For
                end if
            Next
            if i = j then
                'The previous loop ended without divisors found. It is a prime number.
                count = count + 1
            end if
        Next

        findPrimes = count
    End Function


    Sub Main(ByVal args As String())

        if args.Length <> 1 then
            Dim programName as String
            programName = Environment.GetCommandLineArgs()(0)
            Console.WriteLine("Quick and dirty single thread CPU benchmark - by JMC")
            Console.WriteLine("Usage: ")
            Console.WriteLine("        Pass an argument up to which prime numbers will be searched with")
            Console.WriteLine("        an inefficient algorithm, useful to compare the single thread performance")
            Console.WriteLine("        of the CPU")
            Console.WriteLine("Example: ")
            Console.WriteLine("        " + programName + " 304500")
            Console.WriteLine("Notes: ")
            Console.WriteLine("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
            Console.WriteLine("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
            Console.WriteLine("        VB.NET: it takes 10.015s using .NET 4.0.30319 with /optimize flag in a 32bit Win7 SP1 VM.")
            Console.WriteLine("")
            Environment.ExitCode = 1
            Exit Sub
        end if

        Dim startTime, endTime As DateTime
        Dim elapsed As TimeSpan
        Dim n, count As Int32

        n = -1
        if Not Int32.TryParse(args(0), n) Or n < 2 then
            Console.Error.WriteLine("ERROR: Argument '" + args(0) + "' not valid.")
            Environment.ExitCode = 1
            Exit Sub
        end if

        startTime = DateTime.Now

        count = findPrimes(n)

        endTime = DateTime.Now
        elapsed = endTime - startTime
        Console.WriteLine("Elapsed: {0,6:f3}s", elapsed.TotalSeconds)

        Console.WriteLine("{0} prime numbers were found between 2 and {1}", count, n)
    End Sub

End Module
