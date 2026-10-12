#!/usr/bin/racket
#lang typed/racket
;;; Benchmark in Scheme Lisp for Typed Racket - by JMC
;;;
;;;
;;; Run:
;;;    ./benchmark.typed.rkt 304500
;;; Compile and run:
;;;    raco exe -o benchmark benchmark.typed.rkt  &&  ./benchmark 304500
;;;
;;; NOTE: Interpreter is the same speed as compiled (it's always JITed,
;;;       and compiling just embeds bytecode into an interpreter wrapper)
;;;       It's actually faster to just run with shebang (160ms startup
;;;       overhead vs 200ms as compiled). And the compiler is slow.
;;;
;;;
;;; Notes:
;;;     -Typed Racket is a statically typed dialect of Racket.
;;;
;;;     -See benchmark.rkt for more notes on Racket.
;;;


;; For formatting floats with ~r:
(require racket/format)

;; For fixnum operations like fx+ or fxremainder:
(require racket/fixnum)


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
;;;
;;; Purely functional implementation with fixnum operations,
;;; with "let" and tail recursion, and without "set!"ing mutable variables.
;;; FASTEST in Typed Racket.
(: findPrimes (Fixnum -> Fixnum))
(define (findPrimes n)
  (: isPrime (Fixnum -> Boolean))
  (define (isPrime i)
    (let loop ((j 2))
      (if (< j i)    ; NOT using the sqrt optimization (for easier benchmarking).
          (and (> (fxremainder i j) 0) (loop (fx+ j 1)))
          #t)))
  (let loop : Fixnum ([i : Fixnum 2] [count : Fixnum 0])
    (if (<= i n)
        (loop (fx+ i 1)
              (fx+ count (if (isPrime i) 1 0)))
        count)))


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; FAST but slower in racket than let loops.
(: findPrimes_Do (Fixnum -> Fixnum))
(define (findPrimes_Do n)
  (: count Fixnum)
  (define count 0)
  (do ((i : Fixnum 2 (fx+ i 1)))
      ((> i n))
    (do ((j : Fixnum 2 (fx+ j 1)))
      ((or (>= j i)
           (= (fxremainder i j) 0))
       (when (= i j)
             (set! count (fx+ count 1))))))
  count)


;;; Using Racket's "for" loops:
;;; FAST but slower in racket than let loops and DO loops.
(: findPrimes_For (Fixnum -> Integer))
(define (findPrimes_For n)
  (for/sum ([i (in-range 2 (add1 n))])
    (if (for/and : Boolean ((j (in-range 2 i)))
          (> (fxremainder i j) 0))
        1
        0)))


(define (main)
  (define args (current-command-line-arguments))
  (: nparse Any)
  (define nparse 0)
  (define nstr "")
  (: n Fixnum)
  (define n 0)
  (define count 0)
  (define startTime 0)
  (define endTime 0)
  (define elapsed (ann 0.0 Real))

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
    (display "        TypedRacket-32bits: it takes 15.781s using Racket 6.11.\n")
    (display "        TypedRacket: it takes 38.714s using Racket 6.11.\n")
    (newline)
    (exit 1))

  (set! nstr (vector-ref args 0))
  (set! nparse (string->number nstr))
  (when (or (eq? nparse #f) (not (fixnum? nparse)) (< (cast nparse Fixnum) 2))
    (displayln (format "ERROR: Argument '~a' not valid." (vector-ref args 0)) (current-error-port))
    (exit 1))
  (set! n (cast nparse Fixnum))

  (collect-garbage)
  (set! startTime (current-milliseconds))

  (set! count (findPrimes n))
  ;(set! count (findPrimes_Do n))
  ;(set! count (findPrimes_For n))

  (set! endTime (current-milliseconds))
  (set! elapsed (/ (- endTime startTime) 1000.0))
  (printf "Elapsed: ~as\n" (~r elapsed #:min-width 6 #:precision '(= 3)))

  (printf "~a prime numbers were found between 2 and ~a\n" count n))


(main)

