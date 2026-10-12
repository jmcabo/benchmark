$EMPTYVAR:;nasm -o "$0".o -felf32 "$0"  &&  ld -o benchmark "$0".o -m elf_i386  &&  exec -a "$0" ./benchmark $@ ;  exec /bin/false
;NOTE: For the shebang line to work well, the $EMPTYVAR variable must be empty or undefined.

;Benchmark in Assembly Language for NASM and 32-bit Linux (no libc) - by JMC
;
;
;Run:
;    ./benchmark.nasm32.asm 304500
;Assemble and run:
;    nasm -o benchmark.o -felf32 benchmark.nasm32.asm  &&  ld -o benchmark benchmark.o -m elf_i386  &&  ./benchmark 304500
;
;
;Notes:
;    -See "benchmark.nasm.asm" for more notes about Assembly and NASM.
;
;    -This file (as opposed to benchmark.nasm.asm), is written in 32 bits assembly.
;     This file assembles to a static binary, without dependencies other than the Linux
;     syscalls (not using libc here).
;     The syscalls are performed through "INT 0x80" instead of through the SYSCALL 64bit instruction.
;     The Linux implementation of the INT 0x80 syscalls is 32 bits. Don't use INT 0x80 in 64-bit code
;     passing 64-bit pointers because those will be truncated.
;     The functions and calls in this file follow the 32bit cdecl calling convention.
;
;    -32-bit INT 0x80 syscall numbers are found in the following filesystem file (at least in a Ubuntu system):
;        /usr/include/x86_64-linux-gnu/asm/unistd_32.h
;
;    -According to the 32-bit cdecl calling convention:
;        1. Arguments are passed on the stack in RTL order (right to left).
;           That means that for calling myfunc(a, b, c), first 'c' is pushed, then 'b' then 'a'
;           then comes the call instruction. When the function executes, 'a' is at the top of the stack.
;        2. The caller is responsible for cleaning up the stack after the call, with an "add esp, <params size>".
;        3. Registers EAX, ECX and EDX can be overwritten by the called functions, but all other registers
;           must be preserved. Preserve: EBX, ESI, EDI, EBP.
;        4. The caller must align the stack to 16 byte boundaries before calls (that is only valid for modern
;           GCC and Linux, it used to be to 4 bytes before).
;     Aligning the stack is crucial only when calling GNU libc or calling code that uses SSE instructions
;     that load or store non scalar >= 128bit SSE types. Loading or storing scalar doubles is fine.
;
;    -The 32-bit syscalls receive the parameters in registers:
;        1. EAX for syscall_number.
;        2. EBX, ECX, EDX, ESI, EDI, EBP in that order for up to 6 parameters.
;        3. INT 0x80 should preserve all registers (except return value EAX of course).
;           In 64-bit context, INT 0x80 zeroes R8-R11.
;
;    -The functions and syscalls in this file don't require the stack pointer to be aligned to 16 byte
;     boundaries.
;     Linux 32-bit syscalls are prepared to receive an unaligned stack.
;


bits 32
section .text


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


;Count bytes until zero byte.
;Input: ARG1 string pointer
;Output: EAX length of the string, not counting the null terminator char.
;Used registers: EAX, ECX. Doesn't touch any other register.
getStringLength:
        mov ecx, [esp + 4]
        xor eax, eax                     ;Init counter to zero
getStringLength_loop:
        cmp byte [ecx + eax], 0          ;Test for the null-char terminator.
        jz getStringLength_end
        inc eax
        jmp getStringLength_loop
getStringLength_end:
        ret


