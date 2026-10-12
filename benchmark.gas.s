//bin/true  ;  gcc -c -o "$0".o "$0"  &&  ld -o benchmark "$0".o  &&  exec -a "$0" ./benchmark "$@"  ;  exec /bin/false
# vim: filetype=gas:

#Benchmark in Assembly Language for GAS (GNU Assembler) and 64-bit Linux (no libc) - by JMC
#
#
#Run:
#    ./benchmark.gas.s 304500
#Assemble and run:
#    gcc -c -o benchmark.o benchmark.gas.s  &&  ld -o benchmark benchmark.o  &&  ./benchmark 304500
#The same but using 'as':
#    as -o benchmark.o benchmark.gas.s  &&  ld -o benchmark benchmark.o  &&  ./benchmark 304500
#
#
#Notes:
#    -See "benchmark.nasm.asm" for more notes about Assembly.
#
#    -And again, see "benchmark.nasm.asm" for the same code but written for NASM.
#
#    -This file doesn't use libc, and produces a static binary with no dependencies.
#     It uses syscalls and custom functions instead of libc.
#     Since the binary is static, it doesn't support PIE and the global vars and calls are not
#     relative to RIP or to a PLT (Procedure Linkage Table).
#
#    -If editing with VIM, it is highly recommended to get the following "gas.vim" syntax
#     highlighting file and put it in "/etc/vim/syntax/gas.vim":
#            https://www.vim.org/scripts/script.php?script_id=2863
#            https://github.com/Shirk/vim-gas
#     Then put "vim: ft=gas:" in a comment at the top or the bottom of the edited file.
#
#    -This file is written for GAS, the GNU Assembler. The Assembly syntax is very different
#     from NASM. GAS uses the AT&T assembly syntax. Compared to the Intel syntax, the order
#     of some operands is reversed so that the destination register or memory location is
#     at the right hand side. Memory addressing has a different syntax too. Registers names are
#     prefixed by the "%" sign. Immediate values have to always be prefixed by the "$" sign.
#     See the "Linux assemblers: A comparison of GAS and NASM" for more detailed comparisons,
#     in the useful links section.
#
#    -The GAS syntax (AT&T syntax) comes from the DEC PDP-11 assembler syntax. Unix was born at
#     AT&T on the PDP-11 in the 70s. It predates Intel processors. The PDP-11 assembler used
#     the "%" sign for registers, and the "#" sign for immediates (but "$" was chosen for
#     the AT&T Unix assembler syntax since "#" was a control character for the terminal driver).
#     See:
#        https://stackoverflow.com/questions/4193827/questions-about-att-x86-syntax-design/4194571#4194571
#
#    -Some examples showing how weird the GAS AT&T addressing is:
#           Intel style                         GAS style
#           -----------                         ---------
#           mov esi, [esi]                -->   mov (%rsi), %rsi
#           mov eax, [rbp - 8]            -->   mov -8(%rbp), %eax
#           lea rdx, [rbp - myvar]        -->   lea -myvar(%rbp), %rdx
#           cmp byte [rdi + rax], 0       -->   cmpb $0, (%rdi, %rax, 1)
#           mov rax, [rdx + rsi * 4]      -->   mov (%rdx, %rsi, 4), %eax
#           mov [mytable + rdi * 4], rax  -->   mov %eax, mytable( , %rdi, 4)
#
#    -Instead of specifying "dword" or "quad" when the size of the operand isn't clear in the
#     context, the size is specified as part of the instruction name:
#           mov byte [rsi], 0   -->   movb $0, (%rsi)
#     The suffixes can be: b, w, l, q.
#
#
#Tips:
#    -To disassemble a binary to GAS AT&T syntax style in Linux:
#         objdump -D mybinary > mybinary.objdump.s
#
#
#Useful links:
#    "GNU Assembler Examples" - by Ray Toal (LMU)
#    http://cs.lmu.edu/~ray/notes/gasexamples/
#
#    "Linux assemblers: A comparison of GAS and NASM" - by Ram Narayan - 2007
#    https://www.ibm.com/developerworks/library/l-gas-nasm/index.html
#
#    (see "benchmark.nasm.asm" for more links)
#


.text


#NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
#that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
#but puts the function in a loop and counts 10000 calls).
#Returns how many prime numbers exist between 2 and n:
#
#Input: RDI 32-bit positive number.
#Output: RAX count of primes <= number.
#Used registers: RAX, RBX, RDI, RSI, RDX, RCX. RBX and RDI are preserved.
findPrimes:
        push %rbx                        #Save RBX. The 64-bit calling convention says RBX must be preserved.
                                         #With the push of RBX over RIP, the stack is aligned to 16 bytes.
                                         #Not really needed though in a leaf function.
        xor %esi, %esi                   #ESI is count. Init to zero.
        #For each number up to 'n':
        #Loop i from 2 to n:
        mov $2, %ebx                     #EBX is i
        jmp findPrimes_loopI_guard
findPrimes_loopI:
        #Loop j from 2 to below i:
        mov $2, %ecx                     #ECX is j
        jmp findPrimes_loopJ_guard
findPrimes_loopJ:
        #Compute modulus between EBX and ECX. IDIV stores the modulus (actually remainder) in EDX:
        mov %ebx, %eax
        cdq
        idiv %ecx                        #EDX = EBX % ECX
        test %edx, %edx                  #If i divisible by j, it wasn't a prime number:
        jz findPrimes_notPrime           #Break
        inc %ecx                         #j += 1
findPrimes_loopJ_guard:
        #Check if j < i:
        cmp %ebx, %ecx                   #NOT using the sqrt optimization (for easier benchmarking).
        jl findPrimes_loopJ
