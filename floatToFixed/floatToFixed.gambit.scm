#!/usr/bin/gsi-script
;;; floatToFixed testing file in Scheme Lisp for Gambit-C - by JMC


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


;;; DEPRECATED:
;;; Format a float to string as fixed point with the specified number of decimals - by JMC
;;;
;;; This is like calling in C:
;;;     sprintf(destStr, "%.3f", x)
;;; for (floatToFixed x 3)
;;;
;;; Examples:
;;;         (floatToFixed 1.234 0)      -->  "1"
;;;         (floatToFixed -1.995 2)     -->  "-2.00"
;;;         (floatToFixed 0.1 3)        -->  "0.100"
;;;         (floatToFixed 5 3)          -->  "5.000"
;;;         (floatToFixed 9.99999 2)    -->  "10.00"
;;;         (floatToFixed 1e20 2)       -->  "100000000000000000000.00"
;;;         (floatToFixed +nan.0 2)     -->  "+nan.0"
;;;
;;; Note: Beware of results with 16 digits or more (counting both the integer and fractional parts).
;;; The mantissa of a double precision floating point number is only 53 bits wide. That means that
;;; the mantissa is not guaranteed to represent more than 15 decimal digits, and digits printed
;;; after that could be an approximation or garbage. For example, run this in a linux prompt (or the
;;; equivalent in a C program):
;;;         $ printf "%f\n" 1e30
;;;         1000000000000000000024696061952.000000
;;; it shows garbage in the least significant digits. Also, because floating point is usually represented
;;; with binary digits instead of BCD decimal digits, there can be small errors of representation, evident
;;; when printing 16 digits or more (that is why I had to implement propagation of rounding of the last
;;; digit left off). Again this is common to all languages which use IEEE 754 floating point hardware:
;;;         $ printf "%.20f\n" 1.0002
;;;         1.00019999999999999998
;;;
;;; Note: To make it work with all numbers including the number 1.7e308 for instance, which has the biggest
;;; exponent one can use with double precision, I had to separate the integer part and the fractional
;;; part and process them separately. The trick of multiplying by 10^decimals wouldn't have worked
;;; and would have returned infinite +inf.0 when decimals > 0.
;;;   Another trick that didn't work was using number->string and then removing or adding fractional digits
;;; to complete the number of required decimals (by truncating or filling with 0s). It didn't work
;;; because number->string formats with exponential notation when the number is big or small enough.
;;; So I resorted to extracting the digits one by one by dividing by 10 and taking the remainder,
;;; which wasn't as straight forward since Scheme lacks functions equivalent to fmod() and modf() from C.
;;;
;;; BUGS:
;;;     (floatToFixed_DigitByDigit 12.0002 20)  -->  12.00019999999999953388
;;;                                       should be: 12.00020000000000000000
;;;     (floatToFixed_DigitByDigit 1e30 0)      -->  1000000000000000400000000000000
;;;                                       should be: 1000000000000000000000000000000
;;;     (floatToFixed_DigitByDigit 1.234e70 0)  -->  12339999999999990000000000000000000000000000000000000000000000000000000
;;;                                       should be: 12340000000000000000000000000000000000000000000000000000000000000000000
;;;                                       (the same with 1.234e308)
;;;
(define (floatToFixed_DigitByDigit n decimals)
  (if (or (not (= n n)) (= +inf.0 n) (= -inf.0 n))  ; Skip the rest if NaN or infinite.
      (number->string n)
      (let* ((isNeg (< n 0))
             (f (abs n))
             (intPart (floor f))
             (fracPart (- f intPart))
             (digitList '())
             (carry #f)
             (s ""))
        ;; Sub-function that extracts the least significant integer digit, but compensating
        ;; somehow for errors of missing precision and the lack of fmod() in scheme:
        (define (leastDigitSafe f)
          (let ((digit (floor (- f (* (floor (/ f 10.0)) 10.0)))))
            (if (or (> digit 10.0) (< digit 0.0))
                0
                digit)))
        ;; Truncate 'decimals' argument to non-negative integer:
        (set! decimals (max 0 (inexact->exact (floor decimals))))
        ;; Add digits of integral part:
        (set! digitList (let loop ((f intPart) (digits '()))
                          (if (= f 0.0)
                              ;; End of recursion, return the assembled list:
                              digits
                              ;; Append current digit and do a recursion:
                              (loop (floor (/ f 10.0))
                                    (cons (integer->char (+ 48 (inexact->exact (leastDigitSafe f))))
                                          digits)))))
        ;; Reverse to have least significant digits first:
        (set! digitList (reverse digitList))
        ;; If integer part is empty, add '0':
        (if (null? digitList)
            (set! digitList '(#\0)))
        ;; Add decimal dot if more than 0 decimals desired:
        (if (> decimals 0)
            (set! digitList (cons #\. digitList)))
        ;; Add digits of fractional part:
        (set! digitList (let loop ((f fracPart) (digits digitList) (count 0))
                          (if (or (= f 0.0) (>= count decimals))
                              ;; End of recursion (f is zero or no more decimals required):
                              (if (>= count decimals)
                                  ;; No more decimal digits required:
                                  (begin
                                    ;; Set carry if next digit would have been >= 5:
                                    (if (>= (inexact->exact (floor (* f 10.0))) 5)
                                        (set! carry #t))
                                    ;; Return digits:
                                    digits)
                                  ;; More decimals needed than present in the fractional part. Fill with zeros:
                                  (let addZeros ((digits digits) (i (- decimals count)))
                                    (if (= i 0)
                                        digits
                                        (addZeros (cons #\0 digits) (- i 1)))))
                              ;; Append current digit and do a recursion:
                              (loop (- (* f 10.0) (floor (* f 10.0)))
                                    (cons (integer->char (+ 48 (inexact->exact (floor (* f 10.0)))))
                                          digits)
                                    (+ count 1)))))
        ;; Propagate rounding of the fractional digit that was left off:
        (set! digitList (let loop ((digits digitList) (carry carry))
                          (cond
                           ((null? digits)  ; End of digits.
                            (if carry
                                '(#\1)  ; Carry propagated until the end: Insert a one as most significant digit.
                                '()))
                           ((not carry)  ; No more propagation, return rest of the digit list.
                            digits)
                           (else
                            (let* ((oldChar (car digits))
                                   (newChar (if (eq? oldChar #\.)  ; Skip the decimal dot.
                                                oldChar
                                                (if (eq? oldChar #\9)  ; If 9 then change to 0.
                                                    #\0
                                                    (integer->char (+ 1 (char->integer oldChar)))))))  ; Add one to this digit.
                              ;; Append newChar and do a recursion. Keep carry unless digit is not 9:
                              (cons newChar
                                    (loop (cdr digits)
                                          (or (eq? oldChar #\.) (eq? oldChar #\9)))))))))
        ;; Reverse to have most significant digits first:
        (set! digitList (reverse digitList))
        ;; Convert to string:
        (set! s (list->string digitList))
        ;; Add minus sign:
        (if (eq? isNeg #t)
            (set! s (string-append "-" s)))
        s)))


;;; DEPRECATED:
;;; This is almost equivalent to C's:
;;;     sprintf("%6.3f", n)
;;; for width=6 and decimals=3, example: (formatFloat n 6 3).
;;;
;;; Problems:
;;;     I implemented this function before implementing floatToFixed, which solves all problems.
;;;     This little function doesn't work for numbers that result in exponential notation
;;;     being returned from number->string (big or small numbers, like 1e30 or 1e-30).
;;;
;;; A different way, less portable, is to call an external 'printf' process:
;;;      ;Depends on /usr/bin/printf from 'coreutils':
;;;      (define numStr (number->string n))
;;;      (set! p (open-process (list path: "/usr/bin/printf" arguments: (list "%6.3fs" numStr))))
;;;      (set! numStr (read-all p))
;;;      (close-output-port p)
;;;
;;; BUGS:
;;;     (formatFloat 1.2e-7 0 8)    -->  1.2e-70000   (should be "0.00000012")
;;;     (formatFloat 1e30 0 0)      -->  1e30         (should be "1000000000000000000000000000000")
;;;     (formatFloat 3/4 0 3)       -->  3/4.000      (should be "0.750")
;;;     (formatFloat 1.234e30 0 0)  -->  1            (should be "1234000000000000000000000000000")
;;;     (formatFloat 1e308 0 1)     -->  ERROR!       (should be "1000[..308 zeros..]000.0")
;;;
(define (formatFloat n width decimals)
  (if (or (not (= n n)) (= +inf.0 n) (= -inf.0 n))  ; Skip the rest if NaN or infinite.
      (number->string n)
      (let* ((isNeg (< n 0))
             (decimals (max 0 (inexact->exact (floor decimals))))
             (decimals_factor (expt 10 (max 0 decimals)))
             (f (/ (round (* decimals_factor (abs n))) decimals_factor))
             (s (number->string f))  ; Convert to string using Scheme function.
             (a (string->list s))
             (dotRest (memq #\. a))
             (zeros 0)
             (spc 0))
        ;; Zeros to add:
        (if (not (eq? dotRest #f))
            (set! zeros (- decimals (- (length dotRest) 1)))
            (begin
              (set! s (string-append s "."))
              (set! a (string->list s))
              (set! dotRest (memq #\. a))
              (set! zeros decimals)))
        ;; Add missing leading "0" if it starts with a dot:
        (if (and (> (length a) 0) (eq? (car a) #\.))
            (set! s (string-append "0" s)))
        ;; Add trailing zeros up to 'decimals':
        (if (> zeros 0)
            (set! s (string-append s (make-string zeros #\0))))
        ;; If decimals is 0, remove the dot:
        (if (and (<= decimals 0) (not (eq? dotRest #f)) (>= (length dotRest) 1))
            (set! s (substring s 0 (- (string-length s) (length dotRest)))))
        ;; Re-add minus sign:
        (if (eq? isNeg #t)
            (set! s (string-append "-" s)))
        ;; Padding with spaces:
        (set! spc (- width (string-length s)))
        (if (> spc 0)
            (set! s (string-append (make-string spc #\space) s)))
        s)))


;;; Add spaces to the right up to width. If the string is already bigger than width, return it unchanged.
(define (padRight s width)
  (let ((spc (- width (string-length s))))
    (if (> spc 0)
        (string-append s (make-string spc #\space))
        s)))


(define (testFloatToFixed x decimalPlaces)
  (display (padRight (string-append (number->string x) " " (number->string decimalPlaces)) 10))
  (display (string-append "  -->  " (floatToFixed x decimalPlaces)))
  ;(display (string-append "  -->  " (floatToFixed_DigitByDigit x decimalPlaces)))
  ;(display (string-append "  -->  " (formatFloat x 0 decimalPlaces)))
  (newline))


(define (main . mainArgs)
  (testFloatToFixed 1.2 3.6)
  (testFloatToFixed 1.2 3)
  (testFloatToFixed 0.2 3)
  (testFloatToFixed 1.2e-7 3)
  (testFloatToFixed 1.2e-7 8)
  (testFloatToFixed 1.2e5 3)
  (testFloatToFixed 123 3)
  (testFloatToFixed -0.2 3)
  (testFloatToFixed -0.002 2)
  (testFloatToFixed 9.999 2)
  (testFloatToFixed +nan.0 2)
  (testFloatToFixed 12.0002 20)
  (testFloatToFixed 1e30 0)
  (testFloatToFixed 12.099 2)
  (testFloatToFixed -1.996 2)
  (testFloatToFixed 0.9 0)
  (testFloatToFixed 3/4 3))


