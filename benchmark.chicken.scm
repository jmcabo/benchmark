#! /usr/bin/csi -script
;;; Benchmark in Chicken Scheme Lisp - by JMC
;;;
;;;
;;; NOTE: Don't benchmark using the interpreter, Use the compiler instead!!!
;;;
;;; Compile and run:
;;;     csc -O5 benchmark.chicken.scm  &&  ./benchmark.chicken 30450
;;; WARNING: if there is a file named "benchmark.c" in the same directory, csc deletes it when compiling.
;;;
;;; Interpret:
;;;     ./benchmark.chicken.scm 30450
;;; or:
;;;     csi -script benchmark.chicken.scm 30450
;;;
;;;
;;; Notes:
;;;     -Chicken Scheme was created in 2000. It is a Scheme implementation. It has both an interpreter
;;;      and compiler. Interpreted code is slower than compiled code. When compiling it outputs C code
;;;      which is then compiled to native code.
;;;
;;;     -Compared to the Guile file, there are less versions of findPrimes here,
;;;      because I didn't find SRFI-42 in Chicken Scheme, which means no do-ec, sum-ec, list-ec
;;;      (Eager Comprehensions). Also there is no (while) loop structure in Chicken Scheme.
;;;
;;;     -(format) works with the interpreter but doesn't work after compilation. I had to
;;;      replace usages of (format) with (printf) and (fprintf).
;;;
;;;     -The 'modulo' function is slower than 'remainder'. They differ with negative divisors.
;;;      'remainder' matches the result of Intel IDIV directly.
;;;
;;;     -Even though 'fxrem' is documented, it doesn't seem to work. Only 'fxmod' fixnum operation is
;;;      available with my version of Chicken Scheme.
;;;
;;;     -Fixnums are 63 bits wide. Max positive fixnum integer is 2^62-1 (4611686018427387903) in the
;;;      64-bit version of Chicken. Numbers are converted to float when exceeding that maximum.
;;;      Example:
;;;          most-positive-fixnum
;;;          --> 4611686018427387903
;;;          (fixnum? (+ most-positive-fixnum 1))
;;;          --> #f
;;;          (flonum? (+ most-positive-fixnum 1))
;;;          --> #t
;;;      There is an egg (extension package) available called "numbers" that adds bignum capability.
;;;
;;;     -Parsing an integer can be tricky: the 'string->number' function accepts many types of numbers
;;;      such as: "3", "1+2i", "3.5", "3.", "3/2", "4/2", "#xFF", etc. It is important to filter out or
;;;      truncate inexact numbers such as "3." because they won't work with fixnum operations. Filtering
;;;      complex numbers is also necessary. This can be done with functions like 'truncate', 'integer?',
;;;      'inexact?' and 'fixnum?'.
;;;
;;;
;;; Limitations:
;;;     -No built-in functions to format a float with fixed decimals and left space padding, so I
;;;      had to implement padLeft and floatToFixed.
;;;


