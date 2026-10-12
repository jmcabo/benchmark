$EMPTYVAR:;nasm -o "$0".o -felf32 "$0"  &&  gcc -m32 -o benchmark "$0".o  &&  exec -a "$0" ./benchmark "$@" ;  exec /bin/false
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
;Input: ARG1 pointer to null terminated string to parse.
;Input: ARG2 32-bit junkAllowed. Pass 0 for strict parsing, 1 to allow non numeric chars after the digits.
;Input: ARG3 pointer to 32-bit parseOk or NULL. It will receive 0 if there was an error, or 1 if
;       parsing was successful.
;Output: EAX parsed 32-bit integer.
;Output: 32-bit int pointed to by parseOk. Sets it to 1 if all OK, or 0 if the string doesn't represent
;        a 32-bit base 10 integer value.
;Used registers: EAX, ECX, ESI, EDI. Preserved: ESI, EDI.
parseInt:
        ;Local vars offsets:
        parseInt_parsedLong equ 4        ;A 'long' is 4 bytes in 32-bit Linux with GCC -m32.
        parseInt_end equ parseInt_parsedLong + 4
        parseInt_didParseSomething equ parseInt_end + 4
        parseInt_errnoPtr equ parseInt_didParseSomething + 4
        parseInt_oldErrno equ parseInt_errnoPtr + 4
        parseInt_varsSize equ parseInt_oldErrno
        ;Params offsets:
        parseInt_PARAM_s equ 8
        parseInt_PARAM_junkAllowed equ 0xc
        parseInt_PARAM_parseOk equ 0x10
        ;Prologue
        push ebp
        mov ebp, esp
        sub esp, parseInt_varsSize
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push esi
        push edi
        sub esp, 8                       ;Pad stack to a 16-byte boundary after pushes.
        ;Init end, errnoPtr and oldErrno:
        mov ecx, [ebp + parseInt_PARAM_s]
        mov [ebp - parseInt_end], ecx    ;end = s
        call __errno_location
        mov [ebp - parseInt_errnoPtr], eax  ;errnoPtr = __errnoLocation()
        mov ecx, [eax]                      ;ECX = errno
        mov [ebp - parseInt_oldErrno], ecx  ;oldErrno = errno
        ;Set errno to zero before parsing because strtol
        ;doesn't touch errno if everything is ok:
        mov dword [eax], 0               ;errno = 0
        ;Note: 'errno' is the only correct way to know when the value underflows or overflows
        ;      Testing for LONG_MAX is wrong since in 32bits LONG_MAX == INT_MAX, and strtoll()
        ;      isn't always implemented by compilers. 'errno' is a thread-safe macro these days.
        ;Parse:
        sub esp, 4
        push dword 10
        lea esi, [ebp - parseInt_end]
        push esi
        push dword [ebp + parseInt_PARAM_s]
        call strtol
        add esp, 0x10
        mov [ebp - parseInt_parsedLong], eax

        ;Compute didParseSomething:
        ;Before skipping trailing spaces, we need to make sure that the last char was numeric (Cases: "  ", " + ").
        ;didParseSomething = (end != s && (*(end - 1) >= '0' && *(end - 1) <= '9'));
        mov edi, [ebp + parseInt_PARAM_s]
        cmp edi, [ebp - parseInt_end]    ;end == s ?
        jz parseInt_didntParse
        mov esi, [ebp - parseInt_end]
        dec esi
        mov al, [esi]
        cmp al, 0x30                     ;last parsed char < '0' ?
        jb parseInt_didntParse
        cmp al, 0x39                     ;last parsed char > '9' ?
        ja parseInt_didntParse
        mov dword [ebp - parseInt_didParseSomething], 1
        jmp parseInt_skipSpaces
parseInt_didntParse:
        mov dword [ebp - parseInt_didParseSomething], 0

        ;Consider spaces or tabs after the number to be always ok:
parseInt_skipSpaces:
        mov edi, [ebp - parseInt_end]
parseInt_skipSpaces_loop:                ;while (*end == 0x20 || *end == '\t') ++end;
        cmp byte [edi], 0x20
        jz parseInt_skipSpaces_skipChar
        cmp byte [edi], 0x9
        jz parseInt_skipSpaces_skipChar
        jmp parseInt_skipSpaces_loop_end
parseInt_skipSpaces_skipChar:
        inc edi
        jmp parseInt_skipSpaces_loop
