#!/usr/bin/Rscript

#To run manually:
#     R --no-restore --slave --file=./benchmark.R --args 304500

#Enabling the JIT gives a considerable speedup:
result = library(compiler)
result = enableJIT(3)


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
findPrimes = function(n) {
    count <- 0L

    #For each number up to 'n':
    for (i in 2:n) {
        #Note R: Using WHILE instead of FOR on a range is actually twice as slow for some reason.
        for (j in 2:i) {  #NOT using the sqrt optimization (for easier benchmarking).
            #If i divisible by j, it wasn't a prime number:
            if (i %% j == 0) {
                break
            }
        }
        if (i == j) {
            #The previous loop ended without divisors found. It is a prime number.
            count = count + 1L
        }
    }
    count
}


main = function() {
    programName <- ""
    for (arg in commandArgs()) {
        #Example: "--file=./benchmark.R"
        if ((programName <- sub("--file=", "", arg)) != arg) {
            break;
        }
    }
    args <- commandArgs(trailingOnly = TRUE)
    if (length(args) != 1) {
        cat("Quick and dirty single thread CPU benchmark - by JMC\n");
        cat("Usage: \n");
        cat("        Pass an argument up to which prime numbers will be searched with\n");
        cat("        an inefficient algorithm, useful to compare the single thread performance\n");
        cat("        of the CPU\n");
        cat("Example: \n");
        cat(paste("        ", programName, " 304500\n", sep=""))
        cat("Notes: \n");
        cat("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n");
        cat("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n");
        cat("        R: it takes 439.7s using R 3.3.1 with JIT enabled, and 1088s without JIT.\n");
        cat("        and it takes 591.9s using R 3.0.2 with JIT enabled, and 2195s without JIT.\n");
        cat("\n");
        quit(status=1, save='no', runLast=FALSE)
    }

    n <- strtoi(args[1])
    if (is.na(n) || n < 2) {
        write(sprintf("ERROR: Argument '%s' not valid.", args[1]), stderr())
        quit(status=1, save='no', runLast=FALSE)
    }

    #Either JIT or manually precompiling are the same speed
    #  #Precompile the function: (Otherwise it is 4x slower):
    #  findPrimesCompiled <- cmpfun(findPrimes)

    #Give the JIT a chance to optimize before timing:
    count <- findPrimes(3)

    startTime <- Sys.time()

    count <- findPrimes(n)
    #count <- findPrimesCompiled(n)

    endTime <- Sys.time()
    elapsed <- as.numeric(endTime - startTime, units='secs')
    write(sprintf("Elapsed: %6.3fs", elapsed), stdout())

    write(paste(count, "prime numbers were found between 2 and", n), stdout())
}


main()

