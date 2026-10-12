'Benchmark in VBScript for Windows Console by JMC
'
'
'Run with:
'    cscript //nologo benchmark.wsh.vbs 30450
'Otherwise it prints to message boxes instead of STDOUT.
'
'
'Notes:
'    -VBScript was created by Microsoft in 1996. It is present in WSH, IIS (ASP) and IE.
'
'
'Limitations:
'    -An extra test (reconverted integer != original string) is necessary after parsing the integer
'     argument to exclude strings like "123.", "123.0" or "12.3e1" (using CLng() already produces an
'     error for strings like "123abc"). Because of this extra test, an integer with a plus sign is not
'     considered valid: "+123".
'


Option Explicit


'Relaunch in console (with CScript instead of WScript) if run directly:
if InStr(1, WScript.FullName, "WScript.exe", vbTextCompare) <> 0 then
    Dim args, i, shell

    args = ""
    For i=0 To WScript.Arguments.Count-1
        if args <> "" then
            args = args + " "
        end if
        args = args & """" & WScript.Arguments.Item(i) & """"
    Next

    Set shell = WScript.CreateObject("WScript.Shell")
    shell.Run("%comspec% /c cscript //nologo """ & WScript.ScriptFullName & """ " & args & " & pause")
    WScript.Quit
end if


'NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
'that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
'but puts the function in a loop and counts 10000 calls).
'Returns how many prime numbers exist between 2 and n:
Private Function findPrimes(ByVal n)
    Dim i, j, count
    count = CLng(0)

    'For each number up to 'n':
    For i=CLng(2) To n
        For j=CLng(2) To i-1  'NOT using the sqrt optimization (for easier benchmarking).
            'If i divisible by j, it wasn't a prime number:
            if i Mod j = 0 then
                Exit For
            end if
        Next
        if i = j then
            'The previous loop ended without divisors found. It is a prime number.
            count = count + 1
        end if
    Next

    findPrimes = count
End Function


Private Function padLeft(s, toLength)
    While len(s) < toLength
        s = Chr(&h20) + s
    Wend
    padLeft = s
End Function


Private Function main()
    Dim n, count, startDate, endDate, startTime, endTime, elapsedSecs

    if WScript.Arguments.Count <> 1 then
        WScript.Echo "Quick and dirty single thread CPU benchmark - by JMC"
        WScript.Echo "Usage: "
        WScript.Echo "        Pass an argument up to which prime numbers will be searched with"
        WScript.Echo "        an inefficient algorithm, useful to compare the single thread performance"
        WScript.Echo "        of the CPU"
        WScript.Echo "Example: "
        WScript.Echo "        cscript //nologo " + WScript.ScriptName + " 304500"
        WScript.Echo "Notes: "
        WScript.Echo "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        WScript.Echo "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        WScript.Echo "        VBScript/WSH: it takes 328.797s using WSH 5.1 in a 32bit Win2000 SP4 VM."
        WScript.Echo "        VBScript/WSH: it takes 336.660s using WSH 5.8 in a 64bit Win8.1 VM."
        WScript.Echo "        VBScript/WSH: it takes 412.730s using WSH 5.8 in a 32bit Win7 SP1 VM."
        WScript.Echo "        VBScript/WSH: it takes 424.566s using WSH 5.8 in a 64bit Win7 SP1 BareMetal."
        WScript.Echo "        VBScript/WSH: it takes 458.148s using WSH 5.7 in a 32bit WinXP SP3 VM."
        WScript.Echo ""
        WScript.Quit 1
    end if

    n = -1
    On Error Resume Next
    n = CLng(WScript.Arguments.Item(0))   'Max value for CInt() Integer is 32767. Max for CLng is 2147483647.
    On Error Goto 0
    if TypeName(n) <> "Long" Or Trim(WScript.Arguments.Item(0)) <> CStr(n) Or n < 2 then
        WScript.StdErr.Write("ERROR: Argument '" & WScript.Arguments.Item(0) & "' not valid." & Chr(10))
        WScript.Quit(1)
    end if

    startDate = Now()            'Now() doesn't give milliseconds.
    startTime = Timer()          'Timer() gives "Secs.Millisecs" but wraps around at midnight.

    count = findPrimes(n)

    endTime = Timer()
    endDate = Now()
    'Use milliseconds part from Timer() and whole seconds from Now()+DateDiff(), to
    'handle all cases of midnight(s) happening in between start and end:
    'Note: Int() truncates a Double, while CInt() casts to Integer.
    elapsedSecs = (endTime - Int(endTime) + DateDiff("s", "01/01/1970 00:00:00", endDate)) - _
                  (startTime - Int(startTime) + DateDiff("s", "01/01/1970 00:00:00", startDate))
    WScript.Echo "Elapsed: " & padLeft(FormatNumber(elapsedSecs, 3), 6) & "s"

    WScript.Echo count & " prime numbers were found between 2 and " & n
End Function


main()

