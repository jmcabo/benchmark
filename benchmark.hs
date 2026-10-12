#!/usr/bin/runhaskell
--Benchmark in Haskell - by JMC
--
--
--NOTE: Don't benchmark using runhaskell. Use the compiler instead!!!
--(runhaskell passes --interactive to ghc, which disables -O2)
--
--Compile and run manually (much MUCH faster):
--     ghc -O2 -v0 -fforce-recomp -o benchmark benchmark.hs  &&  ./benchmark 304500
--
--Compiling with llvm produces even a bit faster programs but the matching llvm version is not always available:
--     ghc -O2 -v0 -fllvm -fforce-recomp -o benchmark benchmark.hs  &&  ./benchmark 304500
--
--
--Notes:
--    -Haskell is a lazy evaluation purely functional language. It was created in 1990.
--     I have a fondness for haskell since I first learned it in a course at college, but never used
--     it professionally.
--
--    -Don't benchmark using runhaskell. Use the compiler instead!!!
--     (runhaskell passes --interactive to ghc, which disables -O2)
--
--    -Integers are 64-bit in the 64-bit version of Haskell (-2^63 to 2^63-1):
--         # ghc --interactive
--         Prelude> maxBound :: Int
--         9223372036854775807
--         Prelude> minBound :: Int
--         -9223372036854775808
--
--    -Running on a Haskell 64bit installation is slower than running on Haskell 32 bits.
--     This is because "Int" is implemented then as a 64bit value, and the IDIV assembler instruction
--     is slower for 64bit operands.
--     Using the Int32 data type under Haskell 64bits doesn't fix it, in fact it's slower for some reason.
--     The only way is to run it with an i386 GHC build.
--
--    -The 'mod' function is slower than 'rem'. They differ with negative divisors. Rem matches the result
--     of Intel x86 IDIV directly.
--
--    -In Haskell it is recommended to use foldr (instead of foldl) since it doesn't need the
--     whole list before it starts producing results (a lazy evaluation matter) and can short-circuit
--     the rest of the list. In fact in Haskell documentation, foldl requires the list to be finite.
--     For foldr the list can be "infinite" and can be short-circuited.
--
--    -Lazy evaluation speeds up code. But not always in a predictable manner. It can be hard to
--     reason about performance by just looking at a Haskell program. Not all tail-recursive functions
--     will perform as espected. See:
--         "Does Haskell have tail-recursive optimization?"
--         https://stackoverflow.com/questions/13042353/does-haskell-have-tail-recursive-optimization


import Control.Exception
import Data.Time.Clock
import Data.Int
import System.Environment
import System.Exit
import System.IO
import Text.Printf
import Text.Read


--NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
--that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
--but puts the function in a loop and counts 10000 calls).
--Returns how many prime numbers exist between 2 and n:
--
--Using list comprehension and foldr. Lazy evaluation could avoid even allocating a list:
findPrimes :: Int -> Int
findPrimes n = length ([i | i <- [2..n],
                       foldr (\j a -> j == i || (rem i j /= 0 && a)) True [2..i]])  --NOT using the sqrt optimization (for easier benchmarking):

-- --------------------------------------------------------------------------


--Tail-recursive version without using lists or filtering:
--Almost as fast as findPrimes (not exactly the same, for some reason):

isPrime_Rec :: Int -> Int -> Bool
isPrime_Rec i j = if j < i then
                      if rem i j == 0 then False
                      else isPrime_Rec i (j + 1)
                  else True

countPrimes_Rec :: Int -> Int -> Int -> Int
countPrimes_Rec c i n = if i <= n then
                            countPrimes_Rec (if isPrime_Rec i 2
                                             then c + 1
                                             else c)
                                            (i + 1)
                                            n
                        else c

findPrimes_Rec :: Int -> Int
findPrimes_Rec n = countPrimes_Rec 0 2 n

-- --------------------------------------------------------------------------


--Version that uses SQRT optimization and that only checks prime divisors (since
--the list is recursively generated, sieve uses its own output).
--MUCH FASTER than findPrimes, but not the same algorithm/benchmark. Included here only for completeness:
findPrimes_Sieve :: Int -> Int
findPrimes_Sieve n = length (sieve n)
sieve :: Int -> [Int]
sieve n = 2 : [i | i <- [3..n],
               foldr (\j a -> j*j > i || (rem i j /= 0 && a)) True (sieve n)]

-- --------------------------------------------------------------------------


--Other implementations
--(uncomment only one line of each function below):

