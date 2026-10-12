#!/usr/bin/env ocaml
(*
Benchmark in OCaml - by JMC


Note: Don't use the ocaml interpreter for benchmarking, it's about 2x or more slower. Use
the ocamlopt compiler instead.

Compile and run:
        ocamlopt -pp 'sed "1 s/^\#\!.*$//"' -unsafe -o benchmark benchmark.ocaml.ml  &&  ./benchmark 304500
Compile:
    Comment the shebang line (first line) and then:
        ocamlopt -o benchmark benchmark.ocaml.ml
    or replace the shebang on the fly like this:
        ocamlopt -pp 'sed "1 s/^\#\!.*$//"' -o benchmark benchmark.ocaml.ml
    pass -unsafe to turn off checking if modulus argument is zero (faster):
        ocamlopt -pp 'sed "1 s/^\#\!.*$//"' -unsafe -o benchmark benchmark.ocaml.ml


Notes:
    -OCaml is an eager evaluation functional language with support for the imperative paradigm.
     It was created in 1996. It is closely related to Standard ML, sharing many ideas but
     with slightly different syntax, and adding object-oriented capabilities.

    -Integers are 63 bits in the 64-bit version of OCaml and 31 bits in the 32-bit version:
     The max int is 2^62-1, that is 63 bits for the 64-bit version:
        # max_int;;
        - : int = 4611686018427387903
        # min_int;;
        - : int = -4611686018427387904

    -Use rlwrap to have command line editing and history in the interpreter:
        rlwrap ocaml

    -CTRL+D can be used to exit the interpreter.

    -Ideally use 2 spaces for indentation. Formatting style and guidelines for OCaml code:
        "OCaml Programming Guidelines"
        https://ocaml.org/learn/tutorials/guidelines.html
        https://caml.inria.fr/resources/doc/guides/guidelines.en.html

    -Comments are always delimited by (* and *) and can be nested. There is no single-line comment
     delimiter.

    -There is no list comprehension in the language by default but it can be added with
     a "camlp4" preprocessor like "pa_comprehension".
     List comprehensions won't be as fast as Haskell's because OCaml is not a lazy evaluation language.
     Haskell might avoid allocating a list at all for example.

    -In Haskell it is recommended to use foldr (instead of foldl) since it doesn't need the
     whole list before it starts producing results (a lazy evaluation matter) and can short-circuit
     the rest of the list. In fact in Haskell documentation, foldl requires the list to be finite.
     For foldr the list can be infinite and can be short-circuited.
        Here in OCaml, fold_left is preferred over fold_right since fold_right is not tail-recursive.
     There is no lazy evaluation in OCaml, so fold_right doesn't have a special advantage.

    -In the OCaml library, the map function is not tail-recursive. The reverse version, rev_map, is
     tail-recursive but returns the result in reverse order.

    -The only way to break out of a WHILE or FOR imperative loop is by throwing an exception.


Limitations:
    -Sys.time doesn't return the time of a wall clock but instead the time that the process
     has been running. If we execute the sleep BASH command in the shell, by calling:
             Sys.command "sleep 2";
     then the elapsed time will measure almost zero with Sys.time, because it only measures time
     in the current ocaml process.
     There are libraries that provide a precise wall clock, but nothing inside the standard library.
     It works fine for benchmarking pure OCaml code that doesn't interact with the OS.
     Sys.time has more than millisecond precision.

*)


(* For list operations, to write fold_left instead of List.fold_left *)
open List;;

(* For breaking out of imperative WHILE and FOR loops: *)
exception BreakLoop;;


(* NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
 * that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
 * but puts the function in a loop and counts 10000 calls).
 * Returns how many prime numbers exist between 2 and n:
*)
(* Fastest version in the file. Without mutation and tail-recursive: *)
(*   OCaml 32bits: Execution time is 0.132s for n=30450 and 10.940s for n=304500. *)
(*   OCaml 64bits: Execution time is 0.353s for n=30450 and 28.602s for n=304500. *)
let findPrimes n =

  let rec isPrime i j =
    if j < i then
      if i mod j == 0 then false
      else isPrime i (j + 1)
    else true
  in

  let rec countPrimes c i =
    if i <= n then
      countPrimes (if isPrime i 2 then c + 1 else c) (i + 1)
    else c
  in

  countPrimes 0 2
;;


