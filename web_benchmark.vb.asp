<%@ language="vbscript" %><% Option Explicit

'Benchmark in VBScript for ASP Classic by JMC
'
'
'Run (in a browser):
'    http://<webserver>/path/to/web_benchmark.vb.asp?n=30450
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

    Response.ContentType = "text/plain"
    Response.Charset = "UTF-8"

    if IsEmpty(Request.QueryString("n")) Or Request.QueryString.Count <> 1 then
        Response.Write "Quick and dirty single thread CPU benchmark - by JMC" & Chr(10)
        Response.Write "Usage: " & Chr(10)
        Response.Write "        Pass an argument up to which prime numbers will be searched with" & Chr(10)
        Response.Write "        an inefficient algorithm, useful to compare the single thread performance" & Chr(10)
        Response.Write "        of the CPU" & Chr(10)
        Response.Write "Example: " & Chr(10)
        Response.Write "        " + Request.ServerVariables("SCRIPT_NAME") + "?n=304500" & Chr(10)
        Response.Write "Notes: " & Chr(10)
        Response.Write "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz" & Chr(10)
        Response.Write "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3." & Chr(10)
        Response.Write "        ASP VBScript: it takes 332.031s using IIS 5.0.2195 in a 32bit Win2000 SP4 VM." & Chr(10)
        Response.Write "        ASP VBScript: it takes 457.602s using IIS 7.5.7600.20917 in a 32bit WinXP SP3 VM." & Chr(10)
        Response.Write "" & Chr(10)
        Response.End()
    end if

    n = -1
    On Error Resume Next
    n = CLng(Request.QueryString("n"))   'Max value for CInt() Integer is 32767. Max for CLng is 2147483647.
    On Error Goto 0
    if TypeName(n) <> "Long" Or Trim(Request.QueryString("n")) <> CStr(n) Or n < 2 then
        Response.Write("ERROR: Argument '" & Request.QueryString("n") & "' not valid." & Chr(10))
        Response.End()
    end if

    Server.ScriptTimeout = 3600  'Default is only 90 seconds.
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
    Response.Write "Elapsed: " & padLeft(FormatNumber(elapsedSecs, 3), 6) & "s" & Chr(10)

    Response.Write count & " prime numbers were found between 2 and " & n & Chr(10)
End Function


main()


%>
