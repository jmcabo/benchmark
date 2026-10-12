(*
Benchmark in StandardML for Poly/ML - by JMC


Compile and Run:
    polyc -o benchmark benchmark.polyml.sml  &&  ./benchmark 30450

To compile with polyc in ubuntu/debian, "libpolyml-dev" must also be installed.


-Notes:
    -The Poly/ML compiler/interpreter implements the Standard ML programming language revision '97.
     Poly/ML development began in 1983, according to the history in the preface of:
            "Papers on Poly/ML" - David C J Matthews
            http://www.lfcs.inf.ed.ac.uk/reports/95/ECS-LFCS-95-335/
     As of 2018, it is still being maintained and developed. Poly/ML is written in C++ and Standard ML.

    -Standard ML is a functional programming language with eager evaluation and support for the imperative
     paradigm. It was standardized in 1990 and revised in 1997.

    -Code run through the interpreter runs at compiled speeds. It probably has on the fly incremental compilation.

    -Integers are 63 bits in the 64-bit version of Poly/ML. Max positive integer is 2^62-1:
            > Int.maxInt;
            val it = SOME 4611686018427387903: int option
            > Int.minInt;
            val it = SOME ~4611686018427387904: int option
     Integers are 31 bits in the 32-bit version of Poly/ML. I performed the benchmark in both versions
     since it runs a couple of times faster in the 32-bit version (the intel IDIV instruction for remainder
     operation is faster with 32-bit registers).
     There is also the IntInf type, which is arbitrary precision (like the value returned by Time.toMilliseconds).

    -In Standard ML, "-1" is expressed as "~1" because "-" is always parsed as an operator function.
     Compared to OCaml, instead of "||" and "&&" it has "orelse" and "andalso". Instead of "!=" and "==" it
     has "<>" and just "=". In Standard ML, many functions in the standard library take tuples when there is
     more than one argument, instead of just many individual arguments.

    -Standard ML doesn't have FOR loops, but does have WHILE loops (OCaml has both).

    -The "Int.rem" function is a bit faster than the "mod" operator. They differ with negative divisors.
     "Int.rem" matches the result of Intel x86 IDIV directly, and of the C modulus "%" operator.

    -The only way to break out of a WHILE imperative loop is by throwing an exception.


Limitations:
    -Poly/ML provides both an interactive interpreter and a compiler. Interpreted code runs at the same speed as
     compiled code in Poly/ML. It is possible to use a shebang like this one:
            #!/usr/bin/poly --script
     but I didn't do it in this file because the CommandLine.arguments() work different from when the
     code is compiled to a standalone executable. Also, when running with "poly --script" one needs to call main
     explicitly like this:
            val _ = Benchmark.main ();
     instead of providing the main function entry point. but if I leave that line in, then the "polyc" compiler
     fails (because the "polyc" compiler works by first loading the file and running it and that would interrupt
     the load). The "polyc" compiler also fails if the shebang line is present.


*)


structure Benchmark =
struct


(* For list operations, to write foldl instead of List.foldl *)
open List

(* For breaking out of imperative WHILE loops: *)
exception BreakLoop


(* NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
 * that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
 * but puts the function in a loop and counts 10000 calls).
 * Returns how many prime numbers exist between 2 and n:
*)
(* Fastest version in the file. Without mutation and tail-recursive: *)
(*   Poly/ML 32bits: Execution time is 0.164s for n=30450 and 12.903s for n=304500. *)
(*   Poly/ML 64bits: Execution time is 0.373s for n=30450 and 31.863s for n=304500. *)
fun findPrimes n =
  let
    fun isPrime i j =
      if j < i then
        if Int.rem(i, j) = 0 then false
        else isPrime i (j + 1)
      else true

    fun countPrimes count i =
      if i <= n then
        countPrimes (if isPrime i 2 then count + 1 else count) (i + 1)
      else count
  in
    countPrimes 0 2
  end


