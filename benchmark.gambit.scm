#!/usr/bin/gsi-script
;;; Benchmark in Scheme Lisp for Gambit-C - by JMC
;;;
;;;
;;; NOTE: Don't benchmark using the interpreter, Use the compiler instead!!!
;;;
;;; Compile and run (FOR Gambit 4.8.8-3 / Ubuntu 18.04 64-bit):
;;;         gsc -link benchmark.gambit.scm  &&  gcc -O2 -o benchmark benchmark.gambit*.c -L/usr/lib/x86_64-linux-gnu/gambit4 -lgambit  &&  ./benchmark 304500
;;; For 32-bit:
;;;         gsc -link benchmark.gambit.scm  &&  gcc -O2 -o benchmark benchmark.gambit*.c -L/usr/lib/i386-linux-gnu/gambit4 -lgambit  &&  ./benchmark 304500
;;; Note: In Kubuntu/Ubuntu 18.04, Gambit renamed libgambc to libgambit (-lgambc to -lgambit),
;;; and they forgot to add the "libgambit.so" symlink (it is in a "gambit4" subdir), that is
;;; why I specify the path.
;;;
;;; Compile and run (FOR Gambit 4.2.8):
;;;         gsc -link benchmark.gambit.scm  &&  gcc -O2 -o benchmark benchmark.gambit*.c -lgambc  &&  ./benchmark 304500
;;; Some more -l library arguments may be required:
;;;         gsc -link benchmark.gambit.scm  &&  gcc -O2 -o benchmark benchmark.gambit*.c -lgambc -lm -ldl -lutil  &&  ./benchmark 304500
;;;
;;;
;;; Notes:
;;;     -Gambit-C implements the Scheme Lisp language. Gambit-C was first released in 1994 and it is
;;;      still being maintained and developed as of 2018. Development for Gambit, before Gambit-C,
;;;      started around 1988.
;;;
;;;     -As opposed to GNU Guile, Gambit-C doesn't come with pre-installed SRFI modules.
;;;      But Gambit it is much faster than Guile though. The website of the SLIB library shows
;;;      that it supports Gambit-C.
;;;
;;;     -The 'modulo' function is slower than 'remainder'. They differ with negative divisors.
;;;      'remainder' matches the result of Intel IDIV directly.
;;;
;;;     -The 'fxwrap+' operation is faster than 'fx+'. Instead of checking for overflow, in Gambit-C,
;;;      'fxwrap+' just wraps to negative if it overflows the greatest fixnum.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 62 bits in
;;;      the 64-bit version of Gambit-C:
;;;             > (fixnum? (- (expt 2 61) 1))
;;;             #t
;;;             > (fixnum? (- (expt 2 62) 1))
;;;             #f
;;;      If one adds 1 to 2^61-1, it becomes a Bignum automatically.
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


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
;;;
;;; Using (do) loops and fixnum operations:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; FASTEST in Gambit-C.
(define (findPrimes n)
  (define count 0)
  (do ((i 2 (fxwrap+ i 1)))
      ((fx> i n))
    (do ((j 2 (fxwrap+ j 1)))
      ((or (fx>= j i)
           (fx= (fxremainder i j) 0))
       (if (fx= i j)
           (set! count (fxwrap+ count 1))))))
  count)


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; FAST but not as fast as the fixnum operations 'findPrimes' version.
(define (findPrimes_Do n)
  (define count 0)
  (do ((i 2 (+ i 1)))
      ((> i n))
    (do ((j 2 (+ j 1)))
      ((or (>= j i)
           (= (remainder i j) 0))
       (if (= i j)
           (set! count (+ count 1))))))
  count)


;;; Purely functional implementation, using fixnum operations,
;;; with "let" and tail recursion, and without "set!"ing mutable variables.
;;; FAST but not as fast as the DO loops version.
(define (findPrimes_LetFixnum n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (fx< j i)
          (and (fx> (fxremainder i j) 0) (loop (fxwrap+ j 1)))
          #t)))
  (let loop ((i 2) (count 0))
    (if (fx<= i n)
        (loop (fxwrap+ i 1)
              (fxwrap+ count (if (isPrime i) 1 0)))
        count)))


;;; Purely functional implementation,
;;; with "let" and tail recursion, and without "set!"ing mutable variables.
;;; FAST but not as fast as the DO loops version or the fixnum operations version.
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


(define (main . mainArgs)
  (define args (command-line))
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
        (print "        " (path-strip-directory (car args)) " 304500\n")
        (display "Notes: \n")
        (display "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n")
        (display "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n")
        (display "        Gambit-C-32bits: it takes 22.966s Gambit-C 4.8.8 and GCC 7.3.0.\n")
        (display "        Gambit-C: it takes 44.373s using Gambit-C 4.8.8 and GCC 7.3.0.\n")
        (newline)
        (exit 1)))

  (set! n (string->number (cadr args)))
  (if (or (eq? n #f) (not (fixnum? n)) (< n 2))
      (begin
        (println port:(current-error-port) "ERROR: Argument '" (cadr args) "' not valid.")
        (exit 1)))

  (##gc)
  (set! startTime (current-time))

  (set! count (findPrimes n))
  ;(set! count (findPrimes_Do n))
  ;(set! count (findPrimes_LetFixnum n))
  ;(set! count (findPrimes_Let n))

  (set! endTime (current-time))
  (set! elapsed (- (time->seconds endTime) (time->seconds startTime)))
  (println "Elapsed: " (padLeft (floatToFixed elapsed 3) 6) "s")

  (println count " prime numbers were found between 2 and " n))


