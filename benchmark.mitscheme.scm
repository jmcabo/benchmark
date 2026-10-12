#|
#Run with interpreter (10x slower):
exec /usr/bin/mit-scheme --load "$0"
|#

;;; Benchmark in Scheme Lisp for MIT Scheme - by JMC
;;;
;;;
;;; Compile and run:
;;;         echo '(cf "benchmark.mitscheme.scm")' | mit-scheme  &&  echo 304500 | mit-scheme --load benchmark.mitscheme.com
;;; Notes:
;;;     -To re-run inside the interpreter, execute:
;;;         (main)
;;;     -The "cf" command compiles the .scm and generates three files: .bci .bin and .com.
;;;     -To load the compiled file, use the .com filename. If you load the .scm file, it will
;;;      go at interpretation speed (10x slow)
;;;
;;; Compile:
;;;         mit-scheme --eval '(cf "benchmark.mitscheme.scm")'
;;; that generates a .com file.
;;; It also leaves the interpreter running. To not run the interpreter after compiling, do it with echo:
;;;         echo '(cf "benchmark.mitscheme.scm")' | mit-scheme
;;;
;;; Run:
;;;         mit-scheme --load benchmark.mitscheme.com
;;; or:
;;;         echo 304500 | mit-scheme --load benchmark.mitscheme.com
;;; notice the extension .com vs .scm.
;;;
;;; Run interpreted (10x slower than compiled code):
;;;         mit-scheme --load benchmark.mitscheme.scm
;;; or:
;;;         echo 304500 | mit-scheme --load benchmark.mitscheme.scm
;;;
;;;
;;; Notes:
;;;     -MIT Scheme is one of the oldest Scheme lisps still working today. A changelog file I found
;;;      goes as far as 1986, but I couldn't find a precise date of creation for MIT Scheme anywhere
;;;      else (it could be older than the changelog).
;;;
;;;     -Use rlwrap to have history and command line editing inside mit-scheme like this:
;;;             rlwrap mit-scheme
;;;
;;;     -CTRL+D can be used to exit the interpreter.
;;;
;;;     -The 'modulo' function is slower than 'remainder'. They differ with negative divisors.
;;;      'remainder' matches the result of Intel IDIV directly.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 58 bits in
;;;      the 64-bit version of MIT Scheme:
;;;             1 ]=> (fixnum? (- (expt 2 57) 1))
;;;             ;Value: #t
;;;             1 ]=> (fixnum? (- (expt 2 58) 1))
;;;             ;Value: #f
;;;      If one adds 1 to 2^57-1, it becomes a Bignum automatically.
;;;
;;;     -Parsing an integer can be tricky: the 'string->number' function accepts many types of numbers
;;;      such as: "3", "1+2i", "3.5", "3.", "3/2", "4/2", "#xFF", etc. It is important to filter out or
;;;      truncate inexact numbers such as "3." because they won't work with fixnum operations. Filtering
;;;      complex numbers is also necessary. This can be done with functions like 'truncate', 'integer?',
;;;      'inexact?' and 'fixnum?'.
;;;
;;;
;;; Limitations:
;;;     -There is no way to turn off the banner that is printed when mit-scheme starts.
;;;      There is no quiet -q switch.
;;;
;;;     -MIT Scheme also always prints something even if no value was returned by the evaluated
;;;      expression. The output of the program is mixed with the output of MIT Scheme, it's not clean.
;;;      So it is not ideal for creating scripts.
;;;
;;;     -No easy way to parse command line arguments. MIT Scheme does not forward command line
;;;      arguments to the scheme code unless a "world image" is generated and a hook for a specific
;;;      keyword option is registered, like "-abc" (see docs on set-command-line-parser).
;;;      That is why I have to request the user interactively for a numeric argument.
;;;
;;;     -No built-in way of formatting floats with a fixed number of decimals.
;;;
;;;     -(format) is available by executing (load-option 'format) but it doesn't support formatting
;;;      floats with fixed decimals.
;;;
;;;     -(exit) and (quit) don't work the same as in other schemes. Exit will ask the user interactively
;;;      for a confirmation. Quit suspends the interpreter as if CTRL+Z was pressed. They are not
;;;      appropiate for normally exiting the program.
;;;
;;;     -Couldn't find a way of printing to STDERR with MIT Scheme.
;;;


;; For better compiler optimizations:
(declare (usual-integrations))


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
;;;
;;; Purely functional implementation,
;;; with "let" and tail recursion, and without "set!"ing mutable variables.
;;; Using fixnum operations for native speed.
;;; FASTEST in mit-scheme.
(define (findPrimes n)
  (define (isPrime i)
    (let loop ((j 2))
      (if (fix:< j i)   ;NOT using the sqrt optimization (for easier benchmarking):
          (and (fix:> (fix:remainder i j) 0) (loop (fix:1+ j)))
          #t)))
  (let loop ((i 2)
             (count 0))
    (if (fix:<= i n)
        (loop (fix:1+ i)
              (if (isPrime i) (fix:1+ count) count))
        count)))


;;; Same as before but using normal operations instead of fixnum.
(define (findPrimes_NoFixnum n)
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


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
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
;;; In MIT Scheme, Guile and Chicken it runs VERY SLOW (because Scheme doesn't directly support lazy evaluation):
(define (findPrimes_Iota n)
  (length (filter (lambda (i)
                    (fold (lambda (j a) (and a (> (remainder i j) 0))) #t (iota (- i 2) 2)))
                  (iota (- n 1) 2))))


;;; NAIVE implementation, VERY SLOW.
;;; Uses recursion, but it's not "tail call recursion"
;;; SUPER SLOW. Crashes at n=11000 or so with Guile. It didn't crash with Chicken or MIT Scheme, at least up to n=30450.
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
;;; FAST.
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
  (if #f  ; MIT-Scheme doesn't support NaN and Infinite too well:
          ;   (or (not (= n n)) (= +inf.0 n) (= -inf.0 n))  ; Skip the rest if NaN or infinite.
      (number->string n)
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
  (define nstr "")
  (define n 0)
  (define count 0)
  (define startTime 0)
  (define endTime 0)
  (define elapsed 0)

  (display "Quick and dirty single thread CPU benchmark - by JMC\n")
  (display "Usage: \n")
  (display "        Pass an argument up to which prime numbers will be searched with\n")
  (display "        an inefficient algorithm, useful to compare the single thread performance\n")
  (display "        of the CPU\n")
  (display "Example: \n")
  (display "        n=30450\n")
  (display "Notes: \n")
  (display "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n")
  (display "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n")
  (display "        MIT Scheme-32bits: it takes 14.431s using MIT Scheme 9.1.1 in 32 bits.\n")
  (display "        MIT Scheme: it takes 32.230s using MIT Scheme 9.1.1 in 64 bits.\n")
  (newline)

  (display "Search primes up to? ")
  (set! nstr (read-line))
  (newline)  ;When n is piped, it doesn't leave a newline.
  (set! n (string->number nstr))
  (if (or (eq? n #f) (not (fixnum? n)) (< n 2))
      (display (string-append "ERROR: Argument '" nstr "' not valid.\n"))
      ;Else
      (begin
        (gc-flip)
        (set! startTime (real-time-clock))

        (set! count (findPrimes n))
        ;(set! count (findPrimes_NoFixnum n))
        ;(set! count (findPrimes_Do n))
        ;(set! count (findPrimes_Iota n))
        ;(set! count (findPrimes_SlowNaiveRecursion n))
        ;(set! count (findPrimes_Let1 n))
        ;(set! count (findPrimes_Let2Pure n))
        ;(set! count (findPrimes_Let2 n))

        (set! endTime (real-time-clock))
        (set! elapsed (internal-time/ticks->seconds (- endTime startTime)))
        (display (string-append "Elapsed: " (padLeft (floatToFixed elapsed 3) 6) "s\n"))

        (display count) (display " prime numbers were found between 2 and ") (display n) (display "\n"))))


(main)

