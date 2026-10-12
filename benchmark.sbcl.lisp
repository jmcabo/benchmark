#!/usr/bin/sbcl --script

;;; Benchmark in Common Lisp for SBCL - by JMC
;;;
;;;
;;; Run:
;;;     ./benchmark.sbcl.lisp 304500
;;;
;;; Compile and run:
;;;     sbcl --eval "(defvar *is-compiling* t)" \
;;;          --eval "(load \"benchmark.sbcl.lisp\")" \
;;;          --eval "(save-lisp-and-die \"benchmark\" :toplevel 'mainStdAlone :executable t :compression -1)"  &&  ./benchmark 304500
;;;
;;; The same in one line for easy copy and paste:
;;;     sbcl --eval "(defvar *is-compiling* t)" --eval "(load \"benchmark.sbcl.lisp\")" --eval "(save-lisp-and-die \"benchmark\" :toplevel 'mainStdAlone :executable t :compression -1)"  &&  ./benchmark 304500
;;;
;;; Compilation Notes:
;;;     -My defvar *is-compiling* is so that (main) doesn't run while the file is being loaded for
;;;      compilation.
;;;     -The function "mainStdAlone", provides an abort restart. Otherwise, one cannot exit the debugger
;;;      with CTRL-D when compiled standalone.
;;;     -Compression level -1 is fast with good results. Otherwise, "9" is better but makes
;;;      compilation slow.
;;;     -Load time without compression is <5ms. With compression it's about ~100ms in my CPU.
;;;
;;;
;;; Notes:
;;;     -SBCL Lisp was created in 1999 as a fork of CMUCL Lisp, and is maintained and developed as of 2019.
;;;      It is an implementation of Common Lisp. I think SBCL is the most mature one. It compiles directly
;;;      to native code, without depending on any C backend or LLVM like other compilers might do.
;;;      The compiler itself is written in compatible Common Lisp.
;;;
;;;     -Code run through the interpreter runs at compiled speeds. It has on the fly incremental compilation.
;;;
;;;     -I like about CommonLisp that it can approach C-like speeds while being a very high level language.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 63 bits in
;;;      the 64-bit version of SBCL:
;;;             * most-positive-fixnum
;;;             4611686018427387903
;;;             * most-negative-fixnum
;;;             -4611686018427387904
;;;      If one adds 1 to most-positive-fixnum, it becomes a Bignum automatically.
;;;
;;;     -Floats can be single or double precision. To specify a double precision literal, use the exponential
;;;      notation with the letters "l" or "d". Examples: 1d0, 1.0l0, 1.0d308, 1l308:
;;;             * (type-of 1.0)
;;;             SINGLE-FLOAT
;;;             * (type-of 1.0d0)
;;;             DOUBLE-FLOAT
;;;
;;;     -In CommonLisp "True" and "False" are "t" and "nil" respectively. This is different from Scheme.
;;;      NIL is also the empty list.
;;;             * (> 2 1)
;;;             T
;;;             * (> 1 1)
;;;             NIL
;;;             * (length nil)
;;;             0
;;;
;;;     -CTRL+D can be used to exit the interpreter.
;;;
;;;     -Ideally use 2 spaces for indentation. Formatting style for Lisp code:
;;;             "Lisp Style Tips for the Beginner - Heinrich Taube"
;;;             http://people.ace.ed.ac.uk/staff/medward2/class/moz/cm/doc/contrib/lispstyle.html
;;;
;;;
;;; Common Lisp tips:
;;;     -rlwrap sbcl   Starts sbcl with line editing, history and autocompletion.
;;;     -(apropos "string")  Lists all function names containing "string", such as "string-downcase".
;;;     -(apropos "string" :cl)  Lists only in package :cl
;;;     -(describe 'mapcar)  Shows function documentation.
;;;     -(documentation 'mapcar 'function)
;;;     -(inspect 'mapcar)
;;;     -This is useful to further filter apropos, case-insensitive:
;;;          (defun filter-string (str list) (remove-if-not (lambda (x) (search str (write-to-string x) :test #'char-equal)) list))
;;;      example 1:
;;;          (filter-string "prin" (apropos-list "line" :cl))
;;;      example 2, print results in separate lines:
;;;          (format t "~{~a~%~}" (filter-string "prin" (apropos-list "line" :cl)))
;;;     -Apropos that matches all string arguments:
;;;          (defun ap (arg1 &rest args)
;;;            (let ((r))
;;;              (setf r (mapcar 'write-to-string (apropos-list arg1)))
;;;              (loop for arg in args
;;;                    do (setf r (remove-if-not (lambda (x) (search arg x :test 'char-equal)) r)))
;;;              (format t "~{~a~%~}" r)))
;;;      example:
;;;           (ap "wri" "line")
;;;     -Convert a vector to list:
;;;          (coerce myVector 'list)
;;;      or:
;;;          (map 'list #'identity myVector)
;;;      or:
;;;          (loop for x across #(1 2 3) collect x)
;;;     -Sort a list:
;;;          (setf a (sort a '<))             ; Sort returns a good list, but destroys the original for speed.
;;;          (setf a (sort a 'string-lessp))  ; Case insensitive
;;;          (setf a (sort a 'string<))       ; Case sensitive


;;; Not necessary for speedup:
;;; (but "(declare (fixnum n))" in findPrime DOES make a difference):
;;;     (declaim (optimize (speed 3) (debug 0) (safety 0)))


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
(defun findPrimes (n)
  (declare (fixnum n))  ; Just "fixnum n" gives the fastest speed.
  (let ((count 0))
    (loop for i from 2 to n
          do (if (loop for j from 2 below i   ; NOT using the sqrt optimization (for easier benchmarking).
                       never (= 0 (rem i j)))
                 (incf count)))
    count))


;(disassemble 'findPrimes)


;;; This isn't faster than findPrimes, but shows where to put more type declarations in loops and let forms:
(defun findPrimes_MoreDeclares (n)
  (declare (optimize (safety 0)))
  ;(declare ((signed-byte 30) n))
  (declare (fixnum n))
  (let ((count 0))
    (declare (fixnum count))
    (loop for i fixnum from 2 to n
          do (if (loop for j fixnum from 2 below i
                       do (when (= 0 (rem i j))
                            (return nil))
                       finally (return t))
                 (incf count)))
    count))


;;; As fast as (loop), but without mutation, and tail-recursive:
(defun findPrimes_Let (n)
  (labels ((isPrime (i j)
             (declare (fixnum i j))  ; Just declaring i and j as fixnums gives the fastest speed.
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
  (declare (fixnum n))
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
        (count 0))

    (when (/= 2 (length *posix-argv*))
      (write-line "Quick and dirty single thread CPU benchmark - by JMC")
      (write-line "Usage: ")
      (write-line "        Pass an argument up to which prime numbers will be searched with")
      (write-line "        an inefficient algorithm, useful to compare the single thread performance")
      (write-line "        of the CPU")
      (write-line "Example: ")
      (write-line (concatenate 'string "        " (posix-getenv "_") " 304500"))
      (write-line "Notes: ")
      (write-line "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
      (write-line "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
      (write-line "        SBCL-32bits: it takes 9.924s using SBCL 1.4.5 32-bits.")
      (write-line "        SBCL: it takes 29.537s using SBCL 1.1.14 64-bits.")
      (terpri)
      (exit :code 1))

    (setf n (ignore-errors (parse-integer (cadr *posix-argv*))))
    (when (or (null n) (< n 2))
      (format *error-output* "ERROR: Argument '~a' not valid.~%" (cadr *posix-argv*))
      (exit :code 1))

    (gc :full t)
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
        (sb-sys:interactive-interrupt () (write-line " Interrupted!")))
    (abort () (write-line " Benchmark aborted"))))


;;; Call main when run directly as a script:
(unless (boundp '*is-compiling*)
  (main))

