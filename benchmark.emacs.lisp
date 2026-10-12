:;exec /usr/bin/emacs -Q --script "$0" "$@"

;;; Benchmark in GNU Emacs Lisp by JMC
;;;
;;;
;;; Run:
;;;     ./benchmark.emacs.lisp 30450
;;; or:
;;;     emacs -Q --script benchmark.emacs.lisp 30450
;;;
;;;
;;; Notes:
;;;     -Emacs Lisp is the extension language of the GNU Emacs editor. GNU Emacs was created in 1985
;;;      and as of 2018 it is still being maintained. Emacs Lisp is its own Lisp dialect, different
;;;      from both Commond Lisp and Scheme, although a bit closer to the former.
;;;
;;;     -Integers are signed 62 bits in Emacs for 64-bit Linux, and 30 bits in Emacs for 32-bit Linux.
;;;      In Emacs for 64-bit Linux the biggest positive integer is 2^61-1 and the negative is -2^61.
;;;      That is #x1FFFFFFFFFFFFFFF (2305843009213693951) and #x2000000000000000 (-2305843009213693952) respectively.
;;;      In Emacs for 32-bit Linux the biggest positive integer is 2^29-1 and the negative is -2^29.
;;;      That is #x1FFFFFFF (536870911) and #x20000000 (-536870912) respectively.
;;;
;;;     -The standard way of getting the fixnum integer range is:
;;;             (princ most-positive-fixnum) (terpri)
;;;             (princ most-negative-fixnum) (terpri)
;;;      Most lisps (not Emacs Lisp) support arbitrary precision integers (BIGNUMs).
;;;
;;;     -If a numeric value doesn't fit as an integer (fixnum) it is stored as a float. This makes it
;;;      a bit confusing to know what is going on with the precision. This code:
;;;             (setf i 536870911) (princ (format "%x %d %s\n" i i (type-of i)))
;;;             (setf i 536870912) (princ (format "%x %d %s\n" i i (type-of i)))
;;;      prints, for 32-bit Emacs:
;;;             1fffffff 536870911 integer
;;;             20000000 536870912 float
;;;      The same for 64-bit Emacs:
;;;             (setf i 2305843009213693951) (princ (format "%x %d %s\n" i i (type-of i)))
;;;             (setf i 2305843009213693952) (princ (format "%x %d %s\n" i i (type-of i)))
;;;      prints:
;;;             1fffffffffffffff 2305843009213693951 integer
;;;             2000000000000000 2305843009213693952 float
;;;
;;;     -The 32-bit version of Emacs is only a bit faster, about 5%. This is expected since the (mod) operation
;;;      is faster with smaller CPU registers (IDIV assembly instruction).
;;;
;;;     -Emacs Lisp doesn't implement neither the (loop) or the (do) constructs. Instead it implements (while).
;;;      The (dolist) and (dotimes) loop structures are present.
;;;
;;;     -Emacs Lisp doesn't have TCO (tail call optimization) for the moment, so a recursive version
;;;      of findPrimes would probably crash.
;;;
;;;
;;; Limitations:
;;;     -Command line arguments need to be filtered of the interpreter arguments.
;;;
;;;     -The normal shebang "#!/usr/bin/emacs --script" doesn't accept an extra argument like -Q
;;;      so that it doesn't print extra info when running the script. So I used the trick to make
;;;      the first line work both as a BASH command and as an Emacs Lisp comment.
;;;
;;;     -Calling string-to-number doesn't guarantee that the parsed number is an integer. For instance,
;;;      it accepts "3.2" and it will convert it to 3.2. It can be forced to int with 'truncate'.
;;;      Also, it will convert "123abc" to 123 without returning an error.
;;;        An error will be signalled if '1e20' is passed to 'truncate'; wrapping 'truncate' with
;;;      'ignore-errors' will return nil in that case.
;;;
;;;     -An extra test (reconverted integer != original string) is necessary after parsing the integer
;;;      argument to exclude strings like "123abc", otherwise Emacs Lisp parses it as 123. Because of this
;;;      extra test, an integer with a plus sign is not considered valid: "+123".
;;;