findPrimes_loopJEnd:
        #The previous loop ended without divisors found. It is a prime number:
        inc %esi                         #count += 1
findPrimes_notPrime:
        inc %ebx                         #i += 1
findPrimes_loopI_guard:
        #Check if i <= n:
        cmp %edi, %ebx
        jle findPrimes_loopI
findPrimes_loopIEnd:
        mov %esi, %eax                   #RAX = count  ("MOV EAX, *", zeroes high part of RAX)
        pop %rbx
        ret


#Simple straightforward version that maps better to the C loops, without the trick of
#removing the unconditional jump from the repeatable part of both loops, and without
#breaking the loop straight to incrementing 'count'. In my Ivy Bridge laptop it is
#10% slower, but in my Haswell desktop CPU it has practically the same speed.
#
#Input: RDI 32-bit positive number.
#Output: RAX count of primes <= number.
#Used registers: RAX, RBX, RDI, RSI, RDX, RCX. RBX and RDI are preserved.
findPrimes_Simple:
        push %rbx                        #Save RBX. The 64-bit calling convention says RBX must be preserved.
                                         #With the push of RBX over RIP, the stack is aligned to 16 bytes.
                                         #Not really needed though in a leaf function.
        xor %esi, %esi                   #ESI is count. Init to zero.
        #For each number up to 'n':
        #Loop i from 2 to n:
        mov $2, %ebx                     #EBX is i
findPrimes_Simple_loopI:
        #Check if i <= n:
        cmp %edi, %ebx
        jg findPrimes_Simple_end
        #Loop j from 2 to below i:
        mov $2, %ecx                     #ECX is j
findPrimes_Simple_loopJ:
        #Check if j < i:
        cmp %ebx, %ecx
        jge findPrimes_Simple_loopJEnd
        #Compute modulus between EBX and ECX. IDIV stores the modulus (actually remainder) in EDX:
        mov %ebx, %eax
        cdq
        idiv %ecx                        #EDX = EBX % ECX
        test %edx, %edx                  #If i divisible by j, it wasn't a prime number:
        jz findPrimes_Simple_loopJEnd    #Break
        inc %ecx                         #j += 1
        jmp findPrimes_Simple_loopJ
findPrimes_Simple_loopJEnd:
        #Check if i == j. If it is, the loop ended without breaking.
        cmp %ecx, %ebx
        jnz findPrimes_Simple_notPrime
        #The previous loop ended without divisors found. It is a prime number:
        inc %esi                         #count += 1
findPrimes_Simple_notPrime:
        inc %ebx                         #i += 1
        jmp findPrimes_Simple_loopI
findPrimes_Simple_end:
        mov %esi, %eax                   #RAX = count  ("MOV EAX, *", zeroes high part of RAX)
        pop %rbx
        ret


#Count bytes until zero byte.
#Input: RDI string pointer
#Output: RAX length of the string, not counting the null terminator char.
#Used registers: RAX. Preservers RDI. Doesn't touch any other register.
getStringLength:
        xor %rax, %rax                   #Init counter to zero
getStringLength_loop:
        cmpb $0, (%rdi,%rax)             #Test for the null-char terminator.
        jz getStringLength_end
        inc %rax
        jmp getStringLength_loop
getStringLength_end:
        ret


#Takes a signed number and a buffer and returns the decimal (base10) representation
#in a null terminated string in the buffer.
#For 64-bit signed integers, a buffer of 21 bytes is enough for all possible values
#(19 chars for the number, 1 for the sign and 1 for the null terminator char).
#Input: RDI number.
#Input: RSI pointer to buffer with at least 21 bytes.
#Output: In RSI buffer. RAX holds length of string (not counting the null terminator char).
#Used registers: RAX, RDI, RSI, RDX, RCX, R8
longToString:
        mov %rdi, %rax                   #RAX = RDI = Number to convert (First argument)
                                         #RSI = Destination buffer (Second argument)
        xor %rcx, %rcx                   #RCX is buffer index
        xor %r8, %r8                     #R8 is Negative flag
        mov $10, %rdi                    #RDI is divisor 10 (DIV doesn't take an immediate arg)
        #Check if input is negative:
        cmp $0, %rax
        jge longToString_loop
        mov $1, %r8                      #R8 = isNegative = 1
        neg %rax                         #Negate number to make it positive but same absolute value.
longToString_loop:
        #Divide by 10 obtaining the digit as the modulus,
        #until the result is less than 10:
        cmp $0xa, %rax
        jb longToString_lastDigit
        xor %rdx, %rdx                   #Divide RDX:RAX by 10. The next digit is the remainder.
        div %rdi                         #RAX = quotient, RDX = remainder.
        #Push digit:
        add $0x30, %rdx                  #Convert digit to ACII char by adding 0x30 ('0' char code).
        mov %dl, (%rsi,%rcx)             #Push digit at the end of string buffer
        inc %rcx
        jmp longToString_loop
longToString_lastDigit:
        #Push last digit:
        add $0x30, %rax                  #Convert last digit to ACII char by adding 0x30 ('0' char code).
        mov %al, (%rsi,%rcx)             #Push last digit to the string.
        inc %rcx
        #Add '-' char if negative flag in R8:
        cmp $1, %r8
        jnz longToString_nonNegative
        movb $0x2d, (%rsi,%rcx)          #Push '-' char
        inc %rcx
longToString_nonNegative:
        movb $0, (%rsi,%rcx)             #Push nul char terminator.
        #Reverse string in buffer:
        mov %rsi, %rdi
        call reverseString
        ret


