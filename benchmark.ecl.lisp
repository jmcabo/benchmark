#!/usr/bin/ecl -shell

;;; Benchmark in Common Lisp for ECL - by JMC
;;;
;;;
;;; Run (but slow, interpreted):
;;;     ./benchmark.ecl.lisp 30450
;;;
;;; Compile and run:
;;;     ecl -eval "(compile-file \"benchmark.ecl.lisp\" :system-p t)" -eval "(c:build-program \"benchmark\" :lisp-files '(\"benchmark.ecl.o\"))" -eval "(quit)"  &&  ./benchmark 304500
;;;
;;; Compilation Notes:
;;;     -libffi-dev must be installed.
;;;     -The interpreter is between 5x and 17x slower than compiled.
;;;      Calling (compile 'findPrimes) in the interpreter DOES make it as fast as compiled code,
;;;      but generates warnings when called in a completely compiled program.
;;;
;;;
;;; Notes:
;;;     -ECL (Embeddable Common Lisp) was created in 2005, and is maintained and developed as of 2018.
;;;      It is an implementation of Common Lisp. It has both an interpreter and compiler. The compiler
;;;      compiles to C and then to native code. Interpreted code is slower than compiled code in ECL.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 62 bits in
;;;      the 64-bit version of ECL:
;;;             > most-positive-fixnum
;;;             2305843009213693951
;;;             > most-negative-fixnum
;;;             -2305843009213693952
;;;      If one adds 1 to most-positive-fixnum, it becomes a Bignum automatically.
;;;
;;;     -See benchmark.sbcl.lisp for more notes about Common Lisp.
;;;
;;;
;;; Limitations:
;;;     -When compiling, ECL prints lots of info to STDOUT and there is no switch to turn that off.
;;;      When there is an error, it is printed to STDERR but it starts an interactive REPL instead
;;;      of terminating with an error.
;;;
;;;     -Running with the 'ecl -shell' shebang works (it uses the interpreter), but then the command
;;;      line needs to be filtered of the "ecl" and "-shell" elements. The speed when run this way
;;;      is slower than compiled native code.
;;;


;;; Not always necessary for speedup:
;;;     (declaim (optimize (speed 3) (debug 0) (safety 0)))

;(use-package 'ext)       ; ECL's "ext" package for ext:exit, ext:command-args, ext:getenv.


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
(defun findPrimes (n)
  ;(declare (fixnum n))  ; Just "fixnum n" gives the fastest speed in SBCL, but ECL needs i and j as fixnums.
  (let ((count 0))
    (loop for i fixnum from 2 to n
          do (if (loop for j fixnum from 2 below i   ; NOT using the sqrt optimization (for easier benchmarking).
                       never (= 0 (rem i j)))
                 (incf count)))
    count))


;(disassemble 'findPrimes)


;;; This isn't faster than findPrimes, but shows where to put more type declarations in loops and let forms:
(defun findPrimes_MoreDeclares (n)
  (declare (optimize (safety 0)))
  (declare (fixnum n)) ;(declare (type (signed-byte 30) n))
  (let ((count 0)) (declare (fixnum count))
    (loop for i fixnum from 2 to n
          do (if (loop for j fixnum from 2 below i
                       do (when (= 0 (rem i j))
                            (return nil))
                       finally (return t))
                 (incf count)))
    count))


(defun findPrimes_Let (n)
  (declare (optimize (safety 0)))    ; Needed with ECL.
  (labels ((isPrime (i j)
             (declare (fixnum i j))  ; Both i j fixnums and (safety 0) are needed with ECL.
             (if (< j i)
                 (if (= 0 (rem i j))
                     nil
                     (isPrime i (+ j 1)))
                 t))
           (countPrimes (count i)
             (if (<= i n)
                 (countPrimes (if (isPrime i 2) (+ 1 count) count) (+ i 1))
                 count)))
    (countPrimes 0 2)))


;;; This isn't faster than findPrimes_Let, but shows where to put more type declarations in loops and let forms:
(defun findPrimes_LetMoreDeclares (n)
  (declare (optimize (safety 0)))
  (declare (fixnum n))
  (labels ((isPrime (i j)
             (declare (fixnum i j))  ; Just declaring i and j as fixnums gives the fastest speed.
             (if (< j i)
                 (if (= 0 (rem i j))
                     nil
                     (isPrime i (+ j 1)))
                 t))
           (countPrimes (count i)
             (declare (fixnum count i))
             (if (<= i n)
                 (countPrimes (if (isPrime i 2) (+ 1 count) count) (+ i 1))
                 count)))
    (countPrimes 0 2)))


;(disassemble 'findPrimes_Let)


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; As fast as (loop).
(defun findPrimes_Do (n)
  (declare (optimize (safety 0)))
  (declare (fixnum n))
  (let ((count 0))
    (declare (fixnum count))
    (do ((i 2 (1+ i)))
        ((> i n))
      (declare (fixnum i))
      (do ((j 2 (1+ j)))
          ((or (>= j i) (= (rem i j) 0))
           (if (= i j)
               (incf count)))
        (declare (fixnum j))))
    count))


(defun main ()
  (let ((startTime 0)
        (endTime 0)
        (elapsed 0)
        (n 0)
        (count 0)
        (args (ext:command-args)))

    ; Filter "/usr/bin/ecl" and "-shell" arguments (not present when compiled):
    (setf args (loop for x in args
                     when (not (or (search "-shell" x)
                                   (and (>= (length x) 3) (equal "ecl" (subseq x (- (length x) 3))))))  ; Ends with "ecl"
                     collect x))

    (when (/= 2 (length args))
      (write-line "Quick and dirty single thread CPU benchmark - by JMC")
      (write-line "Usage: ")
      (write-line "        Pass an argument up to which prime numbers will be searched with")
      (write-line "        an inefficient algorithm, useful to compare the single thread performance")
      (write-line "        of the CPU")
      (write-line "Example: ")
      (write-line (concatenate 'string "        " (ext:getenv "_") " 304500"))
      (write-line "Notes: ")
      (write-line "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
      (write-line "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
      (write-line "        ECL-32bits: it takes 8.917s using ECL 16.1.2 32-bits.")
      (write-line "        ECL: it takes 28.573s using ECL 13.5.1 64-bits.")
      (terpri)
      (ext:exit 1))

    (setf n (ignore-errors (parse-integer (cadr args))))
    (when (or (null n) (< n 2))
      (format *error-output* "ERROR: Argument '~a' not valid.~%" (cadr args))
      (ext:exit 1))

    (gc :full t)
    ;(compile 'findPrimes)
    (setf startTime (get-internal-real-time))

    (setf count (findPrimes n))

    (setf endTime (get-internal-real-time))
    (setf elapsed (/ (- endTime startTime) internal-time-units-per-second))
    (format t "Elapsed: ~6,3fs~%" elapsed)

    (princ count) (princ " prime numbers were found between 2 and ") (princ n) (terpri)))


;;; Alternative main that provides an Abort restart, and a CTRL+C interrupt handler:
(defun mainStdAlone ()
  (restart-case
      (handler-case
          (main)
        (ext:interactive-interrupt () (write-line " Interrupted!") (quit)))
    (abort () (write-line " Benchmark aborted")))
  ;; Quit. Don't fall through to the compiled interpreter:
  (quit))


(mainStdAlone)

