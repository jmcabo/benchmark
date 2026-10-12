$EMPTYVAR:;nasm -o "$0".o -felf64 "$0"  &&  ld -o benchmark "$0".o -m elf_x86_64  &&  exec -a "$0" ./benchmark $@ ;  exec /bin/false
;NOTE: For the shebang line to work well, the $EMPTYVAR variable must be empty or undefined.

;Benchmark in Assembly Language for NASM and 64-bit Linux (no libc) - by JMC
;
;
;Run:
;    ./benchmark.nasm.asm 304500
;Assemble and run:
;    nasm -o benchmark.o -felf64 benchmark.nasm.asm  &&  ld -o benchmark benchmark.o -m elf_x86_64  &&  ./benchmark 304500
;
;
;Notes:
;    -Assembly Language is an almost 1 to 1 mapping of machine code to mnemonics.
;     "MOV" is a mnemonic, and so is "EAX". But for the computer they are just numbers and bits
;     in an opcode when assembled to machine code. Since machine code is different for
;     each kind of CPU, assembly language will be different too. The 6502 8-bit microprocessor,
;     the Motorola 6800, the HP48's Saturn CPU, the ARM CPUs and the x86 Intel/AMD CPUs all have different
;     assembly languages for them.
;       The first assembly language was developed by Kathleen Booth in 1947. So in a sense
;     the assembly language "family" of programming languages is even older than Fortran and Lisp.
;       The x86 ASM was introduced with the Intel 8086 in 1978. And the 64 bit extensions of x86,
;     called x86-64 or AMD64 that I'm using in this file were introduced with the AMD Opteron in 2003
;     and used by Intel since the E0 revision of the Pentium 4 in 2004.
;
;    -NASM (The Netwide Assembler) is an x86 macro assembler that was first appeared in 1996. I always liked
;     its syntax better than GAS (the GNU Assembler) because it reminds me of TASM (Borland Turbo Assembler)
;     for MSDOS, which I used as a teenager.
;
;    -NASM (and also the old TASM) uses the Intel assembly syntax, while GAS uses the AT&T syntax.
;     With NASM you write "MOV EAX, 1" instead of "MOV $1, %EAX". The intel syntax is more natural
;     to me, having learned assembly in the MSDOS days. One can say that "MOV EAX, 1" looks more
;     like an assignment: "EAX = 1". While the GAS syntax "MOV $1, %EAX" looks more like a copy
;     to a destination: "copy 1 to EAX".
;
;    -Case is insensitive. One can write "mov rax, 1" or "MOV RAX, 1" and it works the same.
;     I prefer to code in lowercase and in comments to refer to code in uppercase (people do this
;     with Lisp too, but while I do it for emphasis, in Lisp they do it for historical reasons
;     and because the REPL prints code in uppercase, as the Common Lisp standard mandates).
;
;    -Hand written assembly code used to always be faster than compiled C code. That is no longer
;     always the case with complex optimizing compilers that can do things like automatically inline
;     functions and unroll loops and that have a model of the target CPU's execution units and
;     pipelines. Modern individual CPU cores can execute more than two instructions at the same time
;     if they don't depend on each other, and optimizing compilers can shuffle them for better
;     paralelization opportunities. Although even more modern CPUs can reorder instructions by themselves.
;     Also, compilers can align jump targets to 16 or 32 byte boundaries by filling with NOP
;     instructions for optimal access to the CPU instruction cache. But again, very modern CPUs are not
;     as sensible to that for small loops.
;
;    -The clever shebang line I made is convenient but not very secure. If $EMPTYVAR contains some
;     code, it will be executed.
;     It is clever because "$EMPTYVAR:;" means a label and a start of a comment in NASM, and also means
;     the NOP command (":" colon) in BASH and a next command (";" semi colon). In NASM, labels can start
;     with "$" dollar sign.
;     Replace "benchmark.o" and "benchmark" with "/tmp/benchmark.o" and "/tmp/benchmark" (or some other path)
;     if you don't want to leave output files lying around everywhere.
;
;    -This file is implemented in pure assembly without using libc or any other libraries, only syscalls.
;     The resulting binary is statically linked and has no dependencies.
;     Syscalls are direct calls to the OS (Linux). For 32-bit, syscalls are performed through the
;     "INT 0x80" interruption, and have a custom calling convention for passing arguments.
;     For 64-bit, syscalls are performed through the new "SYSCALL" instruction, and they use the
;     a convention similar but not equal to the standard 64-bit calling convention for passing arguments
;     (the fourth argument is R10 instead of RCX, so the arguments are: RDI, RSI, RDX, R10, R8 AND R9,
;     and syscalls in Linux clobber RAX, RCX and R11, other registers are preserved).
;     Since I'm targetting 64-bit Linux in this file, I'm using "SYSCALL" for syscalls.
;
;    -According to the calling convention for 64bits in Unix:
;        1. First 6 arguments in these registers in this order: RDI, RSI, RDX, RCX, R8, R9
;        2. Extra arguments go in the stack.
;        3. These registers must be preserved by the called function in 64-bit Linux: RBX, RBP, R12-R15, RSP
;           all others can be used as scratch registers, including all the XMM/YMM/ZMM registers.
;        4. The stack must be aligned to 16-byte boundaries before calls.
;     I'm not sure whether 64-bit syscalls require the stack to be aligned to 16 bytes, but I align it
;     just in case to maximize compatibility (for 64 bits).
;
;    -Since I'm not using libc, the entry point is not main(), there is no main(). Instead, the entry
;     point is "_start" (which is the actual entry point of libc before libc calls main()).
;     Linux calls _start with the command line arguments ready in the stack but without EIP or RIP
;     in the stack. There is no return pointer.
;       The first position in the stack is the number of command line arguments, and in the rest of the
;     positions are the pointers to null terminated strings for each argument. The last position is a
;     null pointer to mark the end of the arguments.
;
;    -In the original C version in "benchmark.c" I used ints (32-bit integers) so I'm also using
;     32-bit registers here for findPrimes(). If I used 64-bit registers and the 64bit IDIV instruction,
;     it would take 3 times as much. It's easy to see: just replace IDIV ECX by IDIV RCX and see the
;     time difference. (see "Instruction Tables by Agner Fog" with instruction timings online for IDIV
;     r32 and r64).
;     Also, with my CPU, DIV is slower than IDIV (again: try replacing IDIV ECX by DIV ECX).
;
;    -The two loops in findPrimes() don't perform any memory accesses (outside of the initial PUSH RBX) and
;     do everything using only registers.
;
;    -The trick of jumping to the loop guard before the first iteration, and locating the loop guard
;     at the end of the loop, saves one unconditional JMP instruction in the loop body of findPrimes().
;     The effect is about 1 second saved for n=304500 with my laptop Intel Ivy Bridge CPU, but surprisingly
;     gives zero gains with my desktop Intel Haswell CPU (try by uncommenting "call findPrimes_Simple")
;
;    -I tried aligning the loops in findPrimes with NOPs but with my CPU it didn't make a speed difference.
;     It seems modern CPUs are more robust against unaligned small loops.
;
;    -This assembly file doesn't use libc. That means that I had to write the following helper functions:
;         clockMillis, formatMillisAsSeconds, getStringLength, intToString, padLeft, printInt,
;         printNewline, printString, printStringStderr, reverseString, sleepMillis, stringToInt.
;     They are well tested and they can be reused.
;
;
;Limitations:
;    -There is no syscall to print a float or convert a float to string. That is why I chose to
;     have the 'elapsed' variable as an integer in milliseconds (instead of a float in seconds),
;     and to format it directly to a string in seconds with 3 fixed decimals instead of formatting
;     a float to string. Converting a float number to string is tricky to do right, and VERY easy to do
;     wrong.
;     See this for more information, about the Dragon4 and Grisu algorithms for converting floats
;     to strings:
;         "Here be dragons: advances in problems you didn’t even know you had" - by Bryan O'Sullivan - 2011
;         http://www.serpentine.com/blog/2011/06/29/here-be-dragons-advances-in-problems-you-didnt-even-know-you-had/
;     The correct algorithms are big and require arbitrary precision integer routines (even the Grisu
;     algorithms require them as a fallback for the numbers in which they fail), which is beyond the scope
;     of this simple file.
;
;
;Tips:
;    -To disassemble a binary in Linux:
;         objdump -D -M intel mybinary > mybinary.objdump.asm
;     or
;         ndisasm -b64 mybinary > mybinary.ndisasm.asm
;     Note that objdump does a better job with labels and symbols than ndisasm.
;
;    -The following macros are useful to align the target of a jump manually, with the minimal number of
;     individual instructions. Obtained from:
;         "Long nop instructions in nasm" - Answer by BeeOnRope - 2018
;         https://stackoverflow.com/questions/48245362/long-nop-instructions-in-nasm;
;     Macros for Multibyte NOPs:
;            %define nop1 nop                                                     ;    NOP
;            %define nop2 db 0x66, 0x90                                           ; 66 NOP
;            %define nop3 db 0x0f, 0x1f, 0x00                                     ;    NOP DWORD ptr [EAX]
;            %define nop4 db 0x0f, 0x1f, 0x40, 0x00                               ;    NOP DWORD ptr [EAX + 00H]
;            %define nop5 db 0x0f, 0x1f, 0x44, 0x00, 0x00                         ;    NOP DWORD ptr [EAX + EAX*1 + 00H]
;            %define nop6 db 0x66, 0x0f, 0x1f, 0x44, 0x00, 0x00                   ; 66 NOP DWORD ptr [EAX + EAX*1 + 00H]
;            %define nop7 db 0x0f, 0x1f, 0x80, 0x00, 0x00, 0x00, 0x00             ;    NOP DWORD ptr [EAX + 00000000H]
;            %define nop8 db 0x0f, 0x1f, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00       ;    NOP DWORD ptr [EAX + EAX*1 + 00000000H]
;            %define nop9 db 0x66, 0x0f, 0x1f, 0x84, 0x00, 0x00, 0x00, 0x00, 0x00 ; 66 NOP DWORD ptr [EAX + EAX*1 + 00000000H]
;     The 'align 16' command in NASM only fills with single byte 0x90 NOPs. And some of the multibyte
;     nops have to be entered by db with NASM. Hence these macros.
;
;
;Useful links:
;    "NASM Tutorial" - by Ray Toal (LMU)
;    http://cs.lmu.edu/~ray/notes/nasmtutorial/
;
;    "Linux System Call Table for x86 64" - 2012
;    http://blog.rchapman.org/posts/Linux_System_Call_Table_for_x86_64/
;
;    For the documentation of Linux syscalls see the man pages.
;    For instance: "man write" or "man clock_gettime".
;    http://man7.org/linux/man-pages/dir_section_2.html
;    https://linux.die.net/man/2/
;
;    64-bit Calling Convention for Linux: "System V AMD64 ABI" - Wikipedia
;    https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI
;
;    "System V Application Binary Interface AMD64 Architecture Processor Supplement" Draft V0.3 - 2013
;    https://software.intel.com/sites/default/files/article/402129/mpx-linux64-abi.pdf
;
;    "Norton Guide - Intel iAPx86 Instruction Set. Compiled October 1996"
;    http://www.ousob.com/ng/iapx86/ng2e5.php
;
;    "Norton Guide - Assembly Language" - 1987
;    http://www.ousob.com/ng/asm/ng47c.php
;
;    "Instruction Tables By Agner Fog" (clock cycles, timings) - 2018
;    https://www.agner.org/optimize/instruction_tables.pdf
;
;    x86 Resources Collected by StackOverflow.com users:
;    https://stackoverflow.com/tags/x86/info
;