#Reverse inplace the chars in a null terminated string.
#Input RDI pointer to buffer.
#Output: Written in RDI buffer and RAX holds length of string.
#Registers: Uses RAX, RCX, RDX and RSI. Preserves RDI.
reverseString:
        call getStringLength             #RAX <- strlen
        mov %rdi, %rsi                   #RSI points to first char
        lea -1(%rdi,%rax), %rdx          #RDX points to last char
reverseString_loop:
        cmp %rdx, %rsi                   #If the pointers cross, we already reversed the whole string.
        jae reverseString_end
        mov (%rsi), %cl                  #Swap [rsi] with [rdx]
        mov (%rdx), %ch
        mov %ch, (%rsi)
        mov %cl, (%rdx)
        inc %rsi                         #Next char
        dec %rdx
        jmp reverseString_loop
reverseString_end:
        ret


#Parse a null-terminated string to 64-bit int in base10.
#It never produces an error. That is why parseInt() is better.
#Works exactly the same as C's atol():
#
#      "1234"      -->  1234
#      "+1234"     -->  1234
#      "++1234"    -->  0
#      "-1234"     -->  -1234
#      "- 1234"    -->  0
#      "1234abc"   -->  1234
#      "1234ab33"  -->  1234
#      "12 3"      -->  12
#      "a12"       -->  0
#      " 12"       -->  12     (skips initial spaces)
#      "\t 12"     -->  12     (skips initial tabs)
#      "\t \t -12" -->  -12    (skips initial spaces/tabs)
#      "9223372036854775807"       -->  9223372036854775807   (max quad word)
#      "9223372036854775809"       -->  9223372036854775807   (overflow. Returns max quad word)
#      "10009223372036854775807"   -->  9223372036854775807   (overflow. Returns max quad word)
#      "18446744073709551616"      -->  9223372036854775807   (overflow. Returns max quad word)
#      "-9223372036854775808"      -->  -9223372036854775808  (min quad word)
#      "-9223372036854775809"      -->  -9223372036854775808  (underflow. Returns min quad word)
#      "-10009223372036854775807"  -->  -9223372036854775808  (underflow. Returns min quad word)
#
#Input: RDI pointer to string.
#Output: RAX parsed integer. RDI is moved to point past the last digit processed.
#Used registers: RAX, RDI, RSI, RDX, RCX, R8
stringToLong:
        xor %rax, %rax                   #RAX is the result. Init to zero.
        xor %rcx, %rcx                   #Lower byte of RCX is used for reading chars and the whole RCX for adding the digit.
        xor %r8, %r8                     #R8 is sign flag. Set to zero meaning a positive number.
        #Skip initial tabs and spaces:
stringToLong_skipBlanks:
        mov (%rdi), %cl
        cmp $0x20, %cl                   #Test for spaces (0x20) and tabs (9)
        jz stringToLong_isBlank
        cmp $0x9, %cl
        jz stringToLong_isBlank
        jmp stringToLong_skipBlanksEnd
stringToLong_isBlank:
        inc %rdi
        jmp stringToLong_skipBlanks
stringToLong_skipBlanksEnd:
        #Check minus or plus sign:
        mov (%rdi), %cl
        cmp $0x2b, %cl                   #Test for plus '+' (0x2b)
        jnz stringToLong_checkMinus
        inc %rdi                         #Skip plus sign and start converting.
        jmp stringToLong_convert
stringToLong_checkMinus:
        cmp $0x2d, %cl                   #Test for minus '-' (0x2d)
        jnz stringToLong_convert
        mov $1, %r8                      #Set sign flag to negative.
        inc %rdi                         #Move past the '-' minus sign and start converting.
        #Begin conversion:
stringToLong_convert:
        mov (%rdi), %cl
        cmp $0x30, %cl
        jb stringToLong_convertEnd
        cmp $0x39, %cl
        ja stringToLong_convertEnd
        #Shift already read digits by multiplying by 10:
        xor %rdx, %rdx
        mov $10, %rsi                    #IMUL must be used instead of MUL. Otherwise it doesn't flag overflow
        imul %rsi                        #when it goes "negative" past the positive quad word max.
        #Check multiplication overflow:
        jo stringToLong_overflow
        #Add new digit:
        sub $0x30, %cl
        add %rcx, %rax
        #Check addition overflow:
        mov $0x8000000000000000, %rdx    #NOTE: CMP doesn't seem to allow quad word immediates.
        cmp %rdx, %rax
        jae stringToLong_overflow
        inc %rdi
        jmp stringToLong_convert
stringToLong_convertEnd:
        #Negate result if we had a minus '-' sign in the string:
        cmp $1, %r8
        jnz stringToLong_end
        neg %rax
        jmp stringToLong_end
stringToLong_overflow:
        #Overflow/Underflow detected. Return max/min possible quad word value:
        cmp $1, %r8
        jz stringToLong_overflow_negative
        mov $0x7fffffffffffffff, %rax    #Max positive quad word.
        jmp stringToLong_end
stringToLong_overflow_negative:
        mov $0x8000000000000000, %rax    #Min negative quad word.
stringToLong_end:
        ret