--isPrime :: Int -> Bool     --NOT using the sqrt optimization (for easier benchmarking):
--isPrime n = null (filter (\x -> rem n x == 0) [2..(n-1)])                          --Using filter.
--isPrime n = foldr (\x a -> (x >= n) || (rem n x /= 0 && a)) True [2..n]            --FAST
--isPrime n = [] == [1 | x <- [2..(n-1)], rem n x == 0]                              --Using list comprehension.
--isPrime n = not (or [True | x <- [2..(n-1)], rem n x == 0])                        --Using or over bool list comprehension.
--isPrime n = (and (map (\x -> rem n x /= 0) [2..(n-1)]))                            --Using map.
--isPrime n = not (or (map (\x -> rem n x /= 0) [2..(n-1)]))                         --Using map.
--isPrime n = (foldr (\x a -> if n `rem` x == 0 then False else a) True [2..(n-1)])  --Using shortcircuiting foldr.

--Returns 1 or 0 instead of Bool (for map):
--isPrime1 :: Int -> Int
--isPrime1 n = if [] == [1 | x <- [2..(n-1)], n `rem` x == 0] then 1 else 0    --NOT using the sqrt optimization (for easier benchmarking).

--primes o = 2 : [n | n <- [3..o], foldr (\x a -> (x >= n) || (rem n x /= 0 && a)) True [2..n]]     --FAST

--findPrimes :: Int -> Int
--findPrimes n = length (filter isPrime [2..n])    --FAST
--findPrimes n = length (primes n)
--findPrimes n = foldr (+) 0 (map isPrime1 [2..n])
--findPrimes n = sum (map isPrime1 [2..n])
--findPrimes n = sum [1 | x <- [2..n], isPrime x]

-- --------------------------------------------------------------------------


--Slower recursive version without using lists or filtering. findPrimes_Slow is not tail recursive:

isPrime_Slow :: Int -> Int -> Bool
isPrime_Slow n x
    | x == 1 = True
    | rem n x == 0 = False
    | otherwise = isPrime_Slow n (x - 1)

findPrimes_Slow :: Int -> Int
findPrimes_Slow 2 = 1
findPrimes_Slow n = findPrimes_Slow (n - 1) + (if isPrime_Slow n (n - 1) then 1 else 0)

-- --------------------------------------------------------------------------


main = do
    programName <- System.Environment.getProgName

    args <- System.Environment.getArgs

    if (length args) /= 1 then do
        putStrLn "Quick and dirty single thread CPU benchmark - by JMC"
        putStrLn "Usage: "
        putStrLn "        Pass an argument up to which prime numbers will be searched with"
        putStrLn "        an inefficient algorithm, useful to compare the single thread performance"
        putStrLn "        of the CPU"
        putStrLn "Example: "
        putStrLn $ "        " ++ programName ++ " 304500"
        putStrLn "Notes: "
        putStrLn "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        putStrLn "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        putStrLn "        Haskell32bits: it takes 8.854s with lists using Haskell GHC 8.0.1 and llvm 3.7.1 and flags -O2 -v0 -fllvm -fforce-recomp."
        putStrLn "        Haskell32bits: it takes 9.971s with lists using Haskell GHC 7.6.3 and flags -O2 -v0 -fllvm -fforce-recomp."
        putStrLn "        Haskell: it takes 29.597s with lists using Haskell GHC 7.6.3 and flags -O2 -v0 -fllvm -fforce-recomp."
        putStrLn "        Haskell: it takes 240.740s with naive implementation, using Haskell GHC 7.6.3 and flags -O2 -v0 -fllvm -fforce-recomp."
        putStrLn ""
        exitWith (ExitFailure 1)
    else
        evaluate()


    n <- case (readMaybe (args!!0) :: Maybe Int) of
            Just x -> return x
            Nothing -> return (-1)
    if n < 2 then do
        hPrintf stderr "ERROR: Argument '%s' not valid.\n" (args!!0)
        exitWith (ExitFailure 1)
    else
        evaluate()


    let getSeconds = getCurrentTime >>= return . fromRational . toRational . utctDayTime
    startTime <- getSeconds

    count <- evaluate (findPrimes n)
    --count <- evaluate (findPrimes_Rec n)
    --count <- evaluate (findPrimes_Sieve n)
    --count <- evaluate (findPrimes_Slow n)

    endTime <- getSeconds
    elapsed <- return (endTime - startTime)
    printf "Elapsed: %6.3fs\n" (elapsed :: Double)

    printf "%d prime numbers were found between 2 and %d\n" (count :: Int) (n :: Int)


