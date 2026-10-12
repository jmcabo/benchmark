#!/usr/bin/guile -s
!#
;;; Benchmark in Scheme Lisp for the GNU Guile compiler/interpreter/VM - by JMC
;;;
;;;
;;; Run:
;;;         ./benchmark.guile.scm 304500
;;; or
;;;         guile -s benchmark.guile.scm 304500
;;; Guile automatically compiles the file to bytecode before running it, and uses the directory
;;; "~/.cache/guile" as cache. It only recompiles when the file is newer than the cache.
;;;
;;;
;;; Notes:
;;;     -GNU Guile implements the Scheme Lisp language. Guile was first released in 1993 and it is still
;;;      being maintained and developed as of 2018.
;;;      It is both a standalone interpreter and an embeddable interpreter. Successful software such as
;;;      GnuCash and LillyPond use it as their scripting/extension language.
;;;      GNU Guile actually runs code in a bytecode VM, after first compiling Scheme code to bytecode.
;;;      There is a project to remake Emacs Lisp to run in this VM, since Guile is faster.
;;;
;;;     -Guile is very complete in its support of SRFI modules from the Scheme standard and comes by
;;;      default with many SRFI modules. It also supports and comes with the SLIB portable scheme
;;;      library which is full of useful stuff.
;;;
;;;     -GNU Guile is the language of choice by the GNU Project for adding a scripting language to programs.
;;;
;;;     -The 'modulo' function is slower than 'remainder'. They differ with negative divisors.
;;;      'remainder' matches the result of Intel IDIV directly.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 62 bits in
;;;      the 64-bit version of GNU Guile:
;;;             scheme@(guile-user)> (import (rnrs (6)))
;;;             scheme@(guile-user)> (greatest-fixnum)
;;;             $1 = 2305843009213693951
;;;             scheme@(guile-user)> (least-fixnum)
;;;             $2 = -2305843009213693952
;;;             scheme@(guile-user)>
;;;      If one adds 1 to (greatest-fixnum), it becomes a Bignum automatically.
;;;
;;;     -For some reason, using fixnum only functions like fx+ and fxmod is slower in GNU Guile than
;;;      using just + and remainder.
;;;
;;;     -Ideally use 2 spaces for indentation. Formatting style for Lisp code:
;;;             "Lisp Style Tips for the Beginner - Heinrich Taube"
;;;             http://people.ace.ed.ac.uk/staff/medward2/class/moz/cm/doc/contrib/lispstyle.html
;;;
;;;     -Parsing an integer can be tricky: the 'string->number' function accepts many types of numbers
;;;      such as: "3", "1+2i", "3.5", "3.", "3/2", "4/2", "#xFF", etc. It is important to filter out or
;;;      truncate inexact numbers such as "3." because they won't work with fixnum operations. Filtering
;;;      complex numbers is also necessary. This can be done with functions like 'truncate', 'integer?',
;;;      'inexact?' and 'fixnum?'.
;;;
;;;
;;; Limitations:
;;;     -The first time that a script is run, or the first time after the source file is modified,
;;;      GNU Guile outputs to STDERR some messages about compilation. I couldn't find a way to disable
;;;      those messages. This makes Guile less than ideal for creating linux scripts. Although if they
;;;      are for personal use, one can easily tolerate the extra messages (as long as other scripts
;;;      don't need to parse the output when including STDERR).
;;;


;; For a (format) with float precision and padding:
(use-modules (ice-9 format))

;; For (iota) with initial value and step:
(use-modules (srfi srfi-1))

;; For list comprehensions with (list-ec) and (: x n):
(use-modules (srfi srfi-42))

;; For fixnum operations like fx+ or fxmod:
;(import (rnrs (6)))
(use-modules ((rnrs) :version (6)))


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
;;;
;;; Purely functional implementation,
;;; with "let" and tail-recursion, and without "set!"ing mutable variables.
;;; FASTEST in guile.
(define (findPrimes n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (< j i)   ;NOT using the sqrt optimization (for easier benchmarking):
          (and (> (remainder i j) 0) (loop (1+ j)))
          #t)))
  (let loop ((i 2)
             (count 0))
    (if (<= i n)
        (loop (1+ i)
              (if (isPrime i) (1+ count) count))
        count)))


;;; Sieve taken from
;;;     http://srfi.schemers.org/srfi-42/srfi-42.html
;;; It's ORDERS OF MAGNITUDE FASTER, but it's not the same benchmark
;;; (which is comparing about 3.8 billion iterations in each language).
(define (findPrimesEratosthenes n)          ; primes in {2..n} for n >= 1
  (set! n (+ n 1))
  (let ((p? (make-string n #\1)))
    (do-ec (:range k 2 n)
           (if (char=? (string-ref p? k) #\1))
           (:range i (* 2 k) n k)
           (string-set! p? i #\0))
    (sum-ec (:range k 2 n) (if (char=? (string-ref p? k) #\1)) 1)))


;--------------------------------------------------------------------------
;Other implementations:


;;; Version using fixnum operations from rnrs, otherwise same as findPrimes.
;;; Instead of gaining speed, in Guile these fixnum operations are slower.
;;; VERY SLOW
(define (findPrimes_Fixnum n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (fx<? j i)   ;NOT using the sqrt optimization (for easier benchmarking):
          (and (fx>? (fxmod i j) 0) (loop (fx+ j 1)))
          #t)))
  (let loop ((i 2)
             (count 0))
    (if (fx<=? i n)
        (loop (fx+ i 1)
              (if (isPrime i) (fx+ count 1) count))
        count)))


;;; Purely functional implementation
;;; with list comprehension and "lambda" and tail-recursion.
;;; (Without using set! or mutating variables).
;;; FAST
(define (findPrimes_ListEC n)
    (define (isPrime i)
      (define loop
        (lambda (j)
          (if (< j i)
              (and (> (remainder i j) 0) (loop (1+ j)))
              #t)))
      (loop 2))
    (length (list-ec (: i 2 (1+ n))
                     (if (isPrime i))
                     i)))


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; FAST
(define (findPrimes_Do n)
  (define count 0)
  (do ((i 2 (1+ i)))
      ((> i n))
    (do ((j 2 (1+ j)))
        ((or (>= j i) (= (remainder i j) 0))
      (if (= i j)
          (set! count (1+ count))))))
  count)


;;; Using (while) loops:
;;; The while loop has this form:
;;;      (while condition body... )
;;; Accepts (break) and also (continue) inside.
;;; FAST
(define (findPrimes_While n)
    (define i 0)
    (define j 0)
    (define count 0)
    (set! i 2)
    (while (<= i n)
        (set! j 2)
        (while (< j i)
            (if (= (remainder i j) 0)
                (break))
            (set! j (1+ j)))
        (if (= i j)
            (set! count (1+ count)))
        (set! i (1+ i)))
    count)


;--------------------------------------------------------------------------
;More implementations:


;;; Similar to this Haskell implementation:
;;;
;;;     --NOT using the sqrt optimization (for easier benchmarking):
;;;     findPrimes :: Int -> Int
;;;     findPrimes n = length ([i | i <- [2..n],
;;;                            foldr (\j a -> j == i || (rem i j /= 0 && a)) True [2..i]])
;;;
;;; in Haskell GHC/llvm this runs at C-like speed.
;;; In Guile and Chicken it runs VERY SLOW (because Scheme doesn't directly support lazy evaluation):
(define (findPrimes_Iota n)
  (length (filter (lambda (i)
                    (fold (lambda (j a) (and a (> (remainder i j) 0))) #t (iota (- i 2) 2)))
                  (iota (1- n) 2))))

;;; Using list comprehensions. Still VERY SLOW.
;;; It's slow because of folding over iota.
(define (findPrimes_ECfold n)
  (sum-ec (: i 2 (1+ n))
          (if (fold (lambda (j a) (and a (> (remainder i j) 0))) #t (iota (- i 2) 2)))
          1))

;;; Using eager comprehensions.
;;; Much faster, but still a bit SLOW.
(define (findPrimes_EC n)
  (define (isPrime i)
    (every?-ec (: j 2 i)
               (> (remainder i j) 0)))
  (sum-ec (: i 2 (1+ n))
          (if (isPrime i))
          1))

;;; Same as findPrimes_EC but in one line:
(define (findPrimes_EcOneLine n)
  (sum-ec (: i 2 (1+ n)) (if (every?-ec (: j 2 i) (> (remainder i j) 0))) 1))


;;; NAIVE implementation, VERY SLOW.
;;; Uses recursion, but it's not "tail call recursion"
;;; SUPER SLOW. Crashes at n=11000 or so with Guile.
(define (findPrimes_SlowNaiveRecursion n)
  (define (isPrime i j)
    (if (< j 2)
        1
        (if (= (remainder i j) 0)
            0
            (isPrime i (- j 1)))))

  (define (countPrimes n i)
    (if (>= i 2)
        (+ (countPrimes n (- i 1)) (isPrime i (1- i)))
        0))

  (countPrimes n n))


;;; Using (let) loops:
;;; let form has this form:
;;;      (let name ((var1 init1) (var2 init2))  body... )
;;; It can call itself inside the body.
;;; FAST.
(define (findPrimes_Let1 n)
  ;; Using (or) and (and) instead of (if),
  ;; and (define) instead of (lambda) or (let):
  (define (isPrime i)
    (define (isPrimeRec j)
      (or (>= j i)
          (and (> (remainder i j) 0)
               (isPrimeRec (+ j 1)))))
    (and (> i 1)
         (isPrimeRec 2)))

  (let loop ((i 2) (count 0))
    (if (<= i n)
        (loop (+ i 1)
              (+ count (if (isPrime i) 1 0)))
        count)))


;;; Using nested (let) loops without mutable variables
;;;
;;; let form has this form:
;;;      (let name ((var1 init1) (var2 init2))  body... )
;;; It can call itself inside the body.
;;; Same as FASTEST.
(define (findPrimes_Let2Pure n)
  (let loop ((i 2) (count 0))
    (if (<= i n)
        (loop (1+ i)
              (if (let loopJ ((j 2))
                    ;NOT using the sqrt optimization (for easier benchmarking):
                    (if (< j i)
                        (if (> (remainder i j) 0)
                            (loopJ (1+ j))
                            #f)
                        #t))
                  (1+ count)
                  count))
        count)))


;;; Using nested (let) loops and a mutable "count" variable.
;;;
;;; let form has this form:
;;;      (let name ((var1 init1) (var2 init2))  body... )
;;; It can call itself inside the body.
;;; FAST.
(define (findPrimes_Let2 n)
  (define count 0)
  (let loop ((i 2))
    (let loopJ ((j 2))
      (if (and (<= j i) (not (= (remainder i j) 0)))
          (loopJ (+ j 1))
          ;Else:
          (if (= i j) (set! count (1+ count)))))
    (if (< i n) (loop (+ i 1))))
  count)


;--------------------------------------------------------------------------


(define (main args)
  (define n 0)
  (define count 0)
  (define startTime 0)
  (define endTime 0)
  (define elapsed 0)

  (if (not (= (length args) 2))
      (begin
        (display "Quick and dirty single thread CPU benchmark - by JMC\n")
        (display "Usage: \n")
        (display "        Pass an argument up to which prime numbers will be searched with\n")
        (display "        an inefficient algorithm, useful to compare the single thread performance\n")
        (display "        of the CPU\n")
        (display "Example: \n")
        (format #t "        ~a 304500\n" (car args))
        (display "Notes: \n")
        (display "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n")
        (display "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n")
        (display "        Guile: it takes 132.561s using GNU Guile 2.0.9 64-bit.\n")
        (newline)
        (quit 1)))

  (set! n (string->number (cadr args)))
  (when (or (eq? n #f) (not (fixnum? n)) (< n 2))
    (format (current-error-port) "ERROR: Argument '~a' not valid.\n" (cadr args))
    (quit 1))

  (gc)
  (set! startTime (get-internal-real-time))

  (set! count (findPrimes n))
  ;(set! count (findPrimesEratosthenes n))
  ;(set! count (findPrimes_Do n))

  (set! endTime (get-internal-real-time))
  (set! elapsed (/ (- endTime startTime) internal-time-units-per-second))
  (format #t "Elapsed: ~6,3fs\n" elapsed)

  (format #t "~d prime numbers were found between 2 and ~d\n" count n))


(main (command-line))