#Parses a 32-bit int from a string in base 10, from scratch, with no dependencies.
#
#Returns the number and sets parseOk == 1 if the string represents a valid int. Returns 0 and sets
#parseOk == 0 if the string is non numeric ("abc", "", " ", "a12" and "+" are considered non numeric).
#When the value underflows, INT_MIN is returned and parseOk is set to 0.
#When the value overflows, INT_MAX is returned and parseOk is set to 0.
#
#When 'junkAllowed' is non-zero, it allows extra non numeric chars and non space or tab chars after
#the number (example: "123a"). Otherwise returns 0 and sets parseOk to 0 in that case.
#
#Spaces at the beginning or end are always allowed no matter the value of 'junkAllowed', as in " 123 ".
#
#The variable parseOk can be NULL if the caller is not interested in it.
#
#Notes:
#    -The standard C functions atoi() and sscanf() produce undefined behaviour if the number in
#     the string is between INT_MAX and LONG_MAX in x86-x64 Linux, and they both always allow "junk"
#     after the number. In glibc, atoi() is equivalent to casting strtol() from long to int and ignoring
#     'end', which is wrong when sizeof(int) < sizeof(long) but it is allowed by the standard.
#    -Example: atoi("4294967419") returns 123 in 64-bit Linux, where an int is 4 bytes and a long is 8.
#    -This function fixes those issues, parsing an int from scratch.
#    -Also, all three standard functions, atoi, sscanf and strtol allow spaces at the beginning, but if we
#     were to use strtol and only check end != s && end != '\0' as strtol's man page suggests, we would
#     introduce the asymmetry of not allowing spaces at the end.
#    -The CommonLisp 'parse-integer' function always allows spaces at the end and has a ':junk-allowed'
#     argument, so parseInt is similar in those ways.
#
#Input: RDI pointer to null terminated string to parse.
#Input: ESI 32-bit junkAllowed. Pass 0 for strict parsing, 1 to allow non numeric chars after the digits.
#Input: RDX pointer to 32-bit parseOk or NULL. It will receive 0 if there was an error, or 1 if
#       parsing was successful.
#Output: EAX parsed 32-bit integer.
#Output: 32-bit int pointed to by parseOk. Sets it to 1 if all OK, or 0 if the string doesn't represent
#        a 32-bit base 10 integer value.
#Used registers: RAX, RBX, RDI, RSI, RDX, RCX. RBX is preserved.
parseInt:
        .equ parseInt_junkAllowed, 4
        .equ parseInt_parseOk, parseInt_junkAllowed + 8
        .equ parseInt_didParseSomething, parseInt_parseOk + 4
        .equ parseInt_overflow, parseInt_didParseSomething + 4
        .equ parseInt_varsSize, parseInt_overflow
        #Prologue
        push %rbp
        mov %rsp, %rbp
        sub $parseInt_varsSize, %rsp
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push %rbx
        sub $8, %rsp                     #Pad stack to a 16-byte boundary after pushes.
        #Save args to vars:
        mov %esi, -parseInt_junkAllowed(%rbp)
        mov %rdx, -parseInt_parseOk(%rbp)
        #Init:
        xor %rax, %rax                   #EAX is the result. Init to zero.
        xor %rcx, %rcx                   #Lower byte of RCX is used for reading chars and ECX for adding the digit.
        xor %rbx, %rbx                   #RBX is the sign flag. Set to zero meaning a positive number.
        movl $0, -parseInt_didParseSomething(%rbp)  #Flag that indicates if there were any digits parsed.
        movl $0, -parseInt_overflow(%rbp)  #Flag that indicates if overflow/underflow was detected.

        #Skip initial tabs and spaces:
parseInt_skipBlanks:
        mov (%rdi), %cl
        cmp $0x20, %cl                   #Test for spaces (0x20) and tabs (9)
        jz parseInt_isBlank
        cmp $0x9, %cl
        jz parseInt_isBlank
        jmp parseInt_skipBlanksEnd
parseInt_isBlank:
        inc %rdi
        jmp parseInt_skipBlanks
parseInt_skipBlanksEnd:

        #Read optional sign:
        mov (%rdi), %cl
        cmp $0x2b, %cl                   #Test for plus '+' (0x2b)
        jnz parseInt_checkMinus
        inc %rdi                         #Skip plus sign and start converting.
        jmp parseInt_convert
parseInt_checkMinus:
        cmp $0x2d, %cl                   #Test for minus '-' (0x2d)
        jnz parseInt_convert
        mov $1, %rbx                     #Set sign flag to negative.
        inc %rdi                         #Move past the '-' minus sign and start converting.

        #Begin conversion:
parseInt_convert:
        mov (%rdi), %cl
        cmp $0x30, %cl
        jb parseInt_convertEnd
        cmp $0x39, %cl
        ja parseInt_convertEnd
        #Parsing at least one decimal digit, set the flag:
        movl $1, -parseInt_didParseSomething(%rbp)
        #Shift already read digits by multiplying by 10:
        xor %rdx, %rdx
        mov $10, %esi                    #IMUL must be used instead of MUL. Otherwise it doesn't flag overflow
        imul %esi                        #when it goes "negative" past the positive dword max.
        #Check multiplication overflow with JNO:
        jno parseInt_noMultiplicationOverflow
        movl $1, -parseInt_overflow(%rbp)
        jmp parseInt_convertEnd
parseInt_noMultiplicationOverflow:
        #Add new digit:
        sub $0x30, %cl
        add %ecx, %eax
        #Check addition overflow:
        #(can't check with JO/JNO because 0x80...00 is a valid value when sign==1)
        #if ((sign && r > (unsigned) INT_MAX + 1U) || (!sign && r > (unsigned) INT_MAX)) { ..overflow.. }
        test %rbx, %rbx
        jz parseInt_checkAddPositiveOverflow
        cmp $0x80000000, %eax
        ja parseInt_addOverflow
        jmp parseInt_checkEnd
parseInt_checkAddPositiveOverflow:
        cmp $0x7fffffff, %eax
        ja parseInt_addOverflow
        jmp parseInt_checkEnd
parseInt_addOverflow:
        movl $1, -parseInt_overflow(%rbp)
        jmp parseInt_convertEnd
parseInt_checkEnd:
        inc %rdi
        jmp parseInt_convert