parseInt_skipSpaces_loop_end:
        mov [ebp - parseInt_end], edi    ;Save to 'end'

        ;Detect parsing error. If !junkAllowed, reject strings that are not fully numeric at the end (but accept " \t  +123  \t "):
        ;In C it is:  if ((errno != 0 && errno != ERANGE) || !didParseSomething || (*end != '\0' && !junkAllowed)) {..}
        mov eax, [ebp - parseInt_errnoPtr]
        mov ecx, [eax]                   ;ECX = errno
        test ecx, ecx                    ;errno == 0 ? Then skip condition to next OR condition.
        jz parseInt_cond_didParseSomething
        cmp ecx, ERANGE                  ;errno != ERANGE ?
        jnz parseInt_parsingError
parseInt_cond_didParseSomething:
        cmp dword [ebp - parseInt_didParseSomething], 0  ;didParseSomething == 0 ?
        jz parseInt_parsingError
        mov eax, [ebp - parseInt_end]
        mov cl, [eax]
        test cl, cl                      ;*end == 0 ? Then skip IF
        jz parseInt_noParsingError
        cmp dword [ebp + parseInt_PARAM_junkAllowed], 0  ;junkAllowed == 0 ?
        jz parseInt_parsingError
        jmp parseInt_noParsingError
parseInt_parsingError:
        ;Set parseOk to 0, set errno to EINVAL and return 0:
        ;*parseOk = 0
        mov ecx, [ebp + parseInt_PARAM_parseOk]
        test ecx, ecx                    ;Skip if parseOK points to NULL.
        jz parseInt_skipParseOk1
        mov dword [ecx], 0
parseInt_skipParseOk1:
        ;errno = EINVAL:
        mov eax, [ebp - parseInt_errnoPtr]
        mov dword [eax], EINVAL
        ;Return 0:
        mov dword [ebp - parseInt_parsedLong], 0
        jmp parseInt_return
parseInt_noParsingError:

        ;Fix undefined behaviour of atoi(s) and sscanf(s, "%d", &n):
        ;Check overflow:
        ; ... (Not necessary with 'sizeof(int) == sizeof(long)' here in 32-bits.

parseInt_checkErrno:
        ;If strtol() set errno to ERANGE (bigger than LONG_MAX),
        ;return INT_MAX or INT_MIN and parseOk == 0:
        mov eax, [ebp - parseInt_errnoPtr]
        mov ecx, [eax]
        cmp ecx, ERANGE
        jnz parseInt_allGood
        ;*parseOk = 0
        mov ecx, [ebp + parseInt_PARAM_parseOk]
        test ecx, ecx                    ;Skip if parseOK points to NULL.
        jz parseInt_skipParseOk2
        mov dword [ecx], 0
parseInt_skipParseOk2:
        jmp parseInt_return

parseInt_allGood:
        ;Set errno = oldErrno
        mov eax, [ebp - parseInt_errnoPtr]
        mov ecx, [ebp - parseInt_oldErrno]
        mov [eax], ecx
        ;*parseOk = 1:
        mov ecx, [ebp + parseInt_PARAM_parseOk]
        test ecx, ecx
        jz parseInt_skipParseOk3
        mov dword [ecx], 1
parseInt_skipParseOk3:

parseInt_return:
        mov dword eax, [ebp - parseInt_parsedLong]
        ;Epilogue:
        add esp, 8                       ;Undo padding of stack.
        pop edi
        pop esi
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
        ;+0 (ebp)  ->  ;old ebp
        ;+0x4      ->  ;RIP program counter for returning to caller
        ;+0x8      ->  ;argc (main ARG1)
        ;+0xc      ->  ;argv (main ARG2)
        ;Local vars offsets:
        main_parseOk equ 4
        main_n equ main_parseOk + 4
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
        sub esp, 4
        lea edx, [ebp - main_parseOk]    ;ARG3 = EDX = &parseOk
        push edx
        push dword 0                     ;ARG2 = junkAllowed = 0
        mov eax, [ebp + main_PARAM_argv]
        mov eax, [eax + 4]
        push eax                         ;ARG1 = EAX = argv[1]
        call parseInt
        add esp, 0x10
        mov [ebp - main_n], eax
        ;Validate 'n':
        cmp dword [ebp - main_parseOk], 0  ;parseOk == 0 ?
        jz main_nIsNotValid
        cmp eax, 2                       ;n < 2 ?
        jge main_nIsValid
main_nIsNotValid:
        ;Print error to STDERR and exit:
        mov eax, [ebp + main_PARAM_argv]
        mov eax, [eax + 4]               ;EAX = argv[1]
        push eax
        push dword nNotValidError
        mov eax, [stderr]                ;EAX = STDERR pointer
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
        sub eax, edx                     ;EAX = endTime - startTime
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