bits 64
section .text


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


;Count bytes until zero byte.
;Input: RDI string pointer
;Output: RAX length of the string, not counting the null terminator char.
;Used registers: RAX. Preservers RDI. Doesn't touch any other register.
getStringLength:
        xor rax, rax                     ;Init counter to zero
getStringLength_loop:
        cmp byte [rdi + rax], 0          ;Test for the null-char terminator.
        jz getStringLength_end
        inc rax
        jmp getStringLength_loop
getStringLength_end:
        ret


;Takes a signed number and a buffer and returns the decimal (base10) representation
;in a null terminated string in the buffer.
;For 64-bit signed integers, a buffer of 21 bytes is enough for all possible values
;(19 chars for the number, 1 for the sign and 1 for the null terminator char).
;Input: RDI number.
;Input: RSI pointer to buffer with at least 21 bytes.
;Output: In RSI buffer. RAX holds length of string (not counting the null terminator char).
;Used registers: RAX, RDI, RSI, RDX, RCX, R8
intToString:
        mov rax, rdi                     ;RAX = RDI = Number to convert (First argument)
                                         ;RSI = Destination buffer (Second argument)
        xor rcx, rcx                     ;RCX is buffer index
        xor r8, r8                       ;R8 is Negative flag
        mov rdi, 10                      ;RDI is divisor 10 (DIV doesn't take an immediate arg)
        ;Check if input is negative:
        cmp rax, 0
        jge intToString_loop
        mov r8, 1                        ;R8 = isNegative = 1
        neg rax                          ;Negate number to make it positive but same absolute value.
intToString_loop:
        ;Divide by 10 obtaining the digit as the modulus,
        ;until the result is less than 10:
        cmp rax, 0xa
        jb intToString_lastDigit
        xor rdx, rdx                     ;Divide RDX:RAX by 10. The next digit is the remainder.
        div rdi                          ;RAX = quotient, RDX = remainder.
        ;Push digit:
        add rdx, 0x30                    ;Convert digit to ACII char by adding 0x30 ('0' char code).
        mov byte [rsi + rcx], dl         ;Push digit at the end of string buffer
        inc rcx
        jmp intToString_loop
intToString_lastDigit:
        ;Push last digit:
        add rax, 0x30                    ;Convert last digit to ACII char by adding 0x30 ('0' char code).
        mov byte [rsi + rcx], al         ;Push last digit to the string.
        inc rcx
        ;Add '-' char if negative flag in R8:
        cmp r8, 1
        jnz intToString_nonNegative
        mov byte [rsi + rcx], 0x2d       ;Push '-' char
        inc rcx
intToString_nonNegative:
        mov byte [rsi + rcx], 0          ;Push nul char terminator.
        ;Reverse string in buffer:
        mov rdi, rsi
        call reverseString
        ret


;Reverse inplace the chars in a null terminated string.
;Input RDI pointer to buffer.
;Output: Written in RDI buffer and RAX holds length of string.
;Registers: Uses RAX, RCX, RDX and RSI. Preserves RDI.
reverseString:
        call getStringLength             ;RAX <- strlen
        mov rsi, rdi                     ;RSI points to first char
        lea rdx, [rdi + rax - 1]         ;RDX points to last char
reverseString_loop:
        cmp rsi, rdx                     ;If the pointers cross, we already reversed the whole string.
        jae reverseString_end
        mov byte cl, [rsi]               ;Swap [rsi] with [rdx]
        mov byte ch, [rdx]
        mov byte [rsi], ch
        mov byte [rdx], cl
        inc rsi                          ;Next char
        dec rdx
        jmp reverseString_loop
reverseString_end:
        ret


;Parse a null-terminated string to 64-bit int in base10.
;It never produces an error.
;Works exactly the same as C's atol():
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
;      "9223372036854775807"       -->  9223372036854775807   (max quad word)
;      "9223372036854775809"       -->  9223372036854775807   (overflow. Returns max quad word)
;      "10009223372036854775807"   -->  9223372036854775807   (overflow. Returns max quad word)
;      "18446744073709551616"      -->  9223372036854775807   (overflow. Returns max quad word)
;      "-9223372036854775808"      -->  -9223372036854775808  (min quad word)
;      "-9223372036854775809"      -->  -9223372036854775808  (underflow. Returns min quad word)
;      "-10009223372036854775807"  -->  -9223372036854775808  (underflow. Returns min quad word)
;
;Input: RDI pointer to string.
;Output: RAX parsed integer. RDI is moved to point past the last digit processed.
;Used registers: RAX, RDI, RSI, RDX, RCX, R8
stringToInt:
        xor rax, rax                     ;RAX is the result. Init to zero.
        xor rcx, rcx                     ;Lower byte of RCX is used for reading chars and the whole RCX for adding the digit.
        xor r8, r8                       ;R8 is sign flag. Set to zero meaning a positive number.
        ;Skip initial tabs and spaces:
stringToInt_skipBlanks:
        mov byte cl, [rdi]
        cmp cl, 0x20                     ;Test for spaces (0x20) and tabs (9)
        jz stringToInt_isBlank
        cmp cl, 0x9
        jz stringToInt_isBlank
        jmp stringToInt_skipBlanksEnd
stringToInt_isBlank:
        inc rdi
        jmp stringToInt_skipBlanks
stringToInt_skipBlanksEnd:
        ;Check minus or plus sign:
        mov byte cl, [rdi]
        cmp cl, 0x2b                     ;Test for plus '+' (0x2b)
        jnz stringToInt_checkMinus
        inc rdi                          ;Skip plus sign and start converting.
        jmp stringToInt_convert
stringToInt_checkMinus:
        cmp cl, 0x2d                     ;Test for minus '-' (0x2d)
        jnz stringToInt_convert
        mov r8, 1                        ;Set sign flag to negative.
        inc rdi                          ;Move past the '-' minus sign and start converting.
        ;Begin conversion:
stringToInt_convert:
        mov byte cl, [rdi]
        cmp cl, 0x30
        jb stringToInt_convertEnd
        cmp cl, 0x39
        ja stringToInt_convertEnd
        ;Shift already read digits by multiplying by 10:
        xor rdx, rdx
        mov rsi, 10                      ;IMUL must be used instead of MUL. Otherwise it doesn't flag overflow
        imul rsi                         ;when it goes "negative" past the positive quad word max.
        ;Check multiplication overflow:
        jo stringToInt_overflow
        ;Add new digit:
        sub cl, 0x30
        add rax, rcx
        ;Check addition overflow:
        mov rdx, 0x8000000000000000      ;NOTE: CMP doesn't seem to allow quad word immediates.
        cmp rax, rdx
        jae stringToInt_overflow
        inc rdi
        jmp stringToInt_convert
stringToInt_convertEnd:
        ;Negate result if we had a minus '-' sign in the string:
        cmp r8, 1
        jnz stringToInt_end
        neg rax
        jmp stringToInt_end
stringToInt_overflow:
        ;Overflow/Underflow detected. Return max/min possible quad word value:
        cmp r8, 1
        jz stringToInt_overflow_negative
        mov rax, 0x7fffffffffffffff      ;Max positive quad word.
        jmp stringToInt_end
stringToInt_overflow_negative:
        mov rax, 0x8000000000000000      ;Min negative quad word.
stringToInt_end:
        ret


;Prints a null-terminated string to STDOUT.
;Input: RDI pointer to string buffer.
;Output: RAX bytes written or -1 if error.
;Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printString:
        push rbp
        mov rbp, rsp
        ;(if stack was aligned before the call, it is aligned again after pushing RBP over RIP,
        ;no need for "AND RSP, -16" for the syscall)
        call getStringLength             ;RAX <- string size
        mov rdx, rax                     ;RDX = size
        mov rsi, rdi                     ;RSI = string buffer
        mov rax, 1                       ;RAX = syscall write
        mov rdi, 1                       ;RDI = 1 (stdout)
        syscall                          ;syscall: RAX = 1 (WRITE), RDI = 1 (STDOUT), RSI = buffer, RDX = length
        mov rsp, rbp
        pop rbp
        ret


;Prints a null-terminated string to STDERR.
;Input: RDI pointer to string buffer.
;Output: RAX bytes written or -1 if error.
;Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printStringStderr:
        push rbp
        mov rbp, rsp
        ;(if stack was aligned before the call, it is aligned again after pushing RBP over RIP,
        ;no need for "AND RSP, -16" for the syscall)
        call getStringLength             ;RAX <- string size
        mov rdx, rax                     ;RDX = size
        mov rsi, rdi                     ;RSI = string buffer
        mov rax, 1                       ;RAX = syscall write
        mov rdi, 2                       ;RDI = 2 (stderr)
        syscall                          ;syscall: RAX = 1 (WRITE), RDI = 2 (STDERR), RSI = buffer, RDX = length
        mov rsp, rbp
        pop rbp
        ret


;Prints a newline to STDOUT.
;Input: none
;Output: RAX bytes written or -1 if error.
;Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printNewline:
        mov rdi, printNewlineString
        call printString
        ret


;Prints a newline to STDERR.
;Input: none
;Output: RAX bytes written or -1 if error.
;Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printNewlineStderr:
        mov rdi, printNewlineString
        call printStringStderr
        ret


;Prints a 64-bit signed int to STDOUT.
;Input: RDI integer to print
;Output: RAX bytes written or -1 if error.
printInt:
        ;Local buffer in stack:
        printInt_numBuffer equ 21
        printInt_varsSize equ printInt_numBuffer
        ;Prologue:
        push rbp
        mov rbp, rsp
        sub rsp, printInt_varsSize
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        ;Convert to string:
        lea rsi, [rbp - printInt_numBuffer]
        call intToString
        ;Print:
        lea rdi, [rbp - printInt_numBuffer]
        call printString
        ;Epilogue:
        mov rsp, rbp
        pop rbp
        ret


;Sleep the specified number of milliseconds.
;Input: RDI number of milliseconds to sleep
;Output: RAX return value of nanosleep syscall.
;Used Registers: RAX, RDI, RSI, RDX, RCX. And also 'syscall' clobbers RCX and R11 in Linux.
sleepMillis:
        ;Local timespec struct in stack:
        sleepMillis_timespec equ 16
        sleepMillis_timespec_tv_sec equ 16
        sleepMillis_timespec_tv_nsec equ 8
        sleepMillis_varsSize equ sleepMillis_timespec
        ;Prologue:
        push rbp
        mov rbp, rsp
        sub rsp, sleepMillis_varsSize
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        ;Divide by 1000 to get the seconds part:
        xor rdx, rdx
        mov rax, rdi
        mov rcx, 1000                    ;1000 milliseconds in a second.
        idiv rcx                         ;Seconds in RAX. Remainder in RDX has milliseconds.
        mov [rbp - sleepMillis_timespec_tv_sec], rax
        ;Multiply the modulus (which is milliseconds between 0 and 999) by 1000000 to get the nanoseconds part:
        mov rax, rdx
        xor rdx, rdx
        mov rcx, 1000000                 ;1000000 nanoseconds in a millisecond.
        imul rcx
        mov [rbp - sleepMillis_timespec_tv_nsec], rax
        ;nanosleep syscall:
        mov rax, 35
        lea rdi, [rbp - sleepMillis_timespec]
        xor rsi, rsi                     ;RSI = NULL for discarding remaining timespec.
        syscall                          ;syscall: RAX = 35 (nanosleep), RDI = *timespec (requested), RSI = *timespec or null (remaining)
        mov rsp, rbp
        pop rbp
        ret


;Returns the time in milliseconds since the epoch or some undetermined point in time,
;using the clock_gettime syscall.
;The C clock() function uses CLOCK_PROCESS_CPUTIME_ID in Linux, but that doesn't measure time
;spent in nanosleep() which could be useful for testing. Uncomment "mov rdi, CLOCK_MONOTONIC"
;to have that time measured.
;Input: none
;Output: RAX clock time in milliseconds.
;Used Registers: RAX, RDI, RSI, RDX, RCX. And also 'syscall' clobbers RCX and R11 in Linux.
clockMillis:
        ;Constants. Some possible clock types for clock_gettime:
        CLOCK_REALTIME equ 0
        CLOCK_MONOTONIC equ 1
        CLOCK_PROCESS_CPUTIME_ID equ 2
        ;Local timespec struct in stack:
        clockMillis_timespec equ 16
        clockMillis_timespec_tv_sec equ 16
        clockMillis_timespec_tv_nsec equ 8
        clockMillis_varsSize equ clockMillis_timespec
        ;Prologue:
        push rbp
        mov rbp, rsp
        sub rsp, clockMillis_varsSize
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        ;clock_gettime syscall:
        mov rax, 228
        mov rdi, CLOCK_PROCESS_CPUTIME_ID
        ; mov rdi, CLOCK_MONOTONIC
        lea rsi, [rbp - clockMillis_timespec]
        syscall                          ;syscall: RAX = 228 (clock_gettime), RDI = clockid_t, RSI = *timespec (requested)
        ;Multiply seconds part by 1000 to get milliseconds:
        xor rdx, rdx
        mov rax, [rbp - clockMillis_timespec_tv_sec]
        mov rcx, 1000
        imul rcx
        ;Save to RDI:
        mov rdi, rax
        ;Divide nanoseconds part by 1000000 to get milliseconds:
        xor rdx, rdx
        mov rax, [rbp - clockMillis_timespec_tv_nsec]
        mov rcx, 1000000
        idiv rcx
        ;Add to RDI:
        add rdi, rax
        ;Returns milliseconds in RAX:
        mov rax, rdi
        mov rsp, rbp
        pop rbp
        ret


;Convert a quad word number in milliseconds to a string in seconds with 3 fixed decimals.
;Examples:
;                    1   ->   "0.001"
;                 1234   ->   "1.234"
;                11100   ->   "11.100"
;   0x7fffffffffffffff   ->   "9223372036854775.807"
;   0x8000000000000000   ->   "-9223372036854775.808"
;Input: RDI signed number in milliseconds.
;Input: RSI destination string buffer with at least 22 bytes (1 for the sign,
;       16 for the seconds, 1 for decimal dot, 3 for decimals, 1 for null char).
;Output: In destination RSI string.
;Used registers: RAX, RDI, RSI, RDX, RCX. RBX is preserved.
formatMillisAsSeconds:
        formatMillisAsSeconds_dest equ 8
        formatMillisAsSeconds_secsPart equ formatMillisAsSeconds_dest + 8
        formatMillisAsSeconds_millisPart equ formatMillisAsSeconds_secsPart + 8
        formatMillisAsSeconds_secsPartString equ formatMillisAsSeconds_millisPart + 21
        formatMillisAsSeconds_millisPartString equ formatMillisAsSeconds_secsPartString + 21
        formatMillisAsSeconds_varsSize equ formatMillisAsSeconds_millisPartString
        ;Prologue
        push rbp
        mov rbp, rsp
        sub rsp, formatMillisAsSeconds_varsSize
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push rbx
        sub rsp, 8                       ;Pad stack to a 16-byte boundary after pushes.
        ;Store destination string ptr to a variable:
        mov [rbp - formatMillisAsSeconds_dest], rsi
        ;Divide by 1000 to get Seconds as result and remaining Milliseconds as modulus.
        mov rax, rdi
        cqo                              ;Sign extend RAX into RDX:RAX
        mov rcx, 1000
        idiv rcx
        ;Store secs part:
        mov [rbp - formatMillisAsSeconds_secsPart], rax
        ;ABS and store millis part:
        cmp rdx, 0
        jge formatMillisAsSeconds_isPositive
        neg rdx
formatMillisAsSeconds_isPositive:
        mov [rbp - formatMillisAsSeconds_millisPart], rdx
        ;Convert seconds part to string:
        mov rdi, [rbp - formatMillisAsSeconds_secsPart]
        lea rsi, [rbp - formatMillisAsSeconds_secsPartString]
        call intToString
        ;Convert milliseconds part to string:
        mov rdi, [rbp - formatMillisAsSeconds_millisPart]
        lea rsi, [rbp - formatMillisAsSeconds_millisPartString]
        call intToString
        ;Copy seconds part to dest:
        lea rdi, [rbp - formatMillisAsSeconds_secsPartString]
        call getStringLength
        mov rcx, rax
        mov rdi, [rbp - formatMillisAsSeconds_dest]
        lea rsi, [rbp - formatMillisAsSeconds_secsPartString]
        cld                              ;Clear direction flag DF to copy forward.
        rep movsb ;[rdi], [rsi]          ;Move bytes from [RSI] to [RDI] until RCX is zero.
                                         ;RSI and RDI are left pointing at the first uncopied bytes
                                         ;(RSI points to the null terminator here).
        ;Add dot char:
        mov byte [rdi], 0x2e             ;0x2e = 46 = Dot char in ASCII
        inc rdi
        ;Millis part length:
        mov rbx, rdi                     ;Save RDI which is pointing to the end of the dest string being built.
        lea rdi, [rbp - formatMillisAsSeconds_millisPartString]
        call getStringLength
        mov rdi, rbx
        ;Left fill with zeros to complete 3 fixed decimals:
        mov rcx, 3
        sub rcx, rax
formatMillisAsSeconds_leftFillZeros:
        cmp rcx, 0
        jle formatMillisAsSeconds_leftFillZerosEnd
        mov byte [rdi], 0x30             ;0x30 = 48 = '0' char in ASCII
        inc rdi
        dec rcx
        jmp formatMillisAsSeconds_leftFillZeros
formatMillisAsSeconds_leftFillZerosEnd:
        ;Copy milliseconds part:
        mov rcx, rax                     ;RAX still has the length of millisPartString.
        lea rsi, [rbp - formatMillisAsSeconds_millisPartString]
        cld
        rep movsb                        ;Move bytes from [RSI] to [RDI] until RCX is zero.
        ;Null terminator char:
        mov byte [rdi], 0
        ;Epilogue:
        add rsp, 8                       ;Undo padding of stack.
        pop rbx
        mov rsp, rbp
        pop rbp
        ret


;Pads a null terminated string inplace with spaces to the left, up to the char count specified in the second argument.
;Examples:
;       "abc", 6    ->   "   abc"
;       "abc", 3    ->   "abc"
;       "abc", -1   ->   "abc"
;Input: RDI buffer of string to pad. Its capacity must be at least the size of the second argument.
;Input: RSI length up to which to pad.
;Output: In RDI buffer. Otherwise none.
;Used registers: RAX, RDI, RSI, RDX, RCX
padLeft:
        ;Count how many padding chars to add:
        call getStringLength             ;RAX = length of input string pointed by RDI
        mov rcx, rsi
        sub rcx, rax                     ;RCX = count of padding chars to add
        cmp rcx, 0                       ;If input string is bigger than requested padding, do nothing (negative RCX)
        jle padLeft_end
        ;Shift chars in string (including null-char terminator) to make room at the beginning:
        lea rsi, [rdi + rcx]             ;RSI = points to beginning of shifted string.
padLeft_shiftChars:
        cmp rax, 0                       ;Loop while RAX >= 0. It enters the loops at least once, for the null terminator.
        jl padLeft_shiftCharsEnd
        mov byte dl, [rdi + rax]         ;Copy from the end towards the beginning.
        mov byte [rsi + rax], dl
        dec rax
        jmp padLeft_shiftChars
padLeft_shiftCharsEnd:
        ;Fill room at the beginning with padding chars:
        xor rax, rax
padLeft_fillPadding:
        cmp rax, rcx
        jz padLeft_end
        mov byte [rdi + rax], 0x20       ;0x20 = 32 = space in ASCII
        inc rax
        jmp padLeft_fillPadding
padLeft_end:
        ret


;Entry point of the whole program. Execution begins at _start
;The command line arguments are present in the stack:
;     -The first position contains the number of arguments.
;     -The following positionss contain a pointer to a null-terminated string for each argument.
;     -The last position contains a zero value.
global _start
_start:
        ;Stack layout:
        ;-0x10     ->  ;local var2 (quad word sized)..
        ;-8        ->  ;local var1 (quad word sized)
        ;+0 (rbp)  ->  ;old rbp
        ;+0x8      ->  ;argc
        ;+0x10     ->  ;arg0
        ;+0x18     ->  ;arg1
        ;+0x20     ->  ;arg2..
        ;Local vars offsets:
        start_argc equ 8
        start_n equ start_argc + 8
        start_count equ start_n + 8
        start_startTime equ start_count + 8
        start_endTime equ start_startTime + 8
        start_elapsed equ start_endTime + 8
        start_millisAsSecondsBuffer equ start_elapsed + 22
        start_varsSize equ start_millisAsSecondsBuffer
        ;Params offsets:
        start_PARAM_argc equ 8
        start_PARAM_arg0 equ 0x10
        start_PARAM_arg1 equ 0x18
        ;Prologue:
        push rbp
        mov rbp, rsp
        sub rsp, start_varsSize          ;Reserve space for local vars.
        ;Align stack:
        and rsp, -16                     ;Align stack to a 16-byte boundary (-16 is 0xff..ff0).

        ;Print usage banner if command line args are not exactly one:
        mov rcx, [rbp + start_PARAM_argc]
        cmp rcx, 2
        jz start_exactlyOneCommandLineArg
        ;Print usage banner:
        mov rdi, usageBannerString1
        call printString
        mov rdi, [rbp + start_PARAM_arg0]  ;Print ARGV0 as program name.
        call printString
        mov rdi, usageBannerString2
        call printString
        call printNewline
        ;Exit program here with exit code 1:
        mov rax, 60
        mov rdi, 1
        syscall                          ;syscall: RAX = 60 (EXIT), RDI = 1 (exit code)
start_exactlyOneCommandLineArg:

        ;Parse command line argument to integer 'n':
        mov rdi, [rbp + start_PARAM_arg1]
        call stringToInt
        mov [rbp - start_n], rax
        ;Validate 'n':
        cmp rax, 2                       ;n < 2 ?
        jl start_nIsNotValid
        cmp rax, 0x7fffffff              ;n > max positive 32bit integer
        jg start_nIsNotValid
        jmp start_nIsValid
start_nIsNotValid:
        ;Print error to STDERR and exit:
        mov rdi, nNotValidError1
        call printStringStderr
        mov rdi, [rbp + start_PARAM_arg1]
        call printStringStderr
        mov rdi, nNotValidError2
        call printStringStderr
        ;Exit program here with exit code 1:
        mov rax, 60
        mov rdi, 1
        syscall                          ;syscall: RAX = 60 (EXIT), RDI = 1 (exit code)
start_nIsValid:

        ;Clock start
        call clockMillis
        mov [rbp - start_startTime], rax

        ;Find primes:
        mov rdi, [rbp - start_n]
        call findPrimes
        ;call findPrimes_Simple
        mov [rbp - start_count], rax
        ;;Sleep for testing clockMillis():
        ;mov rdi, 1033
        ;call sleepMillis

        ;Clock end
        call clockMillis
        mov [rbp - start_endTime], rax
        ;Compute elapsed:
        mov rdx, [rbp - start_startTime]
        sub rax, rdx                     ;RAX = endTime - startTime
        mov [rbp - start_elapsed], rax
        ;Print "Elapsed: ":
        mov rdi, elapsedString1
        call printString
        ;Convert 'elapsed' milliseconds to string as seconds with 3 fixed decimals:
        mov rdi, [rbp - start_elapsed]
        lea rsi, [rbp - start_millisAsSecondsBuffer]
        call formatMillisAsSeconds
        ;Pad with spaces up to 6 chars:
        lea rdi, [rbp - start_millisAsSecondsBuffer]
        mov rsi, 6
        call padLeft
        ;Print time with 3 decimals and space padding up to 6 chars:
        lea rdi, [rbp - start_millisAsSecondsBuffer]
        call printString
        ;Print "s\n":
        mov rdi, elapsedString2
        call printString

        ;Print count of primes found:
        mov rdi, [rbp - start_count]
        call printInt
        mov rdi, resultString
        call printString
        mov rdi, [rbp - start_n]
        call printInt
        call printNewline

        ;Restore stack (not actually necessary here in _start)
        mov rsp, rbp
        pop rbp
        ;Exit:
        mov rax, 60
        mov rdi, 0
        syscall                          ;syscall: RAX = 60 (EXIT), RDI = 0 (exit code)


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
                   db "        NASM: it takes 8.849s using NASM 2.13.01.", 0xa
                   db 0
nNotValidError1 db "ERROR: Argument '", 0
nNotValidError2 db "' not valid.", 0xa, 0
elapsedString1 db "Elapsed: ", 0
elapsedString2 db "s", 0xa, 0
resultString db " prime numbers were found between 2 and ", 0