parseInt_convertEnd:

        #Skip remaining digits after overflow detected. If the string ends with non numeric chars,
        #that error has priority over overflow (ie: return 0 instead of MAX or MIN).
        cmpl $0, -parseInt_overflow(%rbp)
        jz parseInt_skipRemainingDigitsEnd
parseInt_skipRemainingDigits:
        mov (%rdi), %cl
        cmp $0x30, %cl
        jb parseInt_skipRemainingDigitsEnd
        cmp $0x39, %cl
        ja parseInt_skipRemainingDigitsEnd
        inc %rdi
        jmp parseInt_skipRemainingDigits
parseInt_skipRemainingDigitsEnd:

        #Skip spaces to see if the string is well formed, ie: would match this regex /^\s*[+-]\?[0-9]\+\s*$/
parseInt_skipBlanks2:
        mov (%rdi), %cl
        cmp $0x20, %cl                   #Test for spaces (0x20) and tabs (9)
        jz parseInt_isBlank2
        cmp $0x9, %cl
        jz parseInt_isBlank2
        jmp parseInt_skipBlanksEnd2
parseInt_isBlank2:
        inc %rdi
        jmp parseInt_skipBlanks2
parseInt_skipBlanksEnd2:

        #Validate ending:
        cmpl $0, -parseInt_didParseSomething(%rbp)
        jz parseInt_notValid
        cmpb $0, (%rdi)
        jz parseInt_valid
        cmpl $0, -parseInt_junkAllowed(%rbp)
        jz parseInt_notValid
        jmp parseInt_valid
parseInt_notValid:
        #Set *parseOk = 0:
        mov -parseInt_parseOk(%rbp), %rcx
        test %rcx, %rcx
        jz parseInt_skipParseOk1
        movl $0, (%rcx)
parseInt_skipParseOk1:
        xor %rax, %rax
        jmp parseInt_end
parseInt_valid:

        #Overflow / Underflow:
        cmpl $0, -parseInt_overflow(%rbp)
        jz parseInt_success
        #Overflow/Underflow detected. Return max/min possible dword value:
        #Set *parseOk = 0:
        mov -parseInt_parseOk(%rbp), %rcx
        test %rcx, %rcx
        jz parseInt_skipParseOk2
        movl $0, (%rcx)
parseInt_skipParseOk2:
        #Return MAX or MIN according to parsed sign:
        cmp $1, %rbx
        jz parseInt_overflow_negative
        mov $0x7fffffff, %eax            #Max positive dword.
        jmp parseInt_end
parseInt_overflow_negative:
        mov $0x80000000, %eax            #Min negative dword.
        jmp parseInt_end

        #Success:
parseInt_success:
        #Set *parseOk = 1:
        mov -parseInt_parseOk(%rbp), %rcx
        test %rcx, %rcx
        jz parseInt_skipParseOk3
        movl $1, (%rcx)
parseInt_skipParseOk3:
        #Negate result if we had a minus '-' sign in the string:
        cmp $1, %rbx
        jnz parseInt_end
        neg %eax

parseInt_end:
        #Epilogue:
        add $8, %rsp                     #Undo padding of stack.
        pop %rbx
        mov %rbp, %rsp
        pop %rbp
        ret


#Prints a null-terminated string to STDOUT.
#Input: RDI pointer to string buffer.
#Output: RAX bytes written or -1 if error.
#Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printString:
        push %rbp
        mov %rsp, %rbp
        #(if stack was aligned before the call, it is aligned again after pushing RBP over RIP,
        #no need for "AND RSP, -16" for the syscall)
        call getStringLength             #RAX <- string size
        mov %rax, %rdx                   #RDX = size
        mov %rdi, %rsi                   #RSI = string buffer
        mov $1, %rax                     #RAX = syscall write
        mov $1, %rdi                     #RDI = 1 (stdout)
        syscall                          #syscall: RAX = 1 (WRITE), RDI = 1 (STDOUT), RSI = buffer, RDX = length
        mov %rbp, %rsp
        pop %rbp
        ret


#Prints a null-terminated string to STDERR.
#Input: RDI pointer to string buffer.
#Output: RAX bytes written or -1 if error.
#Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printStringStderr:
        push %rbp
        mov %rsp, %rbp
        #(if stack was aligned before the call, it is aligned again after pushing RBP over RIP,
        #no need for "AND RSP, -16" for the syscall)
        call getStringLength             #RAX <- string size
        mov %rax, %rdx                   #RDX = size
        mov %rdi, %rsi                   #RSI = string buffer
        mov $1, %rax                     #RAX = syscall write
        mov $2, %rdi                     #RDI = 2 (stderr)
        syscall                          #syscall: RAX = 1 (WRITE), RDI = 2 (STDERR), RSI = buffer, RDX = length
        mov %rbp, %rsp
        pop %rbp
        ret


#Prints a newline to STDOUT.
#Input: none
#Output: RAX bytes written or -1 if error.
#Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printNewline:
        mov $printNewlineString, %rdi
        call printString
        ret


#Prints a newline to STDERR.
#Input: none
#Output: RAX bytes written or -1 if error.
#Used Registers: RAX, RDI, RSI, RDX. And also 'syscall' clobbers RCX and R11 in Linux.
printNewlineStderr:
        mov $printNewlineString, %rdi
        call printStringStderr
        ret