(* Version with imperative FOR loops and mutable variables. *)
(* FAST *)
let findPrimes_For n =
  let count = ref 0 in
  (* For each number up to 'n': *)
  for i = 2 to n do
    try
      for j = 2 to i-1 do  (* NOT using the sqrt optimization (for easier benchmarking). *)
        (* If i divisible by j, it wasn't a prime number: *)
        if i mod j == 0 then
          raise BreakLoop
      done;
      (* The previous loop ended without divisors found. It is a prime number. *)
      count := !count + 1
    with BreakLoop -> ();
  done;
  !count
;;


(* Version with imperative WHILE loops and mutable variables. *)
(* FAST *)
let findPrimes_While n =
  let count = ref 0 in
  let i = ref 0 in
  let j = ref 0 in
  (* For each number up to 'n': *)
  i := 2;
  while !i <= n do
    (try
      j := 2;
      while !j < !i do  (* NOT using the sqrt optimization (for easier benchmarking). *)
        (* If i divisible by j, it wasn't a prime number: *)
        if !i mod !j == 0 then begin
          raise BreakLoop
        end;
        j := !j + 1
      done;
      (* The previous loop ended without divisors found. It is a prime number. *)
      count := !count + 1
    with BreakLoop -> ());
    i := !i + 1
  done;
  !count
;;


(* Range function from:
        "OCaml Tutorials -> If Statements, Loops and Recursion"
        https://ocaml.org/learn/tutorials/if_statements_loops_and_recursion.html#Tail-recursion
   It is tail-recursive. *)
let range a b =
  let rec rangeRec a b accum = if b < a then accum
                               else rangeRec a (b-1) (b :: accum)
  in rangeRec a b []
;;


(* Sum function for a list of integers (not included in standard library!) *)
let sum xs =
  fold_left (+) 0 xs
;;


(* Version using a list allocated only once, and with exists and fold. It stops at first divisor found. *)
(* But for prime numbers it iterates more until n instead of i. Not the same algorithm. *)
(* It's also O(n) in space and in allocations. *)
(* FAST (only 1.5x slower than findPrimes) *)
let findPrimes_ListOneAlloc n =
  let isPrime numbers i = not (exists (fun j -> j < i && i mod j == 0) numbers) in
  let listToN = range 2 n in
  fold_left (fun count i -> count + if isPrime listToN i then 1 else 0) 0 listToN
;;


(* Version using lists and 'exists' with predicates. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (10x slower than findPrimes). *)
let findPrimes_ListExists n =
  let isPrime i = not (exists (fun j -> i mod j == 0) (range 2 (i-1))) in
  length (filter isPrime (range 2 n))
;;


(* Version using lists and find with predicates. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (10x slower than findPrimes). *)
let findPrimes_ListFind n =
  let isPrime i =
    try
      ignore (find (fun j -> i mod j == 0) (range 2 (i-1)));
      false
    with Not_found -> true
  in
  length (filter isPrime (range 2 n))
;;


(* Version using lists and 'map' with a 1 if prime and 0 if not. It stops at first divisor found for each number. *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (10x slower than findPrimes). *)
let findPrimes_ListMap n =
  let isPrime1 i = if (exists (fun j -> i mod j == 0) (range 2 (i-1))) then 0 else 1 in
  sum (rev_map isPrime1 (range 2 n))
;;


(* Version using lists and filter with predicates. It doesn't stop at first divisor found and *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (20x slower than findPrimes). *)
let findPrimes_ListFilter n =
  let isPrime i = length (filter (fun j -> i mod j == 0) (range 2 (i-1))) == 0 in
  length (filter isPrime (range 2 n))
;;


(* Version using lists and 'fold_left' and filter with predicates. It doesn't stop at first divisor found. *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (20x slower than findPrimes). *)
let findPrimes_ListFold n =
  let isPrime i = fold_left (fun a j -> i mod j != 0 && a) true (range 2 (i-1)) in
  length (filter isPrime (range 2 n))
;;


(* Version using lists and 'fold_left' with predicates. It doesn't stop at first divisor found. *)
(* that means that it iterates more than the other versions (and is not the same algorithm). *)
(* It's also O(n) in space (if the GC frees fast), but O(n^2) in allocations. *)
(* VERY SLOW (20x slower than findPrimes). *)
let findPrimes_ListFoldFold n =
  let isPrime i = fold_left (fun a j -> i mod j != 0 && a) true (range 2 (i-1)) in
  fold_left (fun count i -> count + if isPrime i then 1 else 0) 0 (range 2 n)
;;


let main () =
  if Array.length Sys.argv <> 2 then begin
    print_endline "Quick and dirty single thread CPU benchmark - by JMC";
    print_endline "Usage: ";
    print_endline "        Pass an argument up to which prime numbers will be searched with";
    print_endline "        an inefficient algorithm, useful to compare the single thread performance";
    print_endline "        of the CPU";
    print_endline "Example: ";
    print_endline ("        " ^ Sys.argv.(0) ^ " 304500");
    print_endline "Notes: ";
    print_endline "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz";
    print_endline "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.";
    print_endline "        OCaml-32bits: it takes 10.916s using OCaml 4.05.0 32-bits with flag -unsafe.";
    print_endline "        OCaml: it takes 28.602s using OCaml 4.04.0 64-bits with flag -unsafe.";
    print_newline ();
    exit 1
  end;

  let n = try int_of_string Sys.argv.(1)
          with Failure x -> -1 in
  if n < 2 then begin
    Printf.eprintf "ERROR: Argument '%s' not valid.\n" Sys.argv.(1);
    exit 1;
  end;

  let startTime = Sys.time () in

  let count = findPrimes n in
  (* let count = findPrimes_For n in *)
  (* let count = findPrimes_While n in *)
  (* let count = findPrimes_ListOneAlloc n in *)
  (* let count = findPrimes_ListExists n in *)
  (* let count = findPrimes_ListFind n in *)
  (* let count = findPrimes_ListMap n in *)
  (* let count = findPrimes_ListFilter n in *)
  (* let count = findPrimes_ListFold n in *)
  (* let count = findPrimes_ListFoldFold n in *)

  let endTime = Sys.time () in
  let elapsed = endTime -. startTime in
  Printf.printf "Elapsed: %6.3fs\n" elapsed;

  Printf.printf "%d prime numbers were found between 2 and %d\n" count n;
;;


main () ;;

