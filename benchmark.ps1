#Run as:
#    powershell
#    .\benchmark.ps1 304500
#or just:
#    powershell -f benchmark.ps1 304500
#
#Notes:
#   -Use $lastExitCode to see errorlevel when inside powershell console.
#   -To allow non signed script execution, run a powershell console as Admin and do:
#        set-executionpolicy Unrestricted
#    To put it back after running the benchmark, do:
#        set-executionpolicy Restricted
#    Find current value with:
#        get-executionpolicy
#   -To determine powershell version:
#        echo $PSVersionTable


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
function findPrimes([int32] $n) {
    #Using explicit [int32] type declarations it gets slightly faster (about 10%):
    [int32] $i = 0;
    [int32] $j = 0;
    [int32] $count = 0;

    #For each number up to 'n':
    foreach ($i in 2..$n) {
        #Note: The last value of the variable is the right hand side of the foreach range, if it doesn't break.
        foreach ($j in 2..$i) {  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if ($i % $j -eq 0) {
                break
            }
        }
        if ($i -eq $j) {
            #The previous loop ended without divisors found. It is a prime number.
            ++$count
        }
    }

    return $count
}


#Slower than the "foreach in range" version (1.6 times slower).
#Maybe the foreach version runs more of the loop in native code versus
#having the variable increments and loop guards in interpreted code.
function findPrimes_For($n) {
    $count = 0;

    #For each number up to 'n':
    for ($i=2; $i -le $n; ++$i) {
        for ($j=2; $j -lt $i; ++$j) {  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if ($i % $j -eq 0) {
                break
            }
        }
        if ($i -eq $j) {
            #The previous loop ended without divisors found. It is a prime number.
            ++$count
        }
    }

    return $count
}


#As slow as the For version.
function findPrimes_While($n) {
    $count = 0;

    #For each number up to 'n':
    $i = 2
    while ($i -le $n) {
        $j = 2
        while ($j -lt $i) {
            #If i divisible by j, it wasn't a prime number:
            if ($i % $j -eq 0) {
                break
            }
            ++$j
        }
        if ($i -eq $j) {
            #The previous loop ended without divisors found. It is a prime number.
            ++$count
        }
        ++$i
    }

    return $count
}


function main ($argv) {
    $programName = $myInvocation.ScriptName
    $programName = Split-Path -Leaf $programName

    if ($argv.length -ne 1) {
        echo "Quick and dirty single thread CPU benchmark - by JMC"
        echo "Usage: "
        echo "        Pass an argument up to which prime numbers will be searched with"
        echo "        an inefficient algorithm, useful to compare the single thread performance"
        echo "        of the CPU"
        echo "Example: "
        echo ("        .\{0} 304500" -f $programName)
        echo "Notes: "
        echo "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        echo "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        echo "        PowerShell: it takes 315.580s using Powershell 4.0 build 6.3.9600.16394 in a 64bit Win8.1 VM."
        echo "        PowerShell: it takes 411.215s using Powershell 3.0 build 6.2.9200.16398 in a 32bit Win7 SP1 VM."
        echo "        PowerShell: it takes an estimated 5296s (1h 28m) with the Foreach loop using Powershell 2.0 build 6.1.7600.16385 in a 32bit Win7 SP1 VM. For benchmark 30450, it takes 65.286s."
        echo ""
        exit 1
    }

    $n = -1
    if (-not [int32]::TryParse($argv[0], [ref] $n) -or $n -lt 2) {
        $msg = "ERROR: Argument '" + $argv[0] + "' not valid."
        [Console]::Error.WriteLine($msg)
        exit 1
    }

    $startTime = get-date

    $count = findPrimes $n

    $endTime = get-date
    $elapsed = ($endTime - $startTime).TotalMilliseconds / 1000.0
    echo ("Elapsed: {0,6:f3}s" -f $elapsed)

    echo "$count prime numbers were found between 2 and $n"
}


main $args