(* Version with imperative WHILE loops and mutable variables. *)
(* FAST. Almost as fast as findPrimes (not exactly the same, perhaps for *)
(* the raise/handle exception for breaking out of the loop): *)
fun findPrimes_While n =
  let
    val count = ref 0
    val i = ref 0
    val j = ref 0
  in
    (* For each number up to 'n': *)
    i := 2;
    while !i <= n do (
      (
        j := 2;
        while !j < !i do (  (* NOT using the sqrt optimization (for easier benchmarking). *)
          (* If i divisible by j, it wasn't a prime number: *)
          if Int.rem(!i, !j) = 0 then
            raise BreakLoop
          else ();
          j := !j + 1
        );
        (* The previous loop ended without divisors found. It is a prime number. *)
        count := !count + 1
      ) handle BreakLoop => ();
      i := !i + 1
    );
    !count
  end


(* Helper function for generating lists of integers. For (range 5 10) returns [5,6,7,8,9,10]. *)
(* SLOW. Using List.tabulate for this is not a good idea, much slower than the recursive version. *)
fun rangeTabulate a b =
  List.tabulate (b - a + 1, fn x => x+a)


(* Helper function for generating lists of integers. For (range 5 10) returns [5,6,7,8,9,10]. *)
(* Range function from:
        "OCaml Tutorials -> If Statements, Loops and Recursion"
        https://ocaml.org/learn/tutorials/if_statements_loops_and_recursion.html#Tail-recursion
   It is tail-recursive. *)
(* FAST. *)
fun range a b =
  let fun rangeRec a b accum = if b < a then accum
                               else rangeRec a (b-1) (b :: accum)
  in rangeRec a b []
  end


(* Sum function for a list of integers (not included in standard library!) *)
fun sum xs =
  foldl (op+) 0 xs


(* Version using a list allocated only once, and with exists and fold. It stops at first divisor found. *)
(* But for prime numbers it iterates more until n instead of i. Not the same algorithm. *)
(* It's also O(n) in space and in allocations. *)
(* 1.8x slower than findPrimes in 32-bits Poly/ML. *)
fun findPrimes_ListOneAlloc n =
  let fun isPrime numbers i = not (exists (fn j => j < i andalso i mod j = 0) numbers)
      val listToN = range 2 n
  in foldl (fn (i, count) => count + (if isPrime listToN i then 1 else 0)) 0 listToN
  end


(* Version using lists and 'exists' with predicates. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (11x slower than findPrimes in 32-bits Poly/ML). *)
fun findPrimes_ListExists n =
  let fun isPrime i = not (exists (fn j => i mod j = 0) (range 2 (i-1)))
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and find with predicates. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (11x slower than findPrimes in 32-bits Poly/ML). *)
fun findPrimes_ListFind n =
  let fun isPrime i = NONE = (find (fn j => i mod j = 0) (range 2 (i-1)));
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and 'map' with a 1 if prime and 0 if not. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (11x slower than findPrimes in 32-bits Poly/ML). *)
fun findPrimes_ListMap n =
  let fun isPrime1 i = if (exists (fn j => i mod j = 0) (range 2 (i-1))) then 0 else 1
  in sum (map isPrime1 (range 2 n))
  end


(* Version using lists and filter with predicates. It doesn't stop at first divisor found and *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (28x slower than findPrimes in 32-bits Poly/ML). *)
fun findPrimes_ListFilter n =
  let fun isPrime i = length (filter (fn j => i mod j = 0) (range 2 (i-1))) = 0
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and 'foldl' and filter with predicates. It doesn't stop at first divisor found. *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (28x slower than findPrimes in 32-bits Poly/ML). *)
fun findPrimes_ListFold n =
  let fun isPrime i = foldl (fn (j, a) => i mod j <> 0 andalso a) true (range 2 (i-1))
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and 'foldl' with predicates. It doesn't stop at first divisor found. *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (30x slower than findPrimes in 32-bits Poly/ML). *)
fun findPrimes_ListFoldFold n =
  let fun isPrime i = foldl (fn (j, a) => i mod j <> 0 andalso a) true (range 2 (i-1))
  in foldl (fn (i, count) => count + (if isPrime i then 1 else 0)) 0 (range 2 n)
  end


fun main () =
  let in
    if List.length (CommandLine.arguments ()) <> 1 then (
      print "Quick and dirty single thread CPU benchmark - by JMC\n";
      print "Usage: \n";
      print "        Pass an argument up to which prime numbers will be searched with\n";
      print "        an inefficient algorithm, useful to compare the single thread performance\n";
      print "        of the CPU\n";
      print "Example: \n";
      print ("        " ^ CommandLine.name () ^ " 304500\n");
      print "Notes: \n";
      print "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n";
      print "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n";
      print "        StandardML/PolyML-32bits: it takes 12.903s using Poly/ML 5.7.1 32-bits.\n";
      print "        StandardML/PolyML: it takes 31.863s using Poly/ML 5.7 64-bits.\n";
      print "\n";
      OS.Process.exit OS.Process.failure
    ) else ();

    let
      val nStr = List.hd (CommandLine.arguments ())
      val (n, rest) = valOf (Int.scan StringCvt.DEC Substring.getc (Substring.full nStr))
                      handle Option => (~1, Substring.full "")
                           | Overflow => (~1, Substring.full "")
    in
      if size (Substring.string rest) <> 0 orelse n < 2 then (
        TextIO.output (TextIO.stdErr, "ERROR: Argument '" ^ nStr ^ "' not valid.\n");
        OS.Process.exit OS.Process.failure
      ) else ();

      let
        val startTime = Time.now ()

        val count = findPrimes n
        (* val count = findPrimes_While n *)
        (* val count = findPrimes_ListOneAlloc n *)
        (* val count = findPrimes_ListExists n *)
        (* val count = findPrimes_ListFind n *)
        (* val count = findPrimes_ListMap n *)
        (* val count = findPrimes_ListFilter n *)
        (* val count = findPrimes_ListFold n *)
        (* val count = findPrimes_ListFoldFold n *)

        val endTime = Time.now ()
        val elapsed = (Real.fromLargeInt (Time.toMilliseconds (Time.- (endTime, startTime)))) / 1000.0
        val _ = print ("Elapsed: " ^ StringCvt.padLeft #" " 6 (Real.fmt (StringCvt.FIX (SOME 3)) elapsed) ^ "s\n")
      in
        print (Int.toString count ^ " prime numbers were found between 2 and " ^ Int.toString n ^ "\n")
      end
    end
  end


(* End of "Benchmark" structure: *)
end

(* polyc entry point: *)
fun main () =
  Benchmark.main()

