//Compile and run:
//    rustc -O -o benchmark benchmark.rs  &&  ./benchmark 304500
//Recommended:
//    rustc -A non_snake_case -O -o benchmark benchmark.rs  &&  ./benchmark 304500

use std::io::{self,Write};
use std::time::{SystemTime};


//This is to avoid warnings on camelCase in the next function name:
#[allow(non_snake_case)]

//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
fn findPrimes(n : i32) -> i32 {
    //NOTE: With i64, it takes more than double the time, since IDIV asm instruction is slower on 64 bits (modulo % operation).
    let mut i : i32;
    let mut j : i32;
    let mut count : i32 = 0;

    //For each number up to 'n':
    i = 2;
    //Slower: for i in 2..(n+1) {
    while i <= n {
        j = 2;
        while j < i {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if i % j == 0 {
                break;
            }
            j += 1;
        }
        if i == j {
            //The previous loop ended without divisors found. It is a prime number.
            count += 1;
        }
        i += 1;
    }

    return count;
}


//This is to avoid warnings on camelCase variable names in the next function:
#[allow(non_snake_case)]

fn main() {
    //Convert args Iterator to regular, indexable, array:
    let args : Vec<_> = std::env::args().collect();
    //println!("{:?}", args);

    if args.len() != 2 {
        println!("Quick and dirty single thread CPU benchmark - by JMC");
        println!("Usage: ");
        println!("        Pass an argument up to which prime numbers will be searched with");
        println!("        an inefficient algorithm, useful to compare the single thread performance");
        println!("        of the CPU");
        println!("Example: ");
        println!("        {} 304500", args[0]);
        println!("Notes: ");
        println!("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        println!("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        println!("        Rust: it takes 8.865s using Rust 1.10.0 with flag -O.");
        println!("");
        std::process::exit(1);
    }

    let n : i32;
    let parseResult = args[1].parse();
    match parseResult {
        Result::Ok(value) => n = value,
        Result::Err(_) => n = -1,
    }
    if n < 2 {
        writeln!(&mut io::stderr(), "ERROR: Argument '{}' not valid.", args[1]).unwrap();
        //.expect("Could not write to stderr");
        std::process::exit(1);
    }

    let startTime = SystemTime::now();

    let count : i32 = findPrimes(n);

    let endTime = SystemTime::now();
    let elapsedDuration = endTime.duration_since(startTime).unwrap();
    let elapsed : f64 = (elapsedDuration.as_secs() as f64) + (elapsedDuration.subsec_nanos() as f64) / 1e9;
    println!("Elapsed: {:6.3}s", elapsed);

    println!("{} prime numbers were found between 2 and {}", count, n);
}


