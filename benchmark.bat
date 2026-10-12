@echo off & setlocal enableDelayedExpansion

:: Benchmark in .BAT by JMC
::
::
:: Run:
::     benchmark.bat 304
::
::
:: Notes:
::     -This benchmark.bat requires cmd.exe. Using command.com won't work, it doesn't have
::      arithmetic operators like %% modulus. This leaves out Win98 and older.
::      It can have a ".cmd" extension instead of ".bat" too.
::
::     -Numbers are always 32-bits of precision, even in 64-bit OSs.
::
::
:: Limitations:
::     -It prints 0xd 0xa instead of 0xa, of course.
::
::     -If midnight occurs between measuring startTime and endTime, the elapsed time will be incorrect.
::
::     -Passing "+30" as an argument is not considered a valid 'n' because of validating the integer
::      against the string representation.
::


set programName=%0
call :main %*
exit /b %errorlevel%


:: NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
:: that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
:: but puts the function in a loop and counts 10000 calls).
:: Returns how many prime numbers exist between 2 and n:
::
:: Although slow, it is the fastest version among the others below.
::   It uses for loops (which are faster than ifs and goto loops), and
:: since for loops don't have a "break" statement, the inner loop is
:: put in a subroutine which can exit in the middle of the loop.
:findPrimes resultVarName n
    setlocal enableDelayedExpansion
    set /a n=%2
    set /a count=0
    for /L %%i in (2, 1, !n!) do (
        call :isPrime %%i
        if !errorlevel! EQU 1 (
            set /a count+=1
        )
    )
    endlocal & set /a %~1=%count%
    exit /b 0
    :isPrime n
        set /a forTo=%1 - 1
        for /L %%j in (2, 1, %forTo%) do (
            set /a mod=%1 %% %%j
            if !mod! EQU 0 (
                exit /b 0
            )
        )
        exit /b 1


:: About 2x slower, but still faster than GotoLoops. Uses two nested for loops, but
:: since for loops can't break, it performs unnecessary extra iterations.
:findPrimes_NestedForLoops resultVarName n
    setlocal enableDelayedExpansion
    set /a n=%2
    set /a count=0
    for /L %%i in (2, 1, !n!) do (
        set /a isPrime=1
        set /a forTo=%%i - 1
        for /L %%j in (2, 1, !forTo!) do (
            set /a mod=%%i %% %%j
            if !mod! EQU 0 (
                set /a isPrime=0
            )
        )
        set /a count+=!isPrime!
    )
    endlocal & set /a %~1=%count%
    exit /b 0


:: About 10x slower than the first version above.
:: This uses Goto Loops that can break, as opposed to FOR loops,
:: but for some reason it's the slower of the versions here.
:: Maybe CMD does something silly like re-read the whole file to find a goto label on every jump??
:findPrimes_GotoLoops resultVarName n
    setlocal enableDelayedExpansion
    set /a n=%2
    set /a count=0
    set /a i=2
    :fp2_loop
    if %i% GTR %n% goto fp2_end_loop
        set /a j=2
        :fp2_loopJ
        if %j% GTR %i% goto fp2_end_loopJ
            set /a mod=%i% %% %j%
            if %mod% EQU 0 (
                goto fp2_end_loopJ
            )
            set /a j+=1
        goto fp2_loopJ
        :fp2_end_loopJ
        if %i% EQU %j% (
            set /a count+=1
        )
        set /a i+=1
    goto fp2_loop
    :fp2_end_loop
    endlocal & set /a %~1=%count%
    exit /b 0


