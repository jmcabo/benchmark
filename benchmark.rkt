#!/usr/bin/racket
#lang racket
;;; Benchmark in Scheme Lisp for Racket - by JMC
;;;
;;;
;;; Run:
;;;    ./benchmark.rkt 304500
;;; Compile and run:
;;;    raco exe benchmark.rkt  &&  ./benchmark 304500
;;;
;;; NOTE: Interpreter is the same speed as compiled (it's always JITed,
;;;       and compiling just embeds bytecode into an interpreter wrapper)
;;;       It's actually faster to just run with shebang (160ms startup
;;;       overhead vs 200ms as compiled). And the compiler is slow.
;;;
;;;
;;; Notes:
;;;     -Racket implements the Scheme Lisp language. Racket was called PLT Scheme in the beginning.
;;;      PLT Scheme was started around 1995. It was renamed to "Racket" in 2010. It is being
;;;      maintained and developed as of 2018.
;;;
;;;     -The Racket interpreter is actually a Just In Time compiler, so code always runs at native
;;;      code speeds.
;;;
;;;     -I think Racket is the biggest Scheme implementation. It supports GUI creation, web
;;;      development, database development and so on with its huge library/platform.
;;;      The news.ycombinator.com website (HN) runs on Arc which runs on Racket.
;;;
;;;     -The 'modulo' function is slower than 'remainder'. They differ with negative divisors.
;;;      'remainder' matches the result of Intel IDIV directly.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 63 bits in
;;;      the 64-bit version of Racket:
;;;             > (fixnum? (- (expt 2 62) 1))
;;;             #t
;;;             > (fixnum? (- (expt 2 63) 1))
;;;             #f
;;;      If one adds 1 to 2^62-1, it becomes a Bignum automatically.
;;;
;;;     -Parsing an integer can be tricky: the 'string->number' function accepts many types of numbers
;;;      such as: "3", "1+2i", "3.5", "3.", "3/2", "4/2", "#xFF", etc. It is important to filter out or
;;;      truncate inexact numbers such as "3." because they won't work with fixnum operations. Filtering
;;;      complex numbers is also necessary. This can be done with functions like 'truncate', 'integer?',
;;;      'inexact?' and 'fixnum?'.
;;;


;; For formatting floats with ~r:
(require racket/format)

;; For eager comprehensions (list-ec, sum-ec, every?-ec, etc.):
(require srfi/42)

;; For fixnum operations like fx+ or fxremainder:
(require racket/fixnum)


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
;;;
;;; Purely functional implementation using fixnum operations,
;;; with "let" and tail recursion, and without "set!"ing mutable variables.
;;; FASTEST in Racket.
(define (findPrimes n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (fx< j i)    ; NOT using the sqrt optimization (for easier benchmarking).
          (and (fx> (fxremainder i j) 0) (loop (fx+ j 1)))
          #t)))
  (let loop ((i 2) (count 0))
    (if (fx<= i n)
        (loop (fx+ i 1)
              (fx+ count (if (isPrime i) 1 0)))
        count)))


;;; Purely functional implementation,
;;; with "let" and tail recursion, and without "set!"ing mutable variables.
;;; FAST but fixnum version is fastest.
(define (findPrimes_Let n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (< j i)
          (and (> (remainder i j) 0) (loop (+ j 1)))
          #t)))
  (let loop ((i 2) (count 0))
    (if (<= i n)
        (loop (+ i 1)
              (+ count (if (isPrime i) 1 0)))
        count)))


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; FAST but slower in racket than let loops.
(define (findPrimes_Do n)
  (define count 0)
  (do ((i 2 (+ i 1)))
      ((> i n))
    (do ((j 2 (+ j 1)))
      ((or (>= j i)
           (= (remainder i j) 0))
       (when (= i j)
             (set! count (+ count 1))))))
  count)


;;; Using Racket's "for" loops:
;;; FAST but slower in racket than let loops.
(define (findPrimes_For n)
  (for/sum ([i (in-range 2 (add1 n))])
    (if (for/and ((j (in-range 2 i)))
          (> (remainder i j) 0))
        1
        0)))


;;; Using eager comprehensions.
;;; FAST but it's the slowest in this file.
(define (findPrimes_EC n)
  (define (isPrime i)
    (every?-ec (: j 2 i)
               (> (remainder i j) 0)))
  (sum-ec (: i 2 (add1 n))
          (if (isPrime i))
          1))


(define (main)
  (define args (current-command-line-arguments))
  (define n 0)
  (define count 0)
  (define startTime 0)
  (define endTime 0)
  (define elapsed 0)

  (when (not (= (vector-length args) 1))
    (display "Quick and dirty single thread CPU benchmark - by JMC\n")
    (display "Usage: \n")
    (display "        Pass an argument up to which prime numbers will be searched with\n")
    (display "        an inefficient algorithm, useful to compare the single thread performance\n")
    (display "        of the CPU\n")
    (display "Example: \n")
    (display (string-append "        " (path->string (find-system-path 'run-file)) " 304500\n"))
    (display "Notes: \n")
    (display "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n")
    (display "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n")
    (display "        Racket-32bits: it takes 16.183s using Racket 6.11.\n")
    (display "        Racket: it takes 38.733s using Racket 6.11.\n")
    (newline)
    (exit 1))

  (set! n (string->number (vector-ref args 0)))
  (when (or (eq? n #f) (not (fixnum? n)) (< n 2))
    (displayln (format "ERROR: Argument '~a' not valid." (vector-ref args 0)) (current-error-port))
    (exit 1))

  (collect-garbage)
  (set! startTime (current-milliseconds))

  (set! count (findPrimes n))
  ;(set! count (findPrimes_Let n))
  ;(set! count (findPrimes_For n))
  ;(set! count (findPrimes_Do n))
  ;(set! count (findPrimes_EC n))

  (set! endTime (current-milliseconds))
  (set! elapsed (/ (- endTime startTime) 1000.0))
  (printf "Elapsed: ~as\n" (~r elapsed #:min-width 6 #:precision '(= 3)))

  (printf "~a prime numbers were found between 2 and ~a\n" count n))


(main)

