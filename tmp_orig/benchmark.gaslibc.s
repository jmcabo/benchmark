//bin/true  ;  gcc -o benchmark "$0"  &&  exec -a "$0" ./benchmark $@  ;  exec /bin/false
# vim: filetype=gas:

#Benchmark in Assembly Language for GAS (GNU Assembler) and 64-bit Linux using libc - by JMC
#
#
#Run:
#    ./benchmark.gaslibc.s 304500
#Assemble and run:
#    gcc -o benchmark benchmark.gaslibc.s  &&  ./benchmark 304500
#The same but using 'as':
#    as -o benchmark.o benchmark.gaslibc.s  &&  gcc -o benchmark benchmark.o  &&  ./benchmark 304500
#
#
#Notes:
#    -See "benchmark.nasm.asm" for more notes about Assembly.
#
#    -See "benchmark.nasmlibc.asm" for the same code but written for NASM.
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
#           cmp byte [rdi + rax], 0       -->   cmpb $0, (%rdi,%rax,1)
#           mov rax, [rdx + rsi * 4]      -->   mov (%rdx, %rsi, 4), %eax
#           mov [mytable + rdi * 4], rax  -->   mov %eax, mytable( , %rdi, 4)
#
#    -Instead of specifying "dword" or "quad" when the size of the operand isn't clear in the
#     context, the size is specified as part of the instruction name:
#           mov byte [rsi], 0   -->   movb $0, (%rsi)
#     The suffixes can be: b, w, l, q.
#
#    -The extern's for libc symbols are not necessary with GAS.
#
#    -The default in almost all current Linux distros now (ever since about 2017) is to have
#     gcc compile Position Independent Executables (PIE). That means that when compiling
#     with default switches, we cannot simply do:
#           call printf
#     with GAS we must do instead:
#           call printf@plt
#     That resolves the call location with reference to the PLT (Procedure Linkage Table).
#     Otherwise, we get an error such as:
#           Symbol `printf' causes overflow in R_X86_64_PC32 relocation
#     The alternative is to pass -no-pie to gcc. In that case we can still use "call printf".
#
#    -With PIE, we need to reference global variables relative to the program counter. With NASM
#     for some reason it isn't always necessary or it is resolved by using "rel" or declaring
#     "default rel" at the beginning.
#     With GAS, instead of:
#           mov (stderr), %rdi
#     we must do:
#           mov stderr(%rip), %rdi
#     And the same when using GAS for stuff in our .data section:
#           mov resultString, %rdi
#     becomes:
#           lea resultString(%rip), %rdi
#     Otherwise we get errors such as:
#           relocation R_X86_64_32S against `.data' can not be used when making a shared
#           object; recompile with -fPIC
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

.equ CLOCKS_PER_SEC, 1000000             #Fixed to 1000000 according to POSIX. See "man clock".
                                         #Thus clock() has fixed microsecond precision.


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


#Entry point of the whole program. Execution begins at main
#The command line arguments come in RDI and RSI.
#The argument count 'argc' comes in RDI and 'argv' in RSI.
.global main
.type main, @function                    #The .type directive is optional for x86 ELF.
main:
        #Stack layout:
        #-0x10     ->  ;local var2 (quad word sized)..
        #-8        ->  ;local var1 (quad word sized)
        #+0 (rbp)  ->  ;old rbp
        #+0x8      ->  ;RIP program counter for returning to caller
        #Local vars offsets:
        .equ main_argc, 8
        .equ main_argv, main_argc + 8
        .equ main_n, main_argv + 4
        .equ main_count, main_n + 4
        .equ main_startTime, main_count + 8
        .equ main_endTime, main_startTime + 8
        .equ main_elapsed, main_endTime + 8
        .equ main_varsSize, main_elapsed
        #Prologue:
        push %rbp
        mov %rsp, %rbp
        sub $main_varsSize, %rsp         #Reserve space for local vars.
        #Align stack:
        and $-16, %rsp                   #Align stack to a 16-byte boundary (-16 is 0xff..ff0).
        #Save ARGC and ARGV to variables before overwriting RDI and RSI:
        mov %rdi, -main_argc(%rbp)
        mov %rsi, -main_argv(%rbp)

        #Print usage banner if command line args are not exactly one:
        mov -main_argc(%rbp), %rcx
        cmp $2, %rcx
        jz main_exactlyOneCommandLineArg
        #Print usage banner:
        lea usageBannerString(%rip), %rdi  #RDI = first printf argument
        mov -main_argv(%rbp), %rsi
        mov (%rsi), %rsi                 #RSI = argv[0]
        xor %rax, %rax                   #RAX = 0 = No vector args (floats) in this call to printf.
        call printf@plt
        #Print newline:
        lea printNewlineString(%rip), %rdi
        call puts@plt
        #Exit program here with exit code 1:
        mov $1, %rdi
        call exit@plt