;Takes a signed number and a buffer and returns the decimal (base10) representation
;in a null terminated string in the buffer.
;For 32-bit signed integers, a buffer of 12 bytes is enough for all possible values
;(10 chars for the number, 1 for the sign and 1 for the null terminator char).
;Input: ARG1 number.
;Input: ARG2 pointer to buffer with at least 12 bytes.
;Output: In ARG2 buffer. EAX holds length of string (not counting the null terminator char).
;Used registers: EAX, EBX, ECX, EDX, ESI, EDI. Preserved: EBX, ESI, EDI.
intToString:
        ;Prologue:
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi
        ;Init:
        mov eax, [ebp + 8]               ;EAX = ARG1 = Number to convert
        mov esi, [ebp + 0xc]             ;ESI = ARG2 = Destination buffer
        xor ecx, ecx                     ;ECX is buffer index
        xor ebx, ebx                     ;EBX is Negative flag
        mov edi, 10                      ;EDI is divisor 10 (DIV doesn't take an immediate arg)
        ;Check if input is negative:
        cmp eax, 0
        jge intToString_loop
        mov ebx, 1                       ;EBX = isNegative = 1
        neg eax                          ;Negate number to make it positive but same absolute value.
intToString_loop:
        ;Divide by 10 obtaining the digit as the modulus,
        ;until the result is less than 10:
        cmp eax, 0xa
        jb intToString_lastDigit
        xor edx, edx                     ;Divide EDX:EAX by 10. The next digit is the remainder.
        div edi                          ;EAX = quotient, EDX = remainder.
        ;Push digit:
        add edx, 0x30                    ;Convert digit to ACII char by adding 0x30 ('0' char code).
        mov byte [esi + ecx], dl         ;Push digit at the end of string buffer
        inc ecx
        jmp intToString_loop
intToString_lastDigit:
        ;Push last digit:
        add eax, 0x30                    ;Convert last digit to ACII char by adding 0x30 ('0' char code).
        mov byte [esi + ecx], al         ;Push last digit to the string.
        inc ecx
        ;Add '-' char if negative flag in R8:
        cmp ebx, 1
        jnz intToString_nonNegative
        mov byte [esi + ecx], 0x2d       ;Push '-' char
        inc ecx
intToString_nonNegative:
        mov byte [esi + ecx], 0          ;Push nul char terminator.
        ;Reverse string in buffer:
        push esi
        call reverseString
        add esp, 4
        ;Epilogue:
        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Reverse inplace the chars in a null terminated string.
;Input: ARG1 pointer to buffer.
;Output: Written in ARG1 buffer and EAX holds length of string.
;Used registers: EAX, ECX, EDX, ESI. Preserved: ESI.
reverseString:
        ;Prologue:
        push ebp
        mov ebp, esp
        push esi
        ;Compute length:
        push dword [ebp + 8]
        call getStringLength             ;EAX <- strlen
        add esp, 4
        ;Loop:
        mov esi, [ebp + 8]               ;ESI points to first char
        lea edx, [esi + eax - 1]         ;EDX points to last char
reverseString_loop:
        cmp esi, edx                     ;If the pointers cross, we already reversed the whole string.
        jae reverseString_end
        mov byte cl, [esi]               ;Swap [esi] with [edx]
        mov byte ch, [edx]
        mov byte [esi], ch
        mov byte [edx], cl
        inc esi                          ;Next char
        dec edx
        jmp reverseString_loop
reverseString_end:
        ;Epilogue:
        pop esi
        mov esp, ebp
        pop ebp
        ret


;Parse a null-terminated string to 32-bit int in base10.
;It never produces an error.
;Works almost exactly the same as C's atoi():
;
;      "1234"      -->  1234
;      "+1234"     -->  1234
;      "++1234"    -->  0
;      "-1234"     -->  -1234
;      "- 1234"    -->  0
;      "1234abc"   -->  1234
;      "1234ab33"  -->  1234
;      "12 3"      -->  12
;      "a12"       -->  0
;      " 12"       -->  12     (skips initial spaces)
;      "\t 12"     -->  12     (skips initial tabs)
;      "\t \t -12" -->  -12    (skips initial spaces/tabs)
;      "2147483647"       -->  2147483647   (max dword)
;      "2147483649"       -->  2147483647   (overflow. Returns max dword)
;      "10002147483647"   -->  2147483647   (overflow. Returns max dword)
;      "4294967296"       -->  2147483647   (overflow. Returns max dword)
;      "-2147483648"      -->  -2147483648  (min dword)
;      "-2147483649"      -->  -2147483648  (underflow. Returns min dword)
;      "-10002147483647"  -->  -2147483648  (underflow. Returns min dword)
;
;Input: ARG1 pointer to string.
;Output: EAX parsed integer.
;Used registers: EAX, EBX, ECX, EDX, ESI, EDI. Preserved: EBX, ESI, EDI.
stringToInt:
        ;Prologue:
        push ebp
        mov ebp, esp
        push ebx
        push esi
        push edi
        ;Init:
        xor eax, eax                     ;EAX is the result. Init to zero.
        xor ecx, ecx                     ;Lower byte of ECX is used for reading chars and the whole ECX for adding the digit.
        xor ebx, ebx                     ;EBX is sign flag. Set to zero meaning a positive number.
        mov edi, [ebp + 8]               ;EDI = ARG1
        ;Skip initial tabs and spaces:
stringToInt_skipBlanks:
        mov byte cl, [edi]
        cmp cl, 0x20                     ;Test for spaces (0x20) and tabs (9)
        jz stringToInt_isBlank
        cmp cl, 0x9
        jz stringToInt_isBlank
        jmp stringToInt_skipBlanksEnd
stringToInt_isBlank:
        inc edi
        jmp stringToInt_skipBlanks
stringToInt_skipBlanksEnd:
        ;Check minus or plus sign:
        mov byte cl, [edi]
        cmp cl, 0x2b                     ;Test for plus '+' (0x2b)
        jnz stringToInt_checkMinus
        inc edi                          ;Skip plus sign and start converting.
        jmp stringToInt_convert
stringToInt_checkMinus:
        cmp cl, 0x2d                     ;Test for minus '-' (0x2d)
        jnz stringToInt_convert
        mov ebx, 1                       ;Set sign flag to negative.
        inc edi                          ;Move past the '-' minus sign and start converting.
        ;Begin conversion:
stringToInt_convert:
        mov byte cl, [edi]
        cmp cl, 0x30
        jb stringToInt_convertEnd
        cmp cl, 0x39
        ja stringToInt_convertEnd
        ;Shift already read digits by multiplying by 10:
        xor edx, edx
        mov esi, 10                      ;IMUL must be used instead of MUL. Otherwise it doesn't flag overflow
        imul esi                         ;when it goes "negative" past the positive dword max.
        ;Check multiplication overflow:
        jo stringToInt_overflow
        ;Add new digit:
        sub cl, 0x30
        add eax, ecx
        ;Check addition overflow:
        cmp eax, 0x80000000              ;NOTE: CMP does allow 32 bits immediate operands (but not 64 bits imm in x86_64)
        jae stringToInt_overflow
        inc edi
        jmp stringToInt_convert
stringToInt_convertEnd:
        ;Negate result if we had a minus '-' sign in the string:
        cmp ebx, 1
        jnz stringToInt_end
        neg eax
        jmp stringToInt_end
stringToInt_overflow:
        ;Overflow/Underflow detected. Return max/min possible dword value:
        cmp ebx, 1
        jz stringToInt_overflow_negative
        mov eax, 0x7fffffff              ;Max positive dword.
        jmp stringToInt_end
stringToInt_overflow_negative:
        mov eax, 0x80000000              ;Min negative dword.
stringToInt_end:
        pop edi
        pop esi
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Prints a null-terminated string to STDOUT.
;Input: ARG1 pointer to string buffer.
;Output: EAX bytes written or -1 if error.
;Used Registers: EAX, EBX, ECX, EDX. Preserved: EBX.
printString:
        ;Prologue:
        push ebp
        mov ebp, esp
        push ebx
        ;Compute string length:
        push dword [ebp + 8]             ;ARG1 = string buffer
        call getStringLength             ;EAX <- string size
        add esp, 4
        ;Print:
        mov edx, eax                     ;EDX = size
        mov ecx, [ebp + 8]               ;ECX = string buffer
        mov eax, 4                       ;EAX = syscall write
        mov ebx, 1                       ;EBX = 1 (stdout)
        int 0x80                         ;syscall: EAX = 4 (WRITE), EBX = 1 (STDOUT), ECX = buffer, EDX = length
        ;Epilogue:
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Prints a null-terminated string to STDERR.
;Input: ARG1 pointer to string buffer.
;Output: EAX bytes written or -1 if error.
;Used Registers: EAX, EBX, ECX, EDX. Preserved: EBX.
printStringStderr:
        ;Prologue:
        push ebp
        mov ebp, esp
        push ebx
        ;Compute string length:
        push dword [ebp + 8]             ;ARG1 = string buffer
        call getStringLength             ;EAX <- string size
        add esp, 4
        ;Print:
        mov edx, eax                     ;EDX = size
        mov ecx, [ebp + 8]               ;ECX = string buffer
        mov eax, 4                       ;EAX = syscall write
        mov ebx, 2                       ;EBX = 2 (stderr)
        int 0x80                         ;syscall: EAX = 4 (WRITE), EBX = 2 (STDERR), ECX = buffer, EDX = length
        ;Epilogue:
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Prints a newline to STDOUT.
;Input: none
;Output: EAX bytes written or -1 if error.
;Used Registers: EAX, ECX, EDX.
printNewline:
        push dword printNewlineString
        call printString
        add esp, 4
        ret


;Prints a newline to STDERR.
;Input: none
;Output: EAX bytes written or -1 if error.
;Used Registers: EAX, ECX, EDX.
printNewlineStderr:
        push dword printNewlineString
        call printStringStderr
        add esp, 4
        ret


;Prints a 32-bit signed int to STDOUT.
;Input: ARG1 integer to print
;Output: EAX bytes written or -1 if error.
printInt:
        ;Local buffer in stack:
        printInt_numBuffer equ 12
        printInt_varsSize equ printInt_numBuffer
        ;Prologue:
        push ebp
        mov ebp, esp
        sub esp, printInt_varsSize
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        ;Convert to string:
        lea eax, [ebp - printInt_numBuffer]
        push eax                         ;ARG2 = local buffer
        push dword [ebp + 8]             ;ARG1 = our ARG1
        call intToString
        add esp, 8
        ;Print:
        lea eax, [ebp - printInt_numBuffer]
        push eax
        call printString
        add esp, 4
        ;Epilogue:
        mov esp, ebp
        pop ebp
        ret


;Sleep the specified number of milliseconds.
;Input: ARG1 number of milliseconds to sleep
;Output: EAX return value of nanosleep syscall.
;Used registers: EAX, EBX, ECX, EDX. Preserved: EBX.
sleepMillis:
        ;Local timespec struct in stack:
        sleepMillis_timespec equ 8
        sleepMillis_timespec_tv_sec equ 8
        sleepMillis_timespec_tv_nsec equ 4
        sleepMillis_varsSize equ sleepMillis_timespec
        ;Prologue:
        push ebp
        mov ebp, esp
        sub esp, sleepMillis_varsSize
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push ebx
        ;Divide by 1000 to get the seconds part:
        xor edx, edx
        mov eax, [ebp + 8]
        mov ecx, 1000                    ;1000 milliseconds in a second.
        idiv ecx                         ;Seconds in EAX. Remainder in EDX has milliseconds.
        mov [ebp - sleepMillis_timespec_tv_sec], eax
        ;Multiply the modulus (which is milliseconds between 0 and 999) by 1000000 to get the nanoseconds part:
        mov eax, edx
        xor edx, edx
        mov ecx, 1000000                 ;1000000 nanoseconds in a millisecond.
        imul ecx
        mov [ebp - sleepMillis_timespec_tv_nsec], eax
        ;nanosleep syscall:
        mov eax, 162
        lea ebx, [ebp - sleepMillis_timespec]
        xor ecx, ecx                     ;ECX = NULL for discarding remaining timespec.
        int 0x80                         ;syscall: EAX = 162 (nanosleep), EBX = *timespec (requested), ECX = *timespec or null (remaining)
        ;Epilogue:
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Returns the time in milliseconds since the epoch or some undetermined point in time,
;using the clock_gettime syscall.
;The C clock() function uses CLOCK_PROCESS_CPUTIME_ID in Linux, but that doesn't measure time
;spent in nanosleep() which could be useful for testing. Uncomment "mov ebx, CLOCK_MONOTONIC"
;to have that time measured.
;Input: none
;Output: EAX clock time in milliseconds.
;Used registers: EAX, EBX, ECX, EDX. Preserved: EBX.
clockMillis:
        ;Constants. Some possible clock types for clock_gettime:
        CLOCK_REALTIME equ 0
        CLOCK_MONOTONIC equ 1
        CLOCK_PROCESS_CPUTIME_ID equ 2
        ;Local timespec struct in stack:
        clockMillis_timespec equ 8
        clockMillis_timespec_tv_sec equ 8
        clockMillis_timespec_tv_nsec equ 4
        clockMillis_varsSize equ clockMillis_timespec
        ;Prologue:
        push ebp
        mov ebp, esp
        sub esp, clockMillis_varsSize
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push ebx
        ;clock_gettime syscall:
        mov eax, 265
        mov ebx, CLOCK_PROCESS_CPUTIME_ID
        ; mov ebx, CLOCK_MONOTONIC
        lea ecx, [ebp - clockMillis_timespec]
        int 0x80                         ;syscall: EAX = 265 (clock_gettime), EBX = clockid_t, ECX = *timespec (requested)
        ;Multiply seconds part by 1000 to get milliseconds:
        xor edx, edx
        mov eax, [ebp - clockMillis_timespec_tv_sec]
        mov ecx, 1000
        imul ecx
        ;Save to EBX:
        mov ebx, eax
        ;Divide nanoseconds part by 1000000 to get milliseconds:
        xor edx, edx
        mov eax, [ebp - clockMillis_timespec_tv_nsec]
        mov ecx, 1000000
        idiv ecx
        ;Add to EBX:
        add ebx, eax
        ;Returns milliseconds in EAX:
        mov eax, ebx
        ;Epilogue:
        pop ebx
        mov esp, ebp
        pop ebp
        ret


;Convert a dword number in milliseconds to a string in seconds with 3 fixed decimals.
;Examples:
;                    1   ->   "0.001"
;                 1234   ->   "1.234"
;                11100   ->   "11.100"
;           0x7fffffff   ->   "2147483.647"
;           0x80000000   ->   "-2147483.648"
;Input: ARG1 signed number in milliseconds.
;Input: ARG2 destination string buffer with at least 13 bytes (1 for the sign,
;       7 for the seconds, 1 for decimal dot, 3 for decimals, 1 for null char).
;Output: In destination ARG2 string.
;Used registers: EAX, ECX, EDX, ESI, EDI. Preserved: ESI, EDI.
formatMillisAsSeconds:
        formatMillisAsSeconds_dest equ 4
        formatMillisAsSeconds_secsPart equ formatMillisAsSeconds_dest + 4
        formatMillisAsSeconds_millisPart equ formatMillisAsSeconds_secsPart + 4
        formatMillisAsSeconds_secsPartString equ formatMillisAsSeconds_millisPart + 12
        formatMillisAsSeconds_millisPartString equ formatMillisAsSeconds_secsPartString + 12
        formatMillisAsSeconds_varsSize equ formatMillisAsSeconds_millisPartString
        ;Prologue
        push ebp
        mov ebp, esp
        sub esp, formatMillisAsSeconds_varsSize
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push esi
        push edi
        sub esp, 8                       ;Pad stack to a 16-byte boundary after pushes.
        ;Store destination string ptr to a variable:
        mov eax, [ebp + 0xc]
        mov [ebp - formatMillisAsSeconds_dest], eax
        ;Divide by 1000 to get Seconds as result and remaining Milliseconds as modulus.
        mov eax, [ebp + 8]
        cdq                              ;Sign extend EAX into EDX:EAX
        mov ecx, 1000
        idiv ecx
        ;Store secs part:
        mov [ebp - formatMillisAsSeconds_secsPart], eax
        ;ABS and store millis part:
        cmp edx, 0
        jge formatMillisAsSeconds_isPositive
        neg edx
formatMillisAsSeconds_isPositive:
        mov [ebp - formatMillisAsSeconds_millisPart], edx
        ;Convert seconds part to string:
        lea eax, [ebp - formatMillisAsSeconds_secsPartString]
        push eax
        push dword [ebp - formatMillisAsSeconds_secsPart]
        call intToString
        add esp, 8
        ;Convert milliseconds part to string:
        lea eax, [ebp - formatMillisAsSeconds_millisPartString]
        push eax
        push dword [ebp - formatMillisAsSeconds_millisPart]
        call intToString
        add esp, 8
        ;Copy seconds part to dest:
        lea eax, [ebp - formatMillisAsSeconds_secsPartString]
        push eax
        call getStringLength
        add esp, 4
        mov ecx, eax
        mov edi, [ebp - formatMillisAsSeconds_dest]
        lea esi, [ebp - formatMillisAsSeconds_secsPartString]
        cld                              ;Clear direction flag DF to copy forward.
        rep movsb ;[edi], [esi]          ;Move bytes from [ESI] to [EDI] until ECX is zero.
                                         ;ESI and EDI are left pointing at the first uncopied bytes
                                         ;(ESI points to the null terminator here).
        ;Add dot char:
        mov byte [edi], 0x2e             ;0x2e = 46 = Dot char in ASCII
        inc edi                          ;EDI which is pointing to the end of the dest string being built.
        ;Millis part length:
        lea eax, [ebp - formatMillisAsSeconds_millisPartString]
        push eax
        call getStringLength
        add esp, 4
        ;Left fill with zeros to complete 3 fixed decimals:
        mov ecx, 3
        sub ecx, eax
formatMillisAsSeconds_leftFillZeros:
        cmp ecx, 0
        jle formatMillisAsSeconds_leftFillZerosEnd
        mov byte [edi], 0x30             ;0x30 = 48 = '0' char in ASCII
        inc edi
        dec ecx
        jmp formatMillisAsSeconds_leftFillZeros
formatMillisAsSeconds_leftFillZerosEnd:
        ;Copy milliseconds part:
        mov ecx, eax                     ;EAX still has the length of millisPartString.
        lea esi, [ebp - formatMillisAsSeconds_millisPartString]
        cld
        rep movsb                        ;Move bytes from [ESI] to [EDI] until ECX is zero.
        ;Null terminator char:
        mov byte [edi], 0
        ;Epilogue:
        add esp, 8                       ;Undo padding of stack.
        pop edi
        pop esi
        mov esp, ebp
        pop ebp
        ret


;Pads a null terminated string inplace with spaces to the left, up to the char count specified in the second argument.
;Examples:
;       "abc", 6    ->   "   abc"
;       "abc", 3    ->   "abc"
;       "abc", -1   ->   "abc"
;Input: ARG1 buffer of string to pad. Its capacity must be at least the size of the second argument.
;Input: ARG2 length up to which to pad.
;Output: In ARG1 buffer. Otherwise none.
;Used registers: EAX, ECX, EDX, ESI, EDI. Preserves ESI, EDI.
padLeft:
        ;Prologue:
        push ebp
        mov ebp, esp
        push esi
        push edi
        ;Count how many padding chars to add:
        push dword [ebp + 8]
        call getStringLength             ;EAX = length of input string pointed by ARG1
        add esp, 4
        mov ecx, [ebp + 0xc]             ;ECX = ARG2
        sub ecx, eax                     ;ECX = count of padding chars to add
        cmp ecx, 0                       ;If input string is bigger than requested padding, do nothing (negative ECX)
        jle padLeft_end
        ;Shift chars in string (including null-char terminator) to make room at the beginning:
        mov edi, [ebp + 8]               ;EDI = ARG1 = string
        lea esi, [edi + ecx]             ;ESI = points to beginning of shifted string.
padLeft_shiftChars:
        cmp eax, 0                       ;Loop while EAX >= 0. It enters the loops at least once, for the null terminator.
        jl padLeft_shiftCharsEnd
        mov byte dl, [edi + eax]         ;Copy from the end towards the beginning.
        mov byte [esi + eax], dl
        dec eax
        jmp padLeft_shiftChars
padLeft_shiftCharsEnd:
        ;Fill room at the beginning with padding chars:
        xor eax, eax
padLeft_fillPadding:
        cmp eax, ecx
        jz padLeft_end
        mov byte [edi + eax], 0x20       ;0x20 = 32 = space in ASCII
        inc eax
        jmp padLeft_fillPadding
padLeft_end:
        ;Epilogue:
        pop edi
        pop esi
        mov esp, ebp
        pop ebp
        ret


;;Entry point of the whole program. Execution begins at _start
;;The command line arguments are present in the stack:
;;     -The first position contains the number of arguments.
;;     -The following positionss contain a pointer to a null-terminated string for each argument.
;;     -The last position contains a zero value.
global _start
_start:
        ;Stack layout:
        ;-8        ->  ;local var2 (dword sized)..
        ;-4        ->  ;local var1 (dword sized)
        ;+0 (ebp)  ->  ;old ebp
        ;+0x4      ->  ;argc
        ;+0x8      ->  ;arg0
        ;+0xc      ->  ;arg1
        ;+0x10     ->  ;arg2..
        ;Local vars offsets:
        start_argc equ 4
        start_n equ start_argc + 4
        start_count equ start_n + 4
        start_startTime equ start_count + 4
        start_endTime equ start_startTime + 4
        start_elapsed equ start_endTime + 4
        start_millisAsSecondsBuffer equ start_elapsed + 13
        start_varsSize equ start_millisAsSecondsBuffer
        ;Params offsets:
        start_PARAM_argc equ 4
        start_PARAM_arg0 equ 8
        start_PARAM_arg1 equ 0xc
        ;Prologue:
        push ebp
        mov ebp, esp
        sub esp, start_varsSize          ;Reserve space for local vars.
        ;Align stack:
        and esp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).

        ;Print usage banner if command line args are not exactly one:
        mov ecx, [ebp + start_PARAM_argc]
        cmp ecx, 2
        jz start_exactlyOneCommandLineArg
        ;Print usage banner:
        push dword usageBannerString1
        call printString
        add esp, 4
        push dword [ebp + start_PARAM_arg0]  ;Print ARGV0 as program name.
        call printString
        add esp, 4
        push dword usageBannerString2
        call printString
        add esp, 4
        call printNewline
        ;Exit program here with exit code 1:
        mov eax, 1
        mov ebx, 1
        int 0x80                         ;syscall: EAX = 1 (EXIT), EBX = 1 (exit code)
