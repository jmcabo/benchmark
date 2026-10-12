(*
Benchmark in StandardML for SML/NJ - by JMC


Run:
        sml benchmark.smlnj.sml
or:
        echo 304500 | sml benchmark.smlnj.sml

Notes on compiling:
    The SML/NJ compiler produces the same speed as the interpreter, and it doesn't produce a standalone
    Linux binary but instead a "heap image" that still requires the "sml" command to run. It also requires
    an extra .cm file with build instructions (".cm" stands for Compiler Manager).
    So I'll be using only the interpreter.
    For instructions on how to create an image for "sml @SMLload", see:
            "SML-NJ, how to compile standalone executable"
            https://stackoverflow.com/questions/5053149/sml-nj-how-to-compile-standalone-executable
    and see "heap2exec" (unmaintained) and:
            "How to compile and execute a stand-alone SML-NJ executable"
            https://stackoverflow.com/questions/34015825/how-to-compile-and-execute-a-stand-alone-sml-nj-executable


-Notes:
    -The SML/NJ compiler implements the Standard ML programming language revision '97. SML/NJ stands for
     "Standard ML of New Jersey". I can't find a date of creation, but a copyright notice has the year 1989 in it.
     It was originally developed by Bell Laboratories and Princeton University. As of 2018, it is still being
     maintained and developed.

    -Standard ML is a functional programming language with eager evaluation and support for the imperative
     paradigm. It was standardized in 1990 and revised in 1997.

    -Code run through the interpreter runs at compiled speeds. It has on the fly incremental compilation.

    -Integers are 31bits in the 64bit version of SML/NJ. Max positive integer is 2^30-1:
            - Int.maxInt;
            val it = SOME 1073741823 : int option
            - Int.minInt;
            val it = SOME ~1073741824 : int option
     There is also the IntInf type, which is arbitrary precision (like the value returned by Time.toMilliseconds).

    -Use rlwrap to have command line editing and history in the interpreter:
            rlwrap sml

    -CTRL+D can be used to exit the interpreter.

    -In Standard ML, "-1" is expressed as "~1" because "-" is always parsed as an operator function.
     Compared to OCaml, instead of "||" and "&&" it has "orelse" and "andalso". Instead of "!=" and "==" it
     has "<>" and just "=". In Standard ML, many functions in the standard library take tuples when there is
     more than one argument, instead of just many individual arguments.

    -Standard ML doesn't have FOR loops, but does have WHILE loops (OCaml has both).

    -The "Int.rem" function is a bit faster than the "mod" operator. They differ with negative divisors.
     "Int.rem" matches the result of Intel x86 IDIV directly, and of the C modulus "%" operator.

    -The only way to break out of a WHILE imperative loop is by throwing an exception.


-Limitations:
    -The SML/NJ interpreter doesn't pass command line arguments to the CommandLine module. That is why I ask the
     user interactively for the 'n' number.

    -The SML/NJ interpreter prints extra messages when the program starts, and when it ends. That makes it
     a bit unsuitable for creating shell scripts.
     Also there is no shebang support. See this bug report by someone in the internet:
          "[#84] No shebang support"
          https://smlnj-gforge.cs.uchicago.edu/tracker/index.php?func=detail&aid=84&group_id=33&atid=215

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
(*   SML/NJ: Execution time is 0.146s for n=30450 and 11.818s for n=304500. *)
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
(* 2.3x slower than findPrimes *)
fun findPrimes_ListOneAlloc n =
  let fun isPrime numbers i = not (exists (fn j => j < i andalso i mod j = 0) numbers)
      val listToN = range 2 n
  in foldl (fn (i, count) => count + (if isPrime listToN i then 1 else 0)) 0 listToN
  end


(* Version using lists and 'exists' with predicates. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (12x slower than findPrimes). *)
fun findPrimes_ListExists n =
  let fun isPrime i = not (exists (fn j => i mod j = 0) (range 2 (i-1)))
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and find with predicates. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (12x slower than findPrimes). *)
fun findPrimes_ListFind n =
  let fun isPrime i = NONE = (find (fn j => i mod j = 0) (range 2 (i-1)));
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and 'map' with a 1 if prime and 0 if not. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (12x slower than findPrimes). *)
fun findPrimes_ListMap n =
  let fun isPrime1 i = if (exists (fn j => i mod j = 0) (range 2 (i-1))) then 0 else 1
  in sum (map isPrime1 (range 2 n))
  end


(* Version using lists and filter with predicates. It doesn't stop at first divisor found and *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (23x slower than findPrimes). *)
fun findPrimes_ListFilter n =
  let fun isPrime i = length (filter (fn j => i mod j = 0) (range 2 (i-1))) = 0
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and 'foldl' and filter with predicates. It doesn't stop at first divisor found. *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (25x slower than findPrimes). *)
fun findPrimes_ListFold n =
  let fun isPrime i = foldl (fn (j, a) => i mod j <> 0 andalso a) true (range 2 (i-1))
  in length (filter isPrime (range 2 n))
  end


(* Version using lists and 'foldl' with predicates. It doesn't stop at first divisor found. *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (24x slower than findPrimes). *)
fun findPrimes_ListFoldFold n =
  let fun isPrime i = foldl (fn (j, a) => i mod j <> 0 andalso a) true (range 2 (i-1))
  in foldl (fn (i, count) => count + (if isPrime i then 1 else 0)) 0 (range 2 n)
  end


fun main () =
  let in
    print "Quick and dirty single thread CPU benchmark - by JMC\n";
    print "Usage: \n";
    print "        Pass an argument up to which prime numbers will be searched with\n";
    print "        an inefficient algorithm, useful to compare the single thread performance\n";
    print "        of the CPU\n";
    print "Example: \n";
    print "        n=304500\n";
    print "Notes: \n";
    print "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n";
    print "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n";
    print "        StandardML/NJ: it takes 11.818s using SML/NJ 110.79.\n";
    print "\n";

    print "Search primes up to? ";
    let
      val nStrWithNewline = valOf (TextIO.inputLine TextIO.stdIn)
      val _ = print "\n"  (* When n is piped, it doesn't leave a newline. *)
      val nStr = Substring.string (Substring.dropr (Char.isSpace) (Substring.full nStrWithNewline))
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
    end;

    (* Exit the interpreter (otherwise after the program ends we get the interpreter prompt). *)
    OS.Process.exit OS.Process.success
  end


(* End of "Benchmark" structure: *)
end

(* Call main in the top-level: *)
val _ = Benchmark.main ();

