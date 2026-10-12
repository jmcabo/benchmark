#|
#Compile to .o and run:
GCL_ANSI=t exec /usr/bin/gcl -batch -eval "(setf COMPILER:*COMPILE-VERBOSE* nil)" \
                             -eval "(setf COMPILER:*SUPPRESS-COMPILER-NOTES* t)" \
                             -eval "(compile-file \"$0\" \
                                     :output-file \"`mktemp -d --tmpdir "gcl_compiler_XXXXXX"`/\" \
                                     :load t)" -- "$0" "$@"

Scripting Notes:
    -The shell stops reading the rest of the file when calling "exec".
    -The "exec" must be the first instruction in the file, to preserve the "_" env var as the invoked
     program name (no other way).
    -GCL leaves files lying around (.o, .data, etc.). The safest thing is to put them in a temporary
     directory created with mktemp. But it doesn't get deleted on exit.

This is a kind-of shebang inside a Lisp multiline comment.
GCL doesn't support "#" comments and produces errors when compiling with a proper shebang.
  This isn't actually a shebang, since the file can only be run directly by the shell or by unix system()
calls (which are actually "/bin/sh -c" calls), not by execve() calls, since it doesn't start with the
magic "#!" chars plus path.

Alternative (VERY SLOW):
    GCL_ANSI=t exec /usr/bin/gcl -batch -load "$0" -- "$0" "$@"
Alternative (VERY SLOW and skips first line):
    GCL_ANSI=t exec /usr/bin/gcl -f "$0" "$@"
|#

;;; Benchmark in Common Lisp for GCL - by JMC
;;;
;;;
;;; Compile and run:
;;;     GCL_ANSI=t gcl -batch -eval "(defvar *is-compiling* t)" \
;;;                           -eval "(setf COMPILER:*COMPILE-VERBOSE* nil)" \
;;;                           -eval "(setf COMPILER:*SUPPRESS-COMPILER-NOTES* t)" \
;;;                           -eval "(compile-file \"benchmark.gcl.lisp\" :load t)" \
;;;                           -eval "(setf system::*top-level-hook* 'mainStdAlone)" \
;;;                           -eval "(system::save-system \"benchmark\")"  &&  ./benchmark 304500
;;;
;;; The same in one line for easy copy and paste:
;;;     GCL_ANSI=t gcl -batch -eval "(defvar *is-compiling* t)" -eval "(setf COMPILER:*COMPILE-VERBOSE* nil)" -eval "(setf COMPILER:*SUPPRESS-COMPILER-NOTES* t)" -eval "(compile-file \"benchmark.gcl.lisp\" :load t)" -eval "(setf system::*top-level-hook* 'mainStdAlone)" -eval "(system::save-system \"benchmark\")"  &&  ./benchmark 304500
;;;
;;; Compilation Notes:
;;;     -While compiling, GCL creates a "benchmark.c" file and deletes it. If this is done in the same
;;;      directory as all the benchmark files, "benchmark.c" can be restored with:
;;;             git checkout benchmark.c
;;;     -The "-batch" is so that it quits instead of jumping into the REPL at the end.
;;;     -My defvar *is-compiling* is so that (main) doesn't run while the file is being loaded for
;;;      compilation.
;;;     -The supposed argument to load "scripts", which is "-f", doesn't work (at least in 2.6.10, it
;;;      gives an error about a 'declare in wrong position').
;;;     -The (compile-file) step can be replaced by (load). It wouldn't leave object files around, but
;;;      it would be interpreted, slow code (20x to 35x slower).
;;;     -Compiling is necessary. The interpreter doesn't do Tail Call Optimization, that means recursive
;;;      functions will crash with the interpreter, or run slow.
;;;
;;;
;;; Notes:
;;;     -GCL (GNU Common Lisp) was created in 1984 under a different name. It was renamed to GCL in 1994.
;;;      As of 2019 it is still being mantained and developed. It is an implementation of Common Lisp.
;;;      It compiles to C and then to native code. It has been ported to many Linux architectures and
;;;      also to Mac OS X and Windows. It has both an interpreter and a compiler. Interpreter code
;;;      runs slower than compiled code and GCL only supports TCO for compiled code.
;;;
;;;     -GCL has two modes of operation: the default and GCL_ANSI. The default is not too usable, but
;;;      exists for compatibility reasons for software already written for GCL. For instance, the default
;;;      mode doesn't support Common Lisp conditions (no handler-case, no ignore-errors). Instead, errors are
;;;      signalled to a global function called "universal-error-handler" that one can override.
;;;        By defining an environment variable called "GCL_ANSI" with value "t", GCL then behaves more like
;;;      standard Common Lisp and supports the conditions system. This info was not easy to find online.
;;;
;;;     -Integers have infinite arbitrary precision (Bignums). Fixnums (fast integers) are 64 bits in
;;;      the 64-bit version of GCL:
;;;             >most-positive-fixnum
;;;             9223372036854775807
;;;             >most-negative-fixnum
;;;             -9223372036854775808
;;;      If one adds 1 to most-positive-fixnum, it becomes a Bignum automatically.
;;;
;;;     -See benchmark.sbcl.lisp for more notes about Common Lisp.
;;;
;;; Limitations
;;;     -Shebang is more complicated than it should be, but I made it work for compiling when running as a
;;;      script. The compiler doesn't like true shebangs that start with "#!", so using "#!/usr/bin/gcl -f"
;;;      as a shebang interferes when compiling, because then it doesn't ignore the first line.
;;;
;;;     -Command line arguments need to be filtered.
;;;


;;; Not always necessary for speedup:
;;;     (declaim (optimize (speed 3) (debug 0) (safety 0)))


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
(defun findPrimes (n)
  ;(declare (fixnum n))  ; Just "fixnum n" gives the fastest speed in SBCL, but ECL and GCL need i and j as fixnums.
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
        (args si::*command-args*))

    ;Remove arguments until "--" inclusive, only if "--" is found:
    (let ((lst (member "--" args :test 'equal)))
      (if lst
          (setf args (cdr lst))))

    (when (/= 2 (length args))
      (write-line "Quick and dirty single thread CPU benchmark - by JMC")
      (write-line "Usage: ")
      (write-line "        Pass an argument up to which prime numbers will be searched with")
      (write-line "        an inefficient algorithm, useful to compare the single thread performance")
      (write-line "        of the CPU")
      (write-line "Example: ")
      (write-line (concatenate 'string "        " (system:getenv "_") " 304500"))   ;(file-namestring (car args))
      (write-line "Notes: ")
      (write-line "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz")
      (write-line "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.")
      (write-line "        GCL-32bits: it takes 8.939s using GCL 2.6.12 32-bits.")
      (write-line "        GCL: it takes 28.569s using GCL 2.6.10 64-bits.")
      (terpri)
      (quit 1))

    (setf n (ignore-errors (parse-integer (cadr args))))
    (when (or (null n) (< n 2))
      (format *error-output* "ERROR: Argument '~a' not valid.~%" (cadr args))
      (quit 1))

    (gbc t)
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
        ;; NOTE: GCL doesn't have a specific condition for CTRL+C console interruption
        ;; to distinguish that from other errors:
        (error (condition) (format t "    ERROR!: ~a~%" condition)))
    (abort () (write-line " Benchmark aborted")))
  ;; Quit. Don't fall through to the compiled interpreter:
  (quit))


;;; Call main when run directly as a script:
(unless (boundp '*is-compiling*)
  (main))