:: Subtracts two values obtained from %time%, and returns a string in the format:
::      SECS.MSECS
:: fixed to 3 decimal places.
:: If midnight happened between the two times, the result will be incorrect.
:: The result is returned in the %resultVarName% variable:
::      call getElapsedSecs resultVarName !startTime! !endTime!
:getElapsedSecs resultVarName startTime endTime
    setlocal enableDelayedExpansion
    set resultVarName=%~1
    set startTime=%2
    set endTime=%3
    :: Convert to centiseconds since midnight, with a trick
    :: to avoid "09" being parsed as an erroneous Octal number:
    :: (see: http://stackoverflow.com/questions/9922498/calculate-time-difference-in-windows-batch-file )
    for /f "tokens=1-4 delims=:.," %%a in ("%startTime%") do (
        set /a "startTimeCs=(((%%a * 60) + 1%%b %% 100) * 60 + 1%%c %% 100) * 100 + 1%%d %% 100"
    )
    for /F "tokens=1-4 delims=:.," %%a in ("%endTime%") do (
        set /A "endTimeCs=(((%%a * 60) + 1%%b %% 100) * 60 + 1%%c %% 100) * 100 + 1%%d %% 100"
    )
    :: Subtract centiseconds:
    set /a elapsedCs=endTimeCs - startTimeCs
    :: Split into integer seconds and milliseconds (Batch doesn't have floats):
    set /a elapsedSecsPart=elapsedCs / 100
    set /a elapsedMsPart=(elapsedCs - elapsedSecsPart * 100) * 10
    :: Left pad milliseconds with 0's:
    if !elapsedMsPart! LSS 10 (
        set elapsedMsPart=00!elapsedMsPart!
    ) else (
        if !elapsedMsPart! LSS 100 (
            set elapsedMsPart=0!elapsedMsPart!
        )
    )
    :: Return result string in specified var name:
    endlocal & set %resultVarName%=%elapsedSecsPart%.%elapsedMsPart%
    exit /b 0


:: Adds spaces to the specified string while it is less than n chars long:
::      call padLeft resultVarName "abc" 6
:padLeft resultVarName string n
    setlocal enableDelayedExpansion
    set resultVarName=%~1
    set str=%2
    set /a n=%3
    if !n! LSS 1 (
        set "!resultVarName!=!str!"
        exit /b 0
    )
    :: Batch doesn't have a way to determine string length, but it has substrings.
    :: Iterate while substring of n-1 chars is empty:
    set /a n=%n% - 1
    :padLeft_loop
    if not "!!str:~%n%!" == "" goto padLeft_end_loop
        set str= !str!
    goto padLeft_loop
    :padLeft_end_loop
    endlocal & set %resultVarName%=%str%
    exit /b 0


:main
    set argCount=0
    for %%x in (%*) do set /a argCount+=1

    if !argCount! NEQ 1 (
        echo Quick and dirty single thread CPU benchmark - by JMC
        echo Usage: 2>&1
        echo         Pass an argument up to which prime numbers will be searched with
        echo         an inefficient algorithm, useful to compare the single thread performance
        echo         of the CPU
        echo Example: 2>&1
        echo         %programName% 304
        echo Notes: 2>&1
        echo         Searching up to 304500 takes almost exactly 10 seconds ^(9.7s^) on an Intel i7 4770K @ 3.5GHz
        echo         with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.
        echo         Batch: it takes an estimated 143488s ^(39h 51m^) using cmd 5.1.2600 in a 32bit WinXP SP3 VM. For benchmark 3045, it takes 23.270s.
        echo         Batch: it takes an estimated 259042s ^(71h 57m^) using cmd 6.1.7601 in a 32bit Win7 SP1 VM. For benchmark 3045, it takes 42.010s.
        echo         Batch: it takes an estimated 316265s ^(87h 51m^) using cmd 6.3.9600 in a 64bit Win8.1 VM. For benchmark 3045, it takes 51.290s.
        echo.
        exit /b 1
    )

    set /a n=-1
    set /a n=%1 2>nul
    if not {%n%} == {%1} (
        set /a n=-1
    )
    if %n% LSS 2 (
        echo ERROR: Argument '%1' not valid. 1>&2
        exit /b 1
    )

    set startTime=%time%

    call :findPrimes count !n!

    set endTime=%time%
    call :getElapsedSecs elapsed !startTime! !endTime!
    call :padLeft elapsed %elapsed% 6
    echo Elapsed: !elapsed!s

    echo !count! prime numbers were found between 2 and !n!
    exit /b 0

