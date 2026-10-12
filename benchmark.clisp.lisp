#!/usr/bin/clisp -C

;;; Benchmark in Common Lisp for CLISP - by JMC
;;;
;;;
;;; Run:
;;;     ./benchmark.clisp.lisp 30450
;;;
;;; Compile and run:
;;;     clisp -C -x "(load \"benchmark.clisp.lisp\") (ext:saveinitmem \"benchmark\" :executable t :init-function 'mainStdAlone :quiet t)" -- 304  &&  ./benchmark 30450
;;;
;;; Use this to hide compilation messages:
;;;     clisp -C -q -x "(load \"benchmark.clisp.lisp\" :verbose nil) (ext:saveinitmem \"benchmark\" :executable t :init-function 'mainStdAlone :quiet t)" -- 304 > /dev/null  &&  ./benchmark 3045
;;;
;;; Compilation Notes:
;;;     -Manually comment the shebang before compiling.
;;;     -It might be necessary to comment the call to (main) or pass a "304" as last argument of
;;;      clisp so that (exit) is not called on load.
;;;     -Passing -C in the shebang gives about a 10x speedup as a script.
;;;     -Compiling is that same speed (using -C too), there is no more speedup after compiling to binary.
;;;     -See: file:///usr/share/doc/clisp/clisp/doc/impnotes.html for CLISP function documentation.
;;;
;;;
;;; Notes:
;;;     -CLISP was created in 1987 and is maintained as of 2018. It is an implementation of Common Lisp.
;;;      It is extremely portable, being written in C and Common Lisp. It is an interpreter and a
;;;      bytecode compiler. It can generate stand-alone executables.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 49 bits in
;;;      the 64-bit version of CLISP:
;;;             [1]> most-positive-fixnum
;;;             281474976710655
;;;             [2]> most-negative-fixnum
;;;             -281474976710656
;;;      If one adds 1 to most-positive-fixnum, it becomes a Bignum automatically.
;;;
;;;     -CLISP doesn't seem to accelerate arithmetic operations when fixnum declarations are used.
;;;
;;;     -The 32-bit version of CLISP doesn't run this benchmark any faster.
;;;
;;;     -See benchmark.sbcl.lisp for more notes about Common Lisp.
;;;


;;; Not always necessary for speedup:
;;; (Doesn't improve this benchmark in CLISP):
;;;     (declaim (optimize (speed 3) (debug 0) (safety 0)))


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
(defun findPrimes (n)
  (let ((count 0))
    (loop for i from 2 to n
          do (if (loop for j from 2 below i   ; NOT using the sqrt optimization (for easier benchmarking).
                       never (= 0 (rem i j)))
                 (incf count)))
    count))


;(disassemble 'findPrimes)


;;; In CLISP, fixnum declarations don't seem to change performance.
;;; This isn't faster than findPrimes, but shows where to put type declarations in loops and let forms:
(defun findPrimes_MoreDeclares (n)
  (declare (optimize (safety 0)))
  (declare (fixnum n)) ;(declare (type (signed-byte 30) n))
  (let ((count 0)) (declare (fixnum count))
    (loop for i fixnum from 2 to n
          do (if (loop for j fixnum from 2 below i   ; NOT using the sqrt optimization (for easier benchmarking).
                       do (when (= 0 (rem i j))
                            (return nil))
                       finally (return t))
                 (incf count)))
    count))


(defun findPrimes_Let (n)
  (labels ((isPrime (i j)
             (if (< j i)
                 (if (= 0 (rem i j))
                     nil
                     (isPrime i (+ j 1)))
                 t))
           (countPrimes (a i)
             (if (<= i n)
                 (countPrimes (if (isPrime i 2) (+ 1 a) a) (+ i 1))
                 a)))
    (countPrimes 0 2)))


;(disassemble 'findPrimes_Let)


;;; Using (do) loops:
;;; The do loop has this form:
;;;      (do ((var init increment)) ((untilTrue) (lastExpr)) )
;;; As fast as (loop).
(defun findPrimes_Do (n)
  (let ((count 0))
    (do ((i 2 (1+ i)))
        ((> i n))
      (do ((j 2 (1+ j)))
          ((or (>= j i) (= (rem i j) 0))
           (if (= i j)
               (incf count)))))
    count))


(defun main ()
  (let ((startTime 0)
        (endTime 0)
        (elapsed 0)
        (n 0)
        (count 0)
        (args ext:*args*))

    (when (/= 1 (length args))
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
      (write-line "        CLISP: it takes 172.028s using CLISP 2.49 with -C.")
      (terpri)
      (ext:exit 1))

    (setf n (ignore-errors (parse-integer (car args))))
    (when (or (null n) (< n 2))
      (format *error-output* "ERROR: Argument '~a' not valid.~%" (car args))
      (ext:exit 1))

    (ext:gc)
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
        (system::simple-interrupt-condition () (write-line " Interrupted!") (quit)))
    (abort () (write-line " Benchmark aborted")))
  ;; Quit. Don't fall through to the compiled interpreter:
  (quit))


(main)

