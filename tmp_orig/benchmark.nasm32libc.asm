$EMPTYVAR:;nasm -o "$0".o -felf32 "$0"  &&  gcc -m32 -o benchmark "$0".o  &&  exec -a "$0" ./benchmark $@ ;  exec /bin/false
;NOTE: For the shebang line to work well, the $EMPTYVAR variable must be empty or undefined.

;Benchmark in Assembly Language for NASM and 32-bit Linux using libc - by JMC
;
;
;Run:
;    ./benchmark.nasm32libc.asm 304500
;Assemble and run:
;    nasm -o benchmark.o -felf32 benchmark.nasm32libc.asm  &&  gcc -m32 -o benchmark benchmark.o  &&  ./benchmark 304500
;Note: To assemble this file on 64-bit Linux, since it depends on 32-bit libc and GCC, the
;following must be installed for 64-bit Ubuntu and variants:
;    sudo apt-get install libc6-dev-i386 gcc-multilib
;The other file "benchmark.nasm32.asm" doesn't require it since that one produces a static executable.
;
;
;Notes:
;    -See "benchmark.nasm.asm" for more notes about Assembly and NASM.
;
;    -This file (as opposed to benchmark.nasm32.asm), uses calls to and links to libc.
;     It is more compact since I didn't need any helper functions such as intToString().
;     I use gcc for linking this file, instead of linking with ld (as it was in benchmark.nasm32.asm).
;
;    -The default in almost all current Linux distros now (ever since about 2017) is to have
;     gcc compile Position Independent Executables (PIE). For 32-bit asm code assembled with
;     NASM and linked with GCC, it seems that the relocation is done transparently by the
;     runtime on load, and it is not necessary to write "call printf wrt ..plt" as it was
;     with x86_x64.
;     See the comments to the answer by Peter Cordes in this question for more details:
;            "32-bit absolute addresses no longer allowed in x86-64 Linux?"
;            https://stackoverflow.com/questions/43367427/32-bit-absolute-addresses-no-longer-allowed-in-x86-64-linux
;
;    -The resulting binary is indeed PIE, as can be checked with the 'file' command:
;            $ file benchmark   #For benchmark.nasm32.asm
;            benchmark: ELF 32-bit LSB executable, Intel 80386, version 1 (SYSV), statically linked, not stripped
;
;            $ file benchmark   #For benchmark.nasm32libc.asm
;            benchmark: ELF 32-bit LSB shared object, Intel 80386, version 1 (SYSV), dynamically linked, [..]
;     If it says "LSB shared object" it is a PIE executable. Otherwise it will say "LSB executable".
;


;No "default rel" required for elf32:  ;default rel
bits 32
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
;Input: ARG1 32-bit positive number.
;Output: EAX count of primes <= number.
;Used registers: EAX, EBX, ECX, EDX, ESI, EDI. Preserved: EBX, ESI, EDI.
findPrimes:
        ;Prologue:
        push ebp
        mov ebp, esp
        push ebx                         ;Save EBX, ESI, EDI. The 32-bit calling convention says those must be preserved.
        push esi
        push edi
        sub esp, 0xc                     ;Pad stack to a 16-byte boundary after pushes, assuming it was aligned at call time.
                                         ;Even though it is a leaf function: just to show how.
        ;Init:
        mov edi, [ebp + 8]               ;EDI is n (ARG1).
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
        mov eax, esi                     ;EAX = count
        ;Epilogue:
        add esp, 0xc                     ;Undo padding of stack.
        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Simple straightforward version that maps better to the C loops, without the trick of
;removing the unconditional jump from the repeatable part of both loops, and without
;breaking the loop straight to incrementing 'count'. In my Ivy Bridge laptop it is
;10% slower, but in my Haswell desktop CPU it has practically the same speed.
;
;Input: ARG1 32-bit positive number.
;Output: EAX count of primes <= number.
;Used registers: EAX, EBX, ECX, EDX, ESI, EDI. Preserved: EBX, ESI, EDI.
findPrimes_Simple:
        ;Prologue:
        push ebp
        mov ebp, esp
        push ebx                         ;Save EBX, ESI, EDI. The 32-bit calling convention says those must be preserved.
        push esi
        push edi
        sub esp, 0xc                     ;Pad stack to a 16-byte boundary after pushes, assuming it was aligned at call time.
                                         ;Even though it is a leaf function: just to show how.
        ;Init:
        mov edi, [ebp + 8]               ;EDI is n (ARG1).
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
        mov eax, esi                     ;EAX = count
        ;Epilogue:
        add esp, 0xc                     ;Undo padding of stack.
        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Entry point of the whole program. Execution begins at main