main_exactlyOneCommandLineArg:

        #Parse command line argument to integer 'n':
        mov -main_argv(%rbp), %rdi
        mov 8(%rdi), %rdi                #RDI = argv[1]
        call atoi@plt
        mov %eax, -main_n(%rbp)
        #Validate 'n':
        cmp $2, %eax                     #n < 2 ?
        jge main_nIsValid
main_nIsNotValid:
        #Print error to STDERR and exit:
        mov stderr(%rip), %rdi           #RDI = STDERR pointer (this line requires 'default rel')
        lea nNotValidError(%rip), %rsi
        mov -main_argv(%rbp), %rdx
        mov 8(%rdx), %rdx
        xor %rax, %rax
        call fprintf@plt
        #Exit program here with exit code 1:
        mov $1, %rdi
        call exit@plt
main_nIsValid:

        #Clock start
        call clock@plt
        mov %rax, -main_startTime(%rbp)

        #Find primes:
        mov -main_n(%rbp), %edi
        call findPrimes
        #call findPrimes_Simple
        mov %eax, -main_count(%rbp)

        #Clock end
        call clock@plt
        mov %rax, -main_endTime(%rbp)
        #Compute elapsed as a double in seconds:
        mov -main_startTime(%rbp), %rdx
        sub %rdx, %rax                   #RAX = endTime - startTime
        cvtsi2sd %rax, %xmm0
        mov $CLOCKS_PER_SEC, %rdx
        cvtsi2sd %rdx, %xmm1
        divsd %xmm1, %xmm0               #(endTime - startTime) / CLOCKS_PER_SEC
        movsd %xmm0, -main_elapsed(%rbp)
        #Print Elapsed seconds with 3 fixed decimals and padding up to 6 spaces:
        lea elapsedString(%rip), %rdi
        mov $1, %rax                     #AL = Number of floating point args. XMM0 has the double argument
        call printf@plt

        #Print count of primes found:
        lea resultString(%rip), %rdi
        mov -main_count(%rbp), %esi
        mov -main_n(%rbp), %edx
        xor %rax, %rax
        call printf@plt

        #Exit code 0:
        mov $0, %rax
        #Epilogue:
        mov %rbp, %rsp
        pop %rbp
        ret


.data
printNewlineString: .asciz "\n"
usageBannerString: .ascii "Quick and dirty single thread CPU benchmark - by JMC\n"
                   .ascii "Usage: \n"
                   .ascii "        Pass an argument up to which prime numbers will be searched with\n"
                   .ascii "        an inefficient algorithm, useful to compare the single thread performance\n"
                   .ascii "        of the CPU\n"
                   .ascii "Example: \n"
                   .ascii "        %s 304500\n"
                   .ascii "Notes: \n"
                   .ascii "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz\n"
                   .ascii "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.\n"
                   .ascii "        GAS-libc: it takes 8.849s using GAS 2.29.1.\n"
                   .byte 0
nNotValidError: .asciz "ERROR: Argument '%s' not valid.\n"
elapsedString: .asciz "Elapsed: %6.3fs\n"
resultString: .asciz "%d prime numbers were found between 2 and %d\n"