;; For (iota) with initial value and step:
(use srfi-1)


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
;;;
;;; Purely functional implementation, using fixnum operations,
;;; with "let" and tail-recursion, and without "set!"ing mutable variables.
;;; FASTEST in Chicken.
(define (findPrimes n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (fx< j i)   ;NOT using the sqrt optimization (for easier benchmarking):
          (and (fx> (fxmod i j) 0) (loop (fx+ j 1)))
          #t)))
  (let loop ((i 2)
             (count 0))
    (if (fx<= i n)
        (loop (fx+ i 1)
              (if (isPrime i) (fx+ count 1) count))
        count)))


;;; Purely functional implementation, using type declarations,
;;; with "let" and tail-recursion, and without "set!"ing mutable variables.
;;; FAST in Chicken but still slower than the version with fixnum operations.
(define (findPrimes_LetTypes n)
  (define (isPrime i)
    (assume ((i fixnum))
      (let loop ((j 2))
        (assume ((j fixnum))
          (if (< j i)   ;NOT using the sqrt optimization (for easier benchmarking):
              (and (> (remainder i j) 0) (loop (+ j 1)))
              #t)))))
  (let loop ((i 2)
             (count 0))
    (assume ((i fixnum) (count fixnum))
      (if (<= i n)
          (loop (+ i 1)
                (if (isPrime i) (+ count 1) count))
          count))))


;;; Purely functional implementation,
;;; with "let" and tail-recursion, and without "set!"ing mutable variables.
;;; SLOWER than using fixnum operations in Chicken.
(define (findPrimes_Let n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (< j i)   ;NOT using the sqrt optimization (for easier benchmarking):
          (and (> (remainder i j) 0) (loop (+ j 1)))
          #t)))
  (let loop ((i 2)
             (count 0))
    (if (<= i n)
        (loop (+ i 1)
              (if (isPrime i) (+ count 1) count))
        count)))


;;; --------------------------------------------------------------------------
;;; Other implementations:


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; FAST (when compared to findPrimes_Let).
(define (findPrimes_Do n)
  (define count 0)
  (do ((i 2 (+ i 1)))
      ((> i n))
    (do ((j 2 (+ j 1)))
        ((or (>= j i) (= (remainder i j) 0))
      (if (= i j)
          (set! count (+ count 1))))))
  count)


;;; --------------------------------------------------------------------------
;;; More implementations:


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
                  (iota (- n 1) 2))))


;;; NAIVE implementation, VERY SLOW.
;;; Uses recursion, but it's not "tail call recursion"
;;; SUPER SLOW. Crashes at n=11000 or so with Guile. It didn't crash with Chicken, at least up to n=30450.
(define (findPrimes_SlowNaiveRecursion n)
  (define (isPrime i j)
    (if (< j 2)
        1
        (if (= (remainder i j) 0)
            0
            (isPrime i (- j 1)))))

  (define (countPrimes n i)
    (if (>= i 2)
        (+ (countPrimes n (- i 1)) (isPrime i (- i 1)))
        0))

  (countPrimes n n))


;;; Using (let) loops:
;;; let form has this form:
;;;      (let name ((var1 init1) (var2 init2))  body... )
;;; It can call itself inside the body.
;;; FAST (when compared to findPrimes_Let).
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
;;; Same as findPrimes_Let in speed.
(define (findPrimes_Let2Pure n)
  (let loop ((i 2) (count 0))
    (if (<= i n)
        (loop (+ i 1)
              (if (let loopJ ((j 2))
                    ;NOT using the sqrt optimization (for easier benchmarking):
                    (if (< j i)
                        (if (> (remainder i j) 0)
                            (loopJ (+ j 1))
                            #f)
                        #t))
                  (+ count 1)
                  count))
        count)))


;;; Using nested (let) loops and a mutable "count" variable.
;;;
;;; let form has this form:
;;;      (let name ((var1 init1) (var2 init2))  body... )
;;; It can call itself inside the body.
;;; FAST (when compared to findPrimes_Let).
(define (findPrimes_Let2 n)
  (define count 0)
  (let loop ((i 2))
    (let loopJ ((j 2))
      (if (and (<= j i) (not (= (remainder i j) 0)))
          (loopJ (+ j 1))
          ;Else:
          (if (= i j) (set! count (+ count 1)))))
    (if (< i n) (loop (+ i 1))))
  count)


;;;; --------------------------------------------------------------------------


;;; Add spaces to the left up to width. If the string is already bigger than width, return it unchanged.
(define (padLeft s width)
  (let ((spc (- width (string-length s))))
    (if (> spc 0)
        (string-append (make-string spc #\space) s)
        s)))


;;; Format a float to string as fixed point with the specified number of decimals - by JMC
;;;
;;; This is like calling in C:
;;;     sprintf(destStr, "%.3f", x)
;;; for (floatToFixed x 3)
;;;
;;; Examples:
;;;     (floatToFixed 1.234 0)      -->  "1"
;;;     (floatToFixed 1.234 2)      -->  "1.23"
;;;     (floatToFixed -1.995 2)     -->  "-2.00"
;;;     (floatToFixed 5 3)          -->  "5.000"
;;;     (floatToFixed -0.002 2)     -->  "-0.00"
;;;     (floatToFixed 1e30 2)       -->  "1000000000000000000000000000000.00"
;;;                                       (No weird approximation errors with this algorithm.)
;;;     (floatToFixed +nan.0 2)     -->  "+nan.0"
;;;
;;; Good algorithms for conversion of floats to string are found in:
;;;     "How to Print Floating-Point Numbers Accurately" - 1990 - Guy Steele and Jon White.
;;; but those might require an arbitrary precision integer library.
;;; There is also a famous, a very long, self contained, C implementation based on that paper in:
;;;     "dtoa.c" - http://www.netlib.org/fp/index.html
;;; dtoa.c uses its own implementation of arbitrary precision integers, all contained in a single file.
;;; Similar algorithms are already used by the language when returning a float in string form (just not
;;; with a specific fixed number of decimals).
;;;
;;;   The algorithm below prints the number to string, and parses the exponent (if the number was big or
;;; small enough to be returned with exponential notation with number->string). It applies the exponent and
;;; then it adds or removes fractional digits to complete the number of requested decimals (by filling
;;; with 0s or truncating and rounding).
;;;   This approach is more precise than the approach of trying to extract the digits one by one by
;;; shifting and truncating: Since there is no access to the binary representation of the float, and
;;; since these floats are base-2, small errors would be accumulated when multiplying by 10 and
;;; subtracting the integer part to shift and extract the fractional digits.
;;;   So it is better to rely on the algorithm inside (number->string) for converting to base-10 digits first,
;;; like the present algorithm does.
;;;
(define (floatToFixed x decimalPlaces)
  (if (or (not (= x x)) (= +inf.0 x) (= -inf.0 x))  ; Skip the rest if NaN or infinite.
      (number->string x)
      (let* ((decimalPlaces (max 0 (inexact->exact (floor decimalPlaces))))
             (str (number->string x))
             (f str)
             (exponent 0)
             (expPos 0)
             (isNegative #f)
             (integerDigits 0)
             (fractionalDigits 0)
             (pointPos 0)
             (firstDigitLeftOff 0))
        ;; Sub-function that returns the first position of a char, or #f if not found:
        (define (charIndexOf str c)
          (let loop ((pos 0))
            (if (>= pos (string-length str))
                #f
                (if (char=? (string-ref str pos) c)
                    pos
                    (loop (+ 1 pos))))))
        ;; Turn "3/4" into "0.75":
        (if (charIndexOf str #\/)
            (begin
              (set! str (number->string (exact->inexact x)))
              (set! f str)))
        ;; Parse exponent:
        (set! expPos (charIndexOf str #\e))
        (if expPos
            (begin
              (set! f (substring str 0 expPos))
              (set! exponent (substring str (+ 1 expPos) (string-length str)))
              (set! exponent (string->number exponent))))
        ;; Get negative sign and remove it:
        (if (char=? #\- (string-ref f 0))
            (begin
              (set! f (substring f 1 (string-length f)))
              (set! isNegative #t)))
        ;; Turn ".44" into "0.44" (needed at least for Gambit and MIT Scheme):
        (if (char=? #\. (string-ref f 0))
            (set! f (string-append "0" f)))
        ;; Turn "3." into "3" (needed at least for Gambit and MIT Scheme):
        (if (char=? #\. (string-ref f (- (string-length f) 1)))
            (set! f (substring f 0 (- (string-length f) 1))))
        ;; Get decimal point position and remove it:
        (set! integerDigits (string-length f))
        (set! fractionalDigits 0)
        (set! pointPos (charIndexOf f #\.))
        (if pointPos
            (begin
              (set! integerDigits pointPos)
              (set! f (string-append (substring f 0 pointPos) (substring f (+ 1 pointPos) (string-length f))))
              (set! fractionalDigits (- (string-length f) integerDigits))))
        ;; Shift decimal point (implicit in integerDigits and fractionalDigits) according to exponent,
        ;; add zero characters if necessary (when the decimal point ends up floating in the air beyond the digits):
        (set! fractionalDigits (- fractionalDigits exponent))
        (set! integerDigits (+ integerDigits exponent))
        (if (and (< exponent 0) (< integerDigits 1))
            (begin
              ;; Add zeros to the left, until the decimal point is reached, plus one integer digit zero:
              (set! f (string-append (make-string (- 1 integerDigits) #\0) f))
              (set! integerDigits 1))
            (if (and (> exponent 0) (< fractionalDigits 0))
                (begin
                  ;; Add zeros to the right, until the decimal point is reached:
                  (set! f (string-append f (make-string (- fractionalDigits) #\0)))
                  (set! fractionalDigits 0))))
        ;; Add 0's up to decimalPlaces if we have less than asked for:
        (if (< fractionalDigits decimalPlaces)
            (begin
              (set! f (string-append f (make-string (- decimalPlaces fractionalDigits) #\0)))
              (set! fractionalDigits decimalPlaces)))
        ;; Remove digits if we have more than asked for:
        (if (> fractionalDigits decimalPlaces)
            (begin
              (set! firstDigitLeftOff (string-ref f (+ integerDigits decimalPlaces)))
              (set! f (substring f 0 (+ integerDigits decimalPlaces)))
              (set! fractionalDigits decimalPlaces)
              ;; Propagate rounding if the first digit left off is greater than or equal to "5":
              (if (char>=? firstDigitLeftOff #\5)
                  (let loop ((pos (- (string-length f) 1)))
                    (if (= pos -1)
                        (begin
                          (set! f (string-append "1" f))   ; Ended with carry, prepend a 'one'.
                          (set! integerDigits (+ 1 integerDigits)))
                        (let ((newChar (integer->char (+ 1 (char->integer (string-ref f pos))))))  ; Add one to this digit.
                          (if (char<=? newChar #\9)
                              (string-set! f pos newChar)  ; No carry. Propagation ends here.
                              (begin
                                (string-set! f pos #\0)    ; If 9 then change to 0.
                                (loop (- pos 1))))))))))   ; Loop and keep propagating rounding
        ;; Add decimal point:
        (if (> decimalPlaces 0)
            (set! f (string-append (substring f 0 integerDigits) "." (substring f integerDigits (string-length f)))))
        ;; Add negative sign:
        (if isNegative
            (set! f (string-append "-" f)))
        f)))


(define (main)
  (define n 0)
  (define count 0)
  (define startTime 0)
  (define endTime 0)
  (define elapsed 0)
  (define args (command-line-arguments))

  (if (not (= (length args) 1))
      (begin
        (display "Quick and dirty single thread CPU benchmark - by JMC\n")
        (display "Usage: \n")
        (display "        Pass an argument up to which prime numbers will be searched with\n")
        (display "        an inefficient algorithm, useful to compare the single thread performance\n")
        (display "        of the CPU\n")
        (display "Example: \n")
        (printf "        ~a 304500\n" (program-name))
        (display "Notes: \n")
        (display "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n")
        (display "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n")
        (display "        Chicken-32bits: it takes 11.912s using Chicken 4.12.0 32-bit.\n")
        (display "        Chicken: it takes 30.910s using Chicken 4.12.0 64-bit.\n")
        (newline)
        (exit 1)))

  (set! n (string->number (car args)))
  (when (or (eq? n #f) (not (fixnum? n)) (< n 2))
    (fprintf (current-error-port) "ERROR: Argument '~a' not valid.\n" (car args))
    (exit 1))

  (gc)
  (set! startTime (current-milliseconds))

  (set! count (findPrimes n))
  ;(set! count (findPrimes_LetTypes n))
  ;(set! count (findPrimes_Let n))
  ;(set! count (findPrimes_Do n))
  ;(set! count (findPrimes_Iota n))
  ;(set! count (findPrimes_SlowNaiveRecursion n))
  ;(set! count (findPrimes_Let1 n))
  ;(set! count (findPrimes_Let2Pure n))
  ;(set! count (findPrimes_Let2 n))

  (set! endTime (current-milliseconds))
  (set! elapsed (/ (- endTime startTime) 1000.0))
  (printf "Elapsed: ~as\n" (padLeft (floatToFixed elapsed 3) 6))

  (printf "~a prime numbers were found between 2 and ~a\n" count n))


(main)

