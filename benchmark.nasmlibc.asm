$EMPTYVAR:;nasm -o "$0".o -felf64 "$0"  &&  gcc -o benchmark "$0".o  &&  exec -a "$0" ./benchmark "$@" ;  exec /bin/false
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

extern __errno_location
extern clock
extern exit
extern fprintf
extern printf
extern puts
extern stderr
extern strtol
CLOCKS_PER_SEC equ 1000000               ;Fixed to 1000000 according to POSIX. See "man clock".
                                         ;Thus clock() has fixed microsecond precision.
ERANGE equ 34
EINVAL equ 22


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


;Parses an int from a string in base 10, by correctly wrapping strtol() which returns a long.
;
;Returns the number and sets parseOk == 1 if the string represents a valid int. Returns 0 and sets
;parseOk == 0 and errno to EINVAL if the string is non numeric ("abc", "", " ", "a12" and "+" are
;considered non numeric).
;When the value underflows, INT_MIN is returned and parseOk is set to 0 and errno to ERANGE.
;When the value overflows, INT_MAX is returned and parseOk is set to 0 and errno to ERANGE..
;
;When 'junkAllowed' is non-zero, it allows extra non numeric chars and non space or tab chars after
;the number (example: "123a"). Otherwise returns 0 and sets parseOk to 0 and errno to EINVAL in that case.
;
;Spaces at the beginning or end are always allowed no matter the value of 'junkAllowed', as in " 123 ".
;
;The variable parseOk can be NULL if the caller is not interested in it.
;
;Notes:
;    -The standard functions atoi() and sscanf() produce undefined behaviour if the number in
;     the string is between INT_MAX and LONG_MAX in x86-x64 Linux, and they both always allow "junk"
;     after the number. In glibc, atoi() is equivalent to casting strtol() from long to int and ignoring
;     'end', which is wrong when sizeof(int) < sizeof(long) but it is allowed by the standard.
;    -Example: atoi("4294967419") returns 123 in 64-bit Linux, where an int is 4 bytes and a long is 8.
;    -This function fixes those issues, correctly wrapping strtol().
;    -Also, all three standard functions, atoi, sscanf and strtol allow spaces at the beginning, but if we
;     were to only check end != s && end != '\0' as strtol's man page suggests, we would introduce the
;     asymmetry of not allowing spaces at the end.
;    -The CommonLisp 'parse-integer' function always allows spaces at the end and has a ':junk-allowed'
;     argument, so parseInt is similar in those respects.
;
;Input: RDI pointer to null terminated string to parse.
;Input: ESI 32-bit junkAllowed. Pass 0 for strict parsing, 1 to allow non numeric chars after the digits.
;Input: RDX pointer to 32-bit parseOk or NULL. It will receive 0 if there was an error, or 1 if
;       parsing was successful.
;Output: EAX parsed 32-bit integer.
;Output: 32-bit int pointed to by parseOk. Sets it to 1 if all OK, or 0 if the string doesn't represent
;        a 32-bit base 10 integer value.
;Used registers: RAX, RDI, RSI, RDX, RCX.
parseInt:
        parseInt_s equ 8
        parseInt_junkAllowed equ parseInt_s + 4
        parseInt_parseOk equ parseInt_junkAllowed + 8
        parseInt_parsedLong equ parseInt_parseOk + 8
        parseInt_end equ parseInt_parsedLong + 8
        parseInt_didParseSomething equ parseInt_end + 4
        parseInt_errnoPtr equ parseInt_didParseSomething + 8
        parseInt_oldErrno equ parseInt_errnoPtr + 4
        parseInt_varsSize equ parseInt_oldErrno
        ;Prologue
        push rbp
        mov rbp, rsp
        sub rsp, parseInt_varsSize
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        ;Save args before calls:
        mov [rbp - parseInt_s], rdi
        mov [rbp - parseInt_junkAllowed], esi
        mov [rbp - parseInt_parseOk], rdx
        ;Init end, errnoPtr and oldErrno:
        mov [rbp - parseInt_end], rdi    ;end = s
        call __errno_location wrt ..plt
        mov [rbp - parseInt_errnoPtr], rax  ;errnoPtr = __errnoLocation()
        mov ecx, [rax]                      ;ECX = errno
        mov [rbp - parseInt_oldErrno], ecx  ;oldErrno = errno
        ;Set errno to zero before parsing because strtol
        ;doesn't touch errno if everything is ok:
        mov dword [rax], 0               ;errno = 0
        ;Note: 'errno' is the only correct way to know when the value underflows or overflows
        ;      Testing for LONG_MAX is wrong since in 32bits LONG_MAX == INT_MAX, and strtoll()
        ;      isn't always implemented by compilers. 'errno' is a thread-safe macro these days.
        ;Parse:
        mov rdi, [rbp - parseInt_s]
        lea rsi, [rbp - parseInt_end]
        mov edx, 10
        call strtol wrt ..plt
        mov [rbp - parseInt_parsedLong], rax

        ;Compute didParseSomething:
        ;Before skipping trailing spaces, we need to make sure that the last char was numeric (Cases: "  ", " + ").
        ;didParseSomething = (end != s && (*(end - 1) >= '0' && *(end - 1) <= '9'));
        mov rdi, [rbp - parseInt_s]
        cmp rdi, [rbp - parseInt_end]    ;end == s ?
        jz parseInt_didntParse
        mov rsi, [rbp - parseInt_end]
        dec rsi
        mov al, [rsi]
        cmp al, 0x30                     ;last parsed char < '0' ?
        jb parseInt_didntParse
        cmp al, 0x39                     ;last parsed char > '9' ?
        ja parseInt_didntParse
        mov dword [rbp - parseInt_didParseSomething], 1
        jmp parseInt_skipSpaces