start_exactlyOneCommandLineArg:

        ;Parse command line argument to integer 'n':
        push dword [ebp + start_PARAM_arg1]
        call stringToInt
        add esp, 4
        mov [ebp - start_n], eax
        ;Validate 'n':
        cmp eax, 2                       ;n >= 2 ?
        jge start_nIsValid
start_nIsNotValid:
        ;Print error to STDERR and exit:
        push dword nNotValidError1
        call printStringStderr
        add esp, 4
        push dword [ebp + start_PARAM_arg1]
        call printStringStderr
        add esp, 4
        push dword nNotValidError2
        call printStringStderr
        add esp, 4
        ;Exit program here with exit code 1:
        mov eax, 1
        mov ebx, 1
        int 0x80                         ;syscall: EAX = 1 (EXIT), EBX = 1 (exit code)
start_nIsValid:

        ;Clock start
        call clockMillis
        mov [ebp - start_startTime], eax

        ;Find primes:
        push dword [ebp - start_n]
        call findPrimes
        ;call findPrimes_Simple
        add esp, 4
        mov [ebp - start_count], eax
        ;;Sleep for testing clockMillis():
        ;push dword 1033
        ;call sleepMillis
        ;add esp, 4

        ;Clock end
        call clockMillis
        mov [ebp - start_endTime], eax
        ;Compute elapsed:
        mov edx, [ebp - start_startTime]
        sub eax, edx                     ;EAX = endTime - startTime
        mov [ebp - start_elapsed], eax
        ;Print "Elapsed: ":
        push dword elapsedString1
        call printString
        add esp, 4
        ;Convert 'elapsed' milliseconds to string as seconds with 3 fixed decimals:
        lea eax, [ebp - start_millisAsSecondsBuffer]
        push eax
        push dword [ebp - start_elapsed]
        call formatMillisAsSeconds
        add esp, 8
        ;Pad with spaces up to 6 chars:
        push dword 6
        lea eax, [ebp - start_millisAsSecondsBuffer]
        push eax
        call padLeft
        add esp, 8
        ;Print time with 3 decimals and space padding up to 6 chars:
        lea eax, [ebp - start_millisAsSecondsBuffer]
        push eax
        call printString
        add esp, 4
        ;Print "s\n":
        push dword elapsedString2
        call printString
        add esp, 4

        ;Print count of primes found:
        push dword [ebp - start_count]
        call printInt
        add esp, 4
        push dword resultString
        call printString
        add esp, 4
        push dword [ebp - start_n]
        call printInt
        add esp, 4
        call printNewline

        ;Restore stack (not actually necessary here in _start)
        mov esp, ebp
        pop ebp
        ;Exit:
        mov eax, 1
        xor ebx, ebx
        int 0x80                         ;syscall: EAX = 1 (EXIT), EBX = 0 (exit code)


section .data
printNewlineString db 0xa, 0
usageBannerString1 db "Quick and dirty single thread CPU benchmark - by JMC", 0xa
                   db "Usage: ", 0xa
                   db "        Pass an argument up to which prime numbers will be searched with", 0xa
                   db "        an inefficient algorithm, useful to compare the single thread performance", 0xa
                   db "        of the CPU", 0xa
                   db "Example: ", 0xa
                   db "        "
                   db 0
usageBannerString2 db " 304500", 0xa
                   db "Notes: ", 0xa
                   db "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz", 0xa
                   db "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.", 0xa
                   db "        NASM-32bits: it takes 8.849s using NASM 2.13.01.", 0xa
                   db 0
nNotValidError1 db "ERROR: Argument '", 0
nNotValidError2 db "' not valid.", 0xa, 0
elapsedString1 db "Elapsed: ", 0
elapsedString2 db "s", 0xa, 0
resultString db " prime numbers were found between 2 and ", 0