;The command line arguments come in ARG1 and ARG2 in the stack.
;The argument count 'argc' comes in ARG1 and 'argv' in ARG2.
global main
main:
        ;Stack layout:
        ;-8        ->  ;local var2 (dword sized)..
        ;-4        ->  ;local var1 (dword sized)
        ;+0 (rbp)  ->  ;old rbp
        ;+0x4      ->  ;RIP program counter for returning to caller
        ;+0x8      ->  ;argc (main ARG1)
        ;+0xc      ->  ;argv (main ARG2)
        ;Local vars offsets:
        main_n equ 4
        main_count equ main_n + 4
        main_startTime equ main_count + 4
        main_endTime equ main_startTime + 4
        main_elapsedClockT equ main_endTime + 4
        main_clocksPerSec equ main_elapsedClockT + 4
        main_elapsed equ main_elapsedClockT + 8
        main_varsSize equ main_elapsed
        ;Params offsets:
        main_PARAM_argc equ 8
        main_PARAM_argv equ 0xc
        ;Prologue:
        push ebp
        mov ebp, esp
        sub esp, main_varsSize           ;Reserve space for local vars.
        ;Align stack:
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).

        ;Print usage banner if command line args are not exactly one:
        mov ecx, [ebp + main_PARAM_argc]
        cmp ecx, 2
        jz main_exactlyOneCommandLineArg
        ;Print usage banner:
        sub esp, 8                       ;Align the stack to a 16-byte boundary before
                                         ;the call, counting the pushes.
        mov eax, [ebp + main_PARAM_argv]
        mov eax, [eax]                   ;EAX = argv[0]
        push eax
        push dword usageBannerString
        call printf
        add esp, 0x10                    ;Cleanup stack after call.
        ;Print newline:
        sub esp, 0xc
        push dword printNewlineString
        call puts
        add esp, 0x10
        ;Exit program here with exit code 1:
        sub esp, 0xc
        push dword 1
        call exit
        add esp, 0x10                    ;(Not really necessary since exit() won't return.)
main_exactlyOneCommandLineArg:

        ;Parse command line argument to integer 'n':
        sub esp, 0xc
        mov eax, [ebp + main_PARAM_argv]
        mov eax, [eax + 4]               ;EAX = argv[1]
        push eax
        call atoi
        mov [ebp - main_n], eax
        add esp, 0x10
        ;Validate 'n':
        cmp eax, 2                       ;n < 2 ?
        jge main_nIsValid
main_nIsNotValid:
        ;Print error to STDERR and exit:
        mov eax, [ebp + main_PARAM_argv]
        mov eax, [eax + 4]               ;EAX = argv[1]
        push eax
        push dword nNotValidError
        mov eax, [stderr]                ;RDI = STDERR pointer
        push eax
        call fprintf
        ;Exit program here with exit code 1:
        sub esp, 0xc
        push dword 1
        call exit
        add esp, 0x10                    ;(Not really necessary since exit() won't return.)
main_nIsValid:

        ;Clock start
        call clock
        mov [ebp - main_startTime], eax

        ;Find primes:
        sub esp, 0xc
        push dword [ebp - main_n]
        call findPrimes
        ;call findPrimes_Simple
        add esp, 0x10
        mov [ebp - main_count], eax

        ;Clock end
        call clock
        mov [ebp - main_endTime], eax
        ;Compute elapsed as a double in seconds:
        mov edx, [ebp - main_startTime]
        sub eax, edx                     ;RAX = endTime - startTime
        mov [ebp - main_elapsedClockT], eax
        fild dword [ebp - main_elapsedClockT]  ;Load elapsedClockT to float, which is (endTime - startTime)
        mov dword [ebp - main_clocksPerSec], CLOCKS_PER_SEC
        fild dword [ebp - main_clocksPerSec]   ;Load CLOCKS_PER_SEC constant to float, which is always 1E6.
        fdivp st1                              ;st0 = st1/st0 = (endTime - startTime) / CLOCKS_PER_SEC
        fstp qword [ebp - main_elapsed]        ;Store in 'elapsed' var which is a 64-bit double.
        ;Print Elapsed seconds with 3 fixed decimals and padding up to 6 spaces:
        sub esp, 4
        push dword [ebp - main_elapsed + 4]    ;Push high part of 'elapsed'.
        push dword [ebp - main_elapsed]        ;Push low part of 'elapsed'.
        push dword elapsedString
        call printf
        add esp, 0x10

        ;Print count of primes found:
        sub esp, 4
        push dword [ebp - main_n]
        push dword [ebp - main_count]
        push dword resultString
        call printf
        add esp, 0x10

        ;Exit code 0:
        mov eax, 0
        ;Epilogue:
        mov esp, ebp
        pop ebp
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
                  db "        NASM-32-libc: it takes 8.849s using NASM 2.13.01.", 0xa
                  db 0
nNotValidError db "ERROR: Argument '%s' not valid.", 0xa, 0
elapsedString db "Elapsed: %6.3fs", 0xa, 0
resultString db "%d prime numbers were found between 2 and %d", 0xa, 0


