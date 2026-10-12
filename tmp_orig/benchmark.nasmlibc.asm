$EMPTYVAR:;nasm -o "$0".o -felf64 "$0"  &&  gcc -o benchmark "$0".o  &&  exec -a "$0" ./benchmark $@ ;  exec /bin/false
;NOTE: For the shebang line to work well, the $EMPTYVAR variable must be empty or undefined.

;Benchmark in Assembly Language for NASM and 64-bit Linux using libc - by JMC
;
;
;Run:
;    ./benchmark.nasmlibc.asm 304500
;Assemble and run:
;    nasm -o benchmark.o -felf64 benchmark.nasmlibc.asm  &&  gcc -o benchmark benchmark.o  &&  ./benchmark 304500
;
;
;Notes:
;    -See "benchmark.nasm.asm" for more notes about Assembly and NASM.
;
;    -See "benchmark.gaslibc.s" for the same code but written for GAS.
;
;    -This file (as opposed to benchmark.nasm.asm), uses calls to and links to libc.
;     It is more compact since I didn't need any helper functions such as intToString().
;     I use gcc for linking this file, instead of linking with ld (as it was in benchmark.nasm.asm).
;
;    -The default in almost all current Linux distros now (ever since about 2017) is to have
;     gcc compile Position Independent Executables (PIE). That means that when compiling
;     with default switches, we cannot simply do:
;           call printf
;     with NASM we must do instead:
;           call printf wrt ..plt
;     That resolves the call location with reference to the PLT (Procedure Linkage Table).
;     The alternative is to pass -no-pie to gcc. In that case we can still use "call printf".
;
;    -With PIE, we need to have "default rel" for referencing exported global variables such
;     as 'stderr' like this:
;           default rel
;     somewhere in the beginning of the NASM file. Otherwise this error is produced when linking:
;           relocation R_X86_64_32S against symbol `stderr@@GLIBC_2.2.5' can not be used
;           when making a shared object; recompile with -fPIC
;


default rel                              ;This is required for referencing the libc global var 'stderr'.
bits 64
section .text

extern atoi
extern clock
extern exit
extern fprintf
extern printf
extern puts
extern stderr
CLOCKS_PER_SEC equ 1000000               ;Fixed to 1000000 according to POSIX. See "man clock".
                                         ;Thus clock() has fixed microsecond precision.


;NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
;that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
;but puts the function in a loop and counts 10000 calls).
;Returns how many prime numbers exist between 2 and n:
;
;Input: RDI 32-bit positive number.
;Output: RAX count of primes <= number.
;Used registers: RAX, RBX, RDI, RSI, RDX, RCX. RBX and RDI are preserved.
findPrimes:
        push rbx                         ;Save RBX. The 64-bit calling convention says RBX must be preserved.
                                         ;With the push of RBX over RIP, the stack is aligned to 16 bytes.
                                         ;Not really needed though in a leaf function.
        xor esi, esi                     ;ESI is count. Init to zero.
        ;For each number up to 'n':
        ;Loop i from 2 to n:
        mov ebx, 2                       ;EBX is i
        jmp findPrimes_loopI_guard
findPrimes_loopI:
        ;Loop j from 2 to below i:
        mov ecx, 2                       ;ECX is j
        jmp findPrimes_loopJ_guard
findPrimes_loopJ:
        ;Compute modulus between EBX and ECX. IDIV stores the modulus (actually remainder) in EDX:
        mov eax, ebx
        cdq
        idiv ecx                         ;EDX = EBX % ECX
        test edx, edx                    ;If i divisible by j, it wasn't a prime number:
        jz findPrimes_notPrime           ;Break
        inc ecx                          ;j += 1
findPrimes_loopJ_guard:
        ;Check if j < i:
        cmp ecx, ebx                     ;NOT using the sqrt optimization (for easier benchmarking).
        jl findPrimes_loopJ
findPrimes_loopJEnd:
        ;The previous loop ended without divisors found. It is a prime number:
        inc esi                          ;count += 1
findPrimes_notPrime:
        inc ebx                          ;i += 1
findPrimes_loopI_guard:
        ;Check if i <= n:
        cmp ebx, edi
        jle findPrimes_loopI
findPrimes_loopIEnd:
        mov eax, esi                     ;RAX = count  ("MOV EAX, *", zeroes high part of RAX)
        pop rbx
        ret


;Simple straightforward version that maps better to the C loops, without the trick of
;removing the unconditional jump from the repeatable part of both loops, and without
;breaking the loop straight to incrementing 'count'. In my Ivy Bridge laptop it is
;10% slower, but in my Haswell desktop CPU it has practically the same speed.
;
;Input: RDI 32-bit positive number.
;Output: RAX count of primes <= number.
;Used registers: RAX, RBX, RDI, RSI, RDX, RCX. RBX and RDI are preserved.
findPrimes_Simple:
        push rbx                         ;Save RBX. The 64-bit calling convention says RBX must be preserved.
                                         ;With the push of RBX over RIP, the stack is aligned to 16 bytes.
                                         ;Not really needed though in a leaf function.
        xor esi, esi                     ;ESI is count. Init to zero.
        ;For each number up to 'n':
        ;Loop i from 2 to n:
        mov ebx, 2                       ;EBX is i
findPrimes_Simple_loopI:
        ;Check if i <= n:
        cmp ebx, edi
        jg findPrimes_Simple_end
        ;Loop j from 2 to below i:
        mov ecx, 2                       ;ECX is j
findPrimes_Simple_loopJ:
        ;Check if j < i:
        cmp ecx, ebx
        jge findPrimes_Simple_loopJEnd
        ;Compute modulus between EBX and ECX. IDIV stores the modulus (actually remainder) in EDX:
        mov eax, ebx
        cdq
        idiv ecx                         ;EDX = EBX % ECX
        test edx, edx                    ;If i divisible by j, it wasn't a prime number:
        jz findPrimes_Simple_loopJEnd    ;Break
        inc ecx                          ;j += 1
        jmp findPrimes_Simple_loopJ
findPrimes_Simple_loopJEnd:
        ;Check if i == j. If it is, the loop ended without breaking.
        cmp ebx, ecx
        jnz findPrimes_Simple_notPrime
        ;The previous loop ended without divisors found. It is a prime number:
        inc esi                          ;count += 1
findPrimes_Simple_notPrime:
        inc ebx                          ;i += 1
        jmp findPrimes_Simple_loopI
findPrimes_Simple_end:
        mov eax, esi                     ;RAX = count  ("MOV EAX, *", zeroes high part of RAX)
        pop rbx
        ret


;Entry point of the whole program. Execution begins at main
;The command line arguments come in RDI and RSI.
;The argument count 'argc' comes in RDI and 'argv' in RSI.
global main
main:
        ;Stack layout:
        ;-0x10     ->  ;local var2 (quad word sized)..
        ;-8        ->  ;local var1 (quad word sized)
        ;+0 (rbp)  ->  ;old rbp
        ;+0x8      ->  ;RIP program counter for returning to caller
        ;Local vars offsets:
        main_argc equ 8
        main_argv equ main_argc + 8
        main_n equ main_argv + 4
        main_count equ main_n + 4
        main_startTime equ main_count + 8
        main_endTime equ main_startTime + 8
        main_elapsed equ main_endTime + 8
        main_varsSize equ main_elapsed
        ;Prologue:
        push rbp
        mov rbp, rsp
        sub rsp, main_varsSize           ;Reserve space for local vars.
        ;Align stack:
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        ;Save ARGC and ARGV to variables before overwriting RDI and RSI:
        mov [rbp - main_argc], rdi
        mov [rbp - main_argv], rsi

        ;Print usage banner if command line args are not exactly one:
        mov rcx, [rbp - main_argc]
        cmp rcx, 2
        jz main_exactlyOneCommandLineArg
        ;Print usage banner:
        mov rdi, usageBannerString       ;RDI = first printf argument
        mov rsi, [rbp - main_argv]
        mov rsi, [rsi]                   ;RSI = argv[0]
        xor rax, rax                     ;RAX = 0 = No vector args (floats) in this call to printf.
        call printf wrt ..plt
        ;Print newline:
        mov rdi, printNewlineString
        call puts wrt ..plt
        ;Exit program here with exit code 1:
        mov rdi, 1
        call exit wrt ..plt
main_exactlyOneCommandLineArg:

        ;Parse command line argument to integer 'n':
        mov rdi, [rbp - main_argv]
        mov rdi, [rdi + 8]               ;RDI = argv[1]
        call atoi wrt ..plt
        mov [rbp - main_n], eax
        ;Validate 'n':
        cmp eax, 2                       ;n < 2 ?
        jge main_nIsValid
main_nIsNotValid:
        ;Print error to STDERR and exit:
        mov rdi, [stderr]                ;RDI = STDERR pointer (this line requires 'default rel')
        mov rsi, nNotValidError
        mov rdx, [rbp - main_argv]
        mov rdx, [rdx + 8]
        xor rax, rax
        call fprintf wrt ..plt
        ;Exit program here with exit code 1:
        mov rdi, 1
        call exit wrt ..plt
main_nIsValid:

        ;Clock start
        call clock wrt ..plt
        mov [rbp - main_startTime], rax

        ;Find primes:
        mov edi, [rbp - main_n]
        call findPrimes
        ;call findPrimes_Simple
        mov [rbp - main_count], eax

        ;Clock end
        call clock wrt ..plt
        mov [rbp - main_endTime], rax
        ;Compute elapsed as a double in seconds:
        mov rdx, [rbp - main_startTime]
        sub rax, rdx                     ;RAX = endTime - startTime
        cvtsi2sd xmm0, rax
        mov rdx, CLOCKS_PER_SEC
        cvtsi2sd xmm1, rdx
        divsd xmm0, xmm1                 ;(endTime - startTime) / CLOCKS_PER_SEC
        movsd [rbp - main_elapsed], xmm0
        ;Print Elapsed seconds with 3 fixed decimals and padding up to 6 spaces:
        mov rdi, elapsedString
        mov rax, 1                       ;AL = Number of floating point args. XMM0 has the double argument
        call printf wrt ..plt

        ;Print count of primes found:
        mov rdi, resultString
        mov esi, [rbp - main_count]
        mov edx, [rbp - main_n]
        xor rax, rax
        call printf wrt ..plt

        ;Exit code 0:
        mov rax, 0
        ;Epilogue:
        mov rsp, rbp
        pop rbp
        ret


section .data
printNewlineString db 0xa, 0
usageBannerString db "Quick and dirty single thread CPU benchmark - by JMC", 0xa
                  db "Usage: ", 0xa
                  db "        Pass an argument up to which prime numbers will be searched with", 0xa
                  db "        an inefficient algorithm, useful to compare the single thread performance", 0xa
                  db "        of the CPU", 0xa
                  db "Example: ", 0xa
                  db "        %s 304500", 0xa
                  db "Notes: ", 0xa
                  db "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz", 0xa
                  db "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.", 0xa
                  db "        NASM-libc: it takes 8.849s using NASM 2.13.01.", 0xa
                  db 0
nNotValidError db "ERROR: Argument '%s' not valid.", 0xa, 0
elapsedString db "Elapsed: %6.3fs", 0xa, 0
resultString db "%d prime numbers were found between 2 and %d", 0xa, 0