#Prints a 64-bit signed int to STDOUT.
#Input: RDI integer to print
#Output: RAX bytes written or -1 if error.
printLong:
        #Local buffer in stack:
        .equ printLong_numBuffer, 21
        .equ printLong_varsSize, printLong_numBuffer
        #Prologue:
        push %rbp
        mov %rsp, %rbp
        sub $printLong_varsSize, %rsp
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        #Convert to string:
        lea -printLong_numBuffer(%rbp), %rsi
        call longToString
        #Print:
        lea -printLong_numBuffer(%rbp), %rdi
        call printString
        #Epilogue:
        mov %rbp, %rsp
        pop %rbp
        ret


#Prints a 32-bit signed int to STDOUT.
#Input: EDI integer to print
#Output: RAX bytes written or -1 if error.
printInt:
        #Sign-extend to 64-bit:
        movsxd %edi, %rax
        mov %rax, %rdi
        #Print:
        call printLong
        ret


#Sleep the specified number of milliseconds.
#Input: RDI number of milliseconds to sleep
#Output: RAX return value of nanosleep syscall.
#Used Registers: RAX, RDI, RSI, RDX, RCX. And also 'syscall' clobbers RCX and R11 in Linux.
sleepMillis:
        #Local timespec struct in stack:
        .equ sleepMillis_timespec, 16
        .equ sleepMillis_timespec_tv_sec, 16
        .equ sleepMillis_timespec_tv_nsec, 8
        .equ sleepMillis_varsSize, sleepMillis_timespec
        #Prologue:
        push %rbp
        mov %rsp, %rbp
        sub $sleepMillis_varsSize, %rsp
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        #Divide by 1000 to get the seconds part:
        xor %rdx, %rdx
        mov %rdi, %rax
        mov $1000, %rcx                  #1000 milliseconds in a second.
        idiv %rcx                        #Seconds in RAX. Remainder in RDX has milliseconds.
        mov %rax, -sleepMillis_timespec_tv_sec(%rbp)
        #Multiply the modulus (which is milliseconds between 0 and 999) by 1000000 to get the nanoseconds part:
        mov %rdx, %rax
        xor %rdx, %rdx
        mov $1000000, %rcx               #1000000 nanoseconds in a millisecond.
        imul %rcx
        mov %rax, -sleepMillis_timespec_tv_nsec(%rbp)
        #nanosleep syscall:
        mov $35, %rax
        lea -sleepMillis_timespec(%rbp), %rdi
        xor %rsi, %rsi                   #RSI = NULL for discarding remaining timespec.
        syscall                          #syscall: RAX = 35 (nanosleep), RDI = *timespec (requested), RSI = *timespec or null (remaining)
        mov %rbp, %rsp
        pop %rbp
        ret


#Returns the time in milliseconds since the epoch or some undetermined point in time,
#using the clock_gettime syscall.
#The C clock() function uses CLOCK_PROCESS_CPUTIME_ID in Linux, but that doesn't measure time
#spent in nanosleep() which could be useful for testing. Uncomment "mov $CLOCK_PROCESS_CPUTIME_ID, %rdi"
#to use the same clock as the C clock() function.
#Input: none
#Output: RAX clock time in milliseconds.
#Used Registers: RAX, RDI, RSI, RDX, RCX. And also 'syscall' clobbers RCX and R11 in Linux.
clockMillis:
        #Constants. Some possible clock types for clock_gettime:
        .equ CLOCK_REALTIME, 0
        .equ CLOCK_MONOTONIC, 1
        .equ CLOCK_PROCESS_CPUTIME_ID, 2
        #Local timespec struct in stack:
        .equ clockMillis_timespec, 16
        .equ clockMillis_timespec_tv_sec, 16
        .equ clockMillis_timespec_tv_nsec, 8
        .equ clockMillis_varsSize, clockMillis_timespec
        #Prologue:
        push %rbp
        mov %rsp, %rbp
        sub $clockMillis_varsSize, %rsp
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        #clock_gettime syscall:
        mov $228, %rax
        mov $CLOCK_MONOTONIC, %rdi
        # mov $CLOCK_PROCESS_CPUTIME_ID, %rdi
        lea -clockMillis_timespec(%rbp), %rsi
        syscall                          #syscall: RAX = 228 (clock_gettime), RDI = clockid_t, RSI = *timespec (requested)
        #Multiply seconds part by 1000 to get milliseconds:
        xor %rdx, %rdx
        mov -clockMillis_timespec_tv_sec(%rbp), %rax
        mov $1000, %rcx
        imul %rcx
        #Save to RDI:
        mov %rax, %rdi
        #Divide nanoseconds part by 1000000 to get milliseconds:
        xor %rdx, %rdx
        mov -clockMillis_timespec_tv_nsec(%rbp), %rax
        mov $1000000, %rcx
        idiv %rcx
        #Add to RDI:
        add %rax, %rdi
        #Returns milliseconds in RAX:
        mov %rdi, %rax
        mov %rbp, %rsp
        pop %rbp
        ret