;;; NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;;; that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;;; but puts the function in a loop and counts 10000 calls).
;;; Returns how many prime numbers exist between 2 and n:
(defun findPrimes (n)
  (let ((count 0)
        (i 0)
        (j 0))
    ;; For each number up to 'n':
    (setf i 2)
    (while (<= i n)
      (setf count (1+ count))
      (setf j 2)
      (while (< j i)  ; NOT using the sqrt optimization (for easier benchmarking).
        ;; If i divisible by j, it wasn't a prime number:
        (when (= 0 (mod i j))
          (setf count (1- count))
          (setf j (1- i)))
        (setf j (1+ j)))
      ;; If the previous loop ended without divisors found, it is
      ;; a prime number. Count is not decremented in that case.
      (setf i (1+ i)))
    count))


;;; Version using a (catch) and (throw) to break out of the while loop instead of modifying the loop counter.
;;; Execution time is 0.113s for n=3045 and 8.507s for n=30450 using a 64-bit Emacs
;;; Surprisingly almost the same as the version above.
(defun findPrimes_Throw (n)
  (let ((count 0)
        (i 0)
        (j 0))
    ;; For each number up to 'n':
    (setf i 2)
    (while (<= i n)
      (catch 'divisorFound
        (setf j 2)
        (while (< j i)  ; NOT using the sqrt optimization (for easier benchmarking).
          ;; If i divisible by j, it wasn't a prime number:
          (if (= 0 (mod i j))
              (throw 'divisorFound t))
          (setf j (1+ j)))
        ;; The previous loop ended without divisors found. It is a prime number.
        (setf count (1+ count)))
      (setf i (1+ i)))
    count))


;;; Version using (dotimes) instead of (while). It's slower than using (while).
;;; Execution time is 0.143s for n=3045 and 10.796s for n=30450 using a 64-bit Emacs.
(defun findPrimes_DoTimesThrow (n)
  (let ((count 0))
    ;; For each number up to 'n':
    (dotimes (i (1+ n))
      (if (>= i 2)  ; dotimes always starts from 0.
        (catch 'divisorFound
          (dotimes (j i)  ; NOT using the sqrt optimization (for easier benchmarking).
            (if (>= j 2)
              ;; If i divisible by j, it wasn't a prime number:
              (if (= 0 (mod i j))
                  (throw 'divisorFound t))))
          ;; The previous loop ended without divisors found. It is a prime number.
          (setf count (1+ count)))))
    count))


(defun main ()
  (let ((startTime 0)
        (endTime 0)
        (elapsed 0)
        (n 0)
        (nstr "")
        (count 0)
        (programName ""))

    ;; Script name is the argument just before the script arguments (args versus args-left):
    ;; (The environment variable that should have the program name (getenv "_") is nil here)
    (setf programName (nth (1- (- (length command-line-args) (length command-line-args-left)))
                           command-line-args))

    (when (/= 1 (length command-line-args-left))
      (princ "Quick and dirty single thread CPU benchmark - by JMC\n")
      (princ "Usage: \n")
      (princ "        Pass an argument up to which prime numbers will be searched with\n")
      (princ "        an inefficient algorithm, useful to compare the single thread performance\n")
      (princ "        of the CPU\n")
      (princ "Example: \n")
      (princ (concat "        " programName " 304500\n"))
      (princ "Notes: \n")
      (princ "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n")
      (princ "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n")
      (princ "        Emacs Lisp: it takes 692.572s (12m) using GNU Emacs 25.2.2 in 64-bit Linux.\n")
      (princ "                    For n=3045 it takes 0.113s. For n=30450 it takes 8.483s.\n")
      (terpri)
      (kill-emacs 1))

    (setf nstr (car command-line-args-left))
    (setf n (ignore-errors (truncate (string-to-number nstr))))
    (when (or (eq nil n) (not (string= nstr (number-to-string n))) (< n 2))
      (princ (format "ERROR: Argument '%s' not valid.\n" nstr) 'external-debugging-output)
      (kill-emacs 1))

    (garbage-collect)
    (setf startTime (float-time))

    (setf count (findPrimes n))

    (setf endTime (float-time))
    (setf elapsed (- endTime startTime))
    (princ (format "Elapsed: %6.3fs\n" elapsed))

    (princ count) (princ " prime numbers were found between 2 and ") (princ n) (terpri)))


(main)

