#!/bin/bash

#Run all benchmarks in this directory:
#
#Example output with N=30450
#    Results:
#       c: 0.110 s
#       d: 0.117 s
#       gcl.lisp: 0.360 s
#       sbcl.lisp: 0.365 s
#       typed.rkt: 0.423 s
#       rkt: 0.525 s
#       lua: 1.179 s
#       guile.scm: 1.641 s
#       awk: 1.804 s
#       rb: 1.820 s
#       clisp.lisp: 2.165 s
#       tcl: 2.910 s
#       pl: 4.166 s
#       py: 4.461 s
#       ecl.lisp: 6.005 s
#       gambit.scm: 7.973 s


runBenchmarks() {
    #Benchmark list avoiding very slow benchmarks (bash, vim, etc.), and interactive benchmarks (mit-scheme):
    BENCHMARKS=`ls benchmark.* | grep -v vim | grep -v \.sh | grep -v \.bash | grep -v \.mitscheme\.scm`
    N=3045

    for filename in $BENCHMARKS; do
        #Get language from filename:
        LANGUAGE=`echo $filename|sed -e 's/benchmark[.]\(.*\)$/\1/'`
        LANGUAGE=`echo $LANGUAGE | sed -e $'s/^ *//'`
        1>&2 echo -n "Running $LANGUAGE ..."

        OUTPUT=`./$filename $N 2>&1 | grep -i elapsed`

        #if error level is successful, parse and return elapsed time:
        if [ $? -eq 0 ]; then
            OUTPUT=`echo $OUTPUT | sed -e 's/Elapsed: \(.*\)s/\1/'`
            printf "%-13s %7s\n" $LANGUAGE: ${OUTPUT}s
            1>&2 echo ""
        else
            1>&2 echo " ERROR"
        fi
    done
}


main() {
    RESULT=$(runBenchmarks)
    echo
    echo "Results:"
    #Sort and print results of benchmarks that didn't fail:
    #(using "$RESULT" between quotes so that it preserves newlines)
    echo "$RESULT" | sort -n -k2
}


main "$@"