#Convert a quad word number in milliseconds to a string in seconds with 3 fixed decimals.
#Examples:
#                    1   ->   "0.001"
#                 1234   ->   "1.234"
#                11100   ->   "11.100"
#   0x7fffffffffffffff   ->   "9223372036854775.807"
#   0x8000000000000000   ->   "-9223372036854775.808"
#Input: RDI signed number in milliseconds.
#Input: RSI destination string buffer with at least 22 bytes (1 for the sign,
#       16 for the seconds, 1 for decimal dot, 3 for decimals, 1 for null char).
#Output: In destination RSI string.
#Used registers: RAX, RDI, RSI, RDX, RCX. RBX is preserved.
formatMillisAsSeconds:
        .equ formatMillisAsSeconds_dest, 8
        .equ formatMillisAsSeconds_secsPart, formatMillisAsSeconds_dest + 8
        .equ formatMillisAsSeconds_millisPart, formatMillisAsSeconds_secsPart + 8
        .equ formatMillisAsSeconds_secsPartString, formatMillisAsSeconds_millisPart + 21
        .equ formatMillisAsSeconds_millisPartString, formatMillisAsSeconds_secsPartString + 21
        .equ formatMillisAsSeconds_varsSize, formatMillisAsSeconds_millisPartString
        #Prologue
        push %rbp
        mov %rsp, %rbp
        sub $formatMillisAsSeconds_varsSize, %rsp
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        push %rbx
        sub $8, %rsp                     #Pad stack to a 16-byte boundary after pushes.
        #Store destination string ptr to a variable:
        mov %rsi, -formatMillisAsSeconds_dest(%rbp)
        #Divide by 1000 to get Seconds as result and remaining Milliseconds as modulus.
        mov %rdi, %rax
        cqo                              #Sign extend RAX into RDX:RAX
        mov $1000, %rcx
        idiv %rcx
        #Store secs part:
        mov %rax, -formatMillisAsSeconds_secsPart(%rbp)
        #ABS and store millis part:
        cmp $0, %rdx
        jge formatMillisAsSeconds_isPositive
        neg %rdx
formatMillisAsSeconds_isPositive:
        mov %rdx, -formatMillisAsSeconds_millisPart(%rbp)
        #Convert seconds part to string:
        mov -formatMillisAsSeconds_secsPart(%rbp), %rdi
        lea -formatMillisAsSeconds_secsPartString(%rbp), %rsi
        call longToString
        #Convert milliseconds part to string:
        mov -formatMillisAsSeconds_millisPart(%rbp), %rdi
        lea -formatMillisAsSeconds_millisPartString(%rbp), %rsi
        call longToString
        #Copy seconds part to dest:
        lea -formatMillisAsSeconds_secsPartString(%rbp), %rdi
        call getStringLength
        mov %rax, %rcx
        mov -formatMillisAsSeconds_dest(%rbp), %rdi
        lea -formatMillisAsSeconds_secsPartString(%rbp), %rsi
        cld                              #Clear direction flag DF to copy forward.
        rep movsb #(%rsi), (%rdi)        #Move bytes from [RSI] to [RDI] until RCX is zero.
                                         #RSI and RDI are left pointing at the first uncopied bytes
                                         #(RSI points to the null terminator here).
        #Add dot char:
        movb $0x2e, (%rdi)               #0x2e = 46 = Dot char in ASCII
        inc %rdi
        #Millis part length:
        mov %rdi, %rbx                   #Save RDI which is pointing to the end of the dest string being built.
        lea -formatMillisAsSeconds_millisPartString(%rbp), %rdi
        call getStringLength
        mov %rbx, %rdi
        #Left fill with zeros to complete 3 fixed decimals:
        mov $3, %rcx
        sub %rax, %rcx
formatMillisAsSeconds_leftFillZeros:
        cmp $0, %rcx
        jle formatMillisAsSeconds_leftFillZerosEnd
        movb $0x30, (%rdi)               #0x30 = 48 = '0' char in ASCII
        inc %rdi
        dec %rcx
        jmp formatMillisAsSeconds_leftFillZeros
formatMillisAsSeconds_leftFillZerosEnd:
        #Copy milliseconds part:
        mov %rax, %rcx                   #RAX still has the length of millisPartString.
        lea -formatMillisAsSeconds_millisPartString(%rbp), %rsi
        cld
        rep movsb                        #Move bytes from [RSI] to [RDI] until RCX is zero.
        #Null terminator char:
        movb $0, (%rdi)
        #Epilogue:
        add $8, %rsp                     #Undo padding of stack.
        pop %rbx
        mov %rbp, %rsp
        pop %rbp
        ret


#Pads a null terminated string inplace with spaces to the left, up to the char count specified in the second argument.
#Examples:
#       "abc", 6    ->   "   abc"
#       "abc", 3    ->   "abc"
#       "abc", -1   ->   "abc"
#Input: RDI buffer of string to pad. Its capacity must be at least the size of the second argument.
#Input: RSI length up to which to pad.
#Output: In RDI buffer. Otherwise none.
#Used registers: RAX, RDI, RSI, RDX, RCX
padLeft:
        #Count how many padding chars to add:
        call getStringLength             #RAX = length of input string pointed by RDI
        mov %rsi, %rcx
        sub %rax, %rcx                   #RCX = count of padding chars to add
        cmp $0, %rcx                     #If input string is bigger than requested padding, do nothing (negative RCX)
        jle padLeft_end
        #Shift chars in string (including null-char terminator) to make room at the beginning:
        lea (%rdi,%rcx), %rsi            #RSI = points to beginning of shifted string.
padLeft_shiftChars:
        cmp $0, %rax                     #Loop while RAX >= 0. It enters the loops at least once, for the null terminator.
        jl padLeft_shiftCharsEnd
        mov (%rdi,%rax), %dl             #Copy from the end towards the beginning.
        mov %dl, (%rsi,%rax)
        dec %rax
        jmp padLeft_shiftChars
padLeft_shiftCharsEnd:
        #Fill room at the beginning with padding chars:
        xor %rax, %rax
padLeft_fillPadding:
        cmp %rcx, %rax
        jz padLeft_end
        movb $0x20, (%rdi,%rax)          #0x20 = 32 = space in ASCII
        inc %rax
        jmp padLeft_fillPadding
padLeft_end:
        ret