parseInt_didntParse:
        mov dword [rbp - parseInt_didParseSomething], 0

        ;Consider spaces or tabs after the number to be always ok:
parseInt_skipSpaces:
        mov rdi, [rbp - parseInt_end]
parseInt_skipSpaces_loop:                ;while (*end == 0x20 || *end == '\t') ++end;
        cmp byte [rdi], 0x20
        jz parseInt_skipSpaces_skipChar
        cmp byte [rdi], 0x9
        jz parseInt_skipSpaces_skipChar
        jmp parseInt_skipSpaces_loop_end
parseInt_skipSpaces_skipChar:
        inc rdi
        jmp parseInt_skipSpaces_loop
parseInt_skipSpaces_loop_end:
        mov [rbp - parseInt_end], rdi    ;Save to 'end'

        ;Detect parsing error. If !junkAllowed, reject strings that are not fully numeric at the end (but accept " \t  +123  \t "):
        ;In C it is:  if ((errno != 0 && errno != ERANGE) || !didParseSomething || (*end != '\0' && !junkAllowed)) {..}
        mov rax, [rbp - parseInt_errnoPtr]
        mov ecx, [rax]                   ;ECX = errno
        test ecx, ecx                    ;errno == 0 ? Then skip condition to next OR condition.
        jz parseInt_cond_didParseSomething
        cmp ecx, ERANGE                  ;errno != ERANGE ?
        jnz parseInt_parsingError
parseInt_cond_didParseSomething:
        cmp dword [rbp - parseInt_didParseSomething], 0  ;didParseSomething == 0 ?
        jz parseInt_parsingError
        mov rax, [rbp - parseInt_end]
        mov cl, [rax]
        test cl, cl                      ;*end == 0 ? Then skip IF
        jz parseInt_noParsingError
        cmp dword [rbp - parseInt_junkAllowed], 0  ;junkAllowed == 0 ?
        jz parseInt_parsingError
        jmp parseInt_noParsingError
parseInt_parsingError:
        ;Set parseOk to 0, set errno to EINVAL and return 0:
        ;*parseOk = 0
        mov rcx, [rbp - parseInt_parseOk]
        test rcx, rcx                    ;Skip if parseOK points to NULL.
        jz parseInt_skipParseOk1
        mov dword [rcx], 0
parseInt_skipParseOk1:
        ;errno = EINVAL:
        mov rax, [rbp - parseInt_errnoPtr]
        mov dword [rax], EINVAL
        ;Return 0:
        mov qword [rbp - parseInt_parsedLong], 0
        jmp parseInt_return
parseInt_noParsingError:

        ;Fix undefined behaviour of atoi(s) and sscanf(s, "%d", &n):
        ;Check overflow:
        mov rax, [rbp - parseInt_parsedLong]
        cmp rax, 0x7fffffff              ;if parsedLong > INT_MAX saturate and set errno to ERANGE
        jle parseInt_noOverflow
        mov rax, [rbp - parseInt_errnoPtr]
        mov dword [rax], ERANGE
        mov qword [rbp - parseInt_parsedLong], 0x7fffffff
        jmp parseInt_checkErrno
parseInt_noOverflow:
        ;Check underflow:
        mov rax, [rbp - parseInt_parsedLong]
        mov ecx, 0x80000000
        movsxd rdx, ecx
        cmp rax, rdx
        jge parseInt_checkErrno
        mov rax, [rbp - parseInt_errnoPtr]
        mov dword [rax], ERANGE
        mov [rbp - parseInt_parsedLong], rdx

parseInt_checkErrno:
        ;Whether strtol() set errno to ERANGE (bigger than LONG_MAX) or we did (bigger than INT_MAX),
        ;return INT_MAX or INT_MIN and parseOk == 0:
        mov rax, [rbp - parseInt_errnoPtr]
        mov ecx, [rax]
        cmp ecx, ERANGE
        jnz parseInt_allGood
        ;*parseOk = 0
        mov rcx, [rbp - parseInt_parseOk]
        test rcx, rcx                    ;Skip if parseOK points to NULL.
        jz parseInt_skipParseOk2
        mov dword [rcx], 0
parseInt_skipParseOk2:
        jmp parseInt_return

parseInt_allGood:
        ;Set errno = oldErrno
        mov rax, [rbp - parseInt_errnoPtr]
        mov ecx, [rbp - parseInt_oldErrno]
        mov [rax], ecx
        ;*parseOk = 1:
        mov rcx, [rbp - parseInt_parseOk]
        test rcx, rcx
        jz parseInt_skipParseOk3
        mov dword [rcx], 1
parseInt_skipParseOk3:

parseInt_return:
        mov dword eax, [rbp - parseInt_parsedLong]
        ;Epilogue:
        mov rsp, rbp
        pop rbp
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
        main_parseOk equ main_argv + 4
        main_n equ main_parseOk + 4
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
        mov esi, 0                       ;RSI = junkAllowed = 0
        lea rdx, [rbp - main_parseOk]    ;RDX = &parseOk
        call parseInt
        mov [rbp - main_n], eax
        ;Validate 'n':
        cmp dword [rbp - main_parseOk], 0  ;parseOk == 0 ?
        jz main_nIsNotValid
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