#Entry point of the whole program. Execution begins at _start
#The command line arguments are present in the stack:
#     -The first position contains the number of arguments.
#     -The following positionss contain a pointer to a null-terminated string for each argument.
#     -The last position contains a zero value.
.global _start
_start:
        #Stack layout:
        #-0x10     ->  ;local var2 (quad word sized)..
        #-8        ->  ;local var1 (quad word sized)
        #+0 (rbp)  ->  ;old rbp
        #+0x8      ->  ;argc
        #+0x10     ->  ;arg0
        #+0x18     ->  ;arg1
        #+0x20     ->  ;arg2..
        #Local vars offsets:
        .equ start_argc, 8
        .equ start_parseOk, start_argc + 4
        .equ start_n, start_parseOk + 4
        .equ start_count, start_n + 4
        .equ start_startTime, start_count + 8
        .equ start_endTime, start_startTime + 8
        .equ start_elapsed, start_endTime + 8
        .equ start_millisAsSecondsBuffer, start_elapsed + 22
        .equ start_varsSize, start_millisAsSecondsBuffer
        #Params offsets:
        .equ start_PARAM_argc, 8
        .equ start_PARAM_arg0, 0x10
        .equ start_PARAM_arg1, 0x18
        #Prologue:
        push %rbp
        mov %rsp, %rbp
        sub $start_varsSize, %rsp        #Reserve space for local vars.
        #Align stack:
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).

        #Print usage banner if command line args are not exactly one:
        mov start_PARAM_argc(%rbp), %rcx
        cmp $2, %rcx
        jz start_exactlyOneCommandLineArg
        #Print usage banner:
        mov $usageBannerString1, %rdi
        call printString
        mov start_PARAM_arg0(%rbp), %rdi  #Print ARGV0 as program name.
        call printString
        mov $usageBannerString2, %rdi
        call printString
        call printNewline
        #Exit program here with exit code 1:
        mov $60, %rax
        mov $1, %rdi
        syscall                          #syscall: RAX = 60 (EXIT), RDI = 1 (exit code)
start_exactlyOneCommandLineArg:

        #Parse command line argument to integer 'n':
        mov start_PARAM_arg1(%rbp), %rdi
        mov $0, %esi                     #ESI = junkAllowed = 0
        lea -start_parseOk(%rbp), %rdx   #RDX = &parseOk
        call parseInt
        mov %eax, -start_n(%rbp)
        #Validate 'n':
        cmpl $0, -start_parseOk(%rbp)    #parseOk == 0 ?
        jz start_nIsNotValid
        cmp $2, %eax                     #n < 2 ?
        jl start_nIsNotValid
        jmp start_nIsValid
start_nIsNotValid:
        #Print error to STDERR and exit:
        mov $nNotValidError1, %rdi
        call printStringStderr
        mov start_PARAM_arg1(%rbp), %rdi
        call printStringStderr
        mov $nNotValidError2, %rdi
        call printStringStderr
        #Exit program here with exit code 1:
        mov $60, %rax
        mov $1, %rdi
        syscall                          #syscall: RAX = 60 (EXIT), RDI = 1 (exit code)
start_nIsValid:

        #Clock start
        call clockMillis
        mov %rax, -start_startTime(%rbp)

        #Find primes:
        mov -start_n(%rbp), %edi
        call findPrimes
        #call findPrimes_Simple
        mov %eax, -start_count(%rbp)
        ##Sleep for testing clockMillis():
        #mov $1033, %rdi
        #call sleepMillis

        #Clock end
        call clockMillis
        mov %rax, -start_endTime(%rbp)
        #Compute elapsed:
        mov -start_startTime(%rbp), %rdx
        sub %rdx, %rax                   #RAX = endTime - startTime
        mov %rax, -start_elapsed(%rbp)
        #Print "Elapsed: ":
        mov $elapsedString1, %rdi
        call printString
        #Convert 'elapsed' milliseconds to string as seconds with 3 fixed decimals:
        mov -start_elapsed(%rbp), %rdi
        lea -start_millisAsSecondsBuffer(%rbp), %rsi
        call formatMillisAsSeconds
        #Pad with spaces up to 6 chars:
        lea -start_millisAsSecondsBuffer(%rbp), %rdi
        mov $6, %rsi
        call padLeft
        #Print time with 3 decimals and space padding up to 6 chars:
        lea -start_millisAsSecondsBuffer(%rbp), %rdi
        call printString
        #Print "s\n":
        mov $elapsedString2, %rdi
        call printString

        #Print count of primes found:
        mov -start_count(%rbp), %edi
        call printInt
        mov $resultString, %rdi
        call printString
        mov -start_n(%rbp), %edi
        call printInt
        call printNewline

        #Restore stack (not actually necessary here in _start)
        mov %rbp, %rsp
        pop %rbp
        #Exit:
        mov $60, %rax
        mov $0, %rdi
        syscall                          #syscall: RAX = 60 (EXIT), RDI = 0 (exit code)


.data
printNewlineString: .asciz "\n"
usageBannerString1: .ascii "Quick and dirty single thread CPU benchmark - by JMC\n"
                    .ascii "Usage: \n"
                    .ascii "        Pass an argument up to which prime numbers will be searched with\n"
                    .ascii "        an inefficient algorithm, useful to compare the single thread performance\n"
                    .ascii "        of the CPU\n"
                    .ascii "Example: \n"
                    .ascii "        "
                    .byte 0
usageBannerString2: .ascii " 304500\n"
                    .ascii "Notes: \n"
                    .ascii "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n"
                    .ascii "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n"
                    .ascii "        GAS: it takes 8.849s using GAS 2.29.1.\n"
                    .byte 0
nNotValidError1: .asciz "ERROR: Argument '"
nNotValidError2: .asciz "' not valid.\n"
elapsedString1: .asciz "Elapsed: "
elapsedString2: .asciz "s\n"
resultString: .asciz " prime numbers were found between 2 and "


