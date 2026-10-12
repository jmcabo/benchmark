'Benchmark for LibreOffice Basic by JMC
'
'
'Run:
'    1. Open LibreOffice Calc spreadsheet.
'    2. Go to menu "Tools -> Macros -> Organize Macros -> LibreOffice Basic..."
'    3. A dialog shows up. On the left, click on the item called "Standard" below your
'       spreadsheet. A "New" button shows up on the right. Click "New".
'    4. The LibreOffice Basic editor shows up. Paste the contents of this file.
'    5. Hit F5 to Run or click on the play button in the toolbar.
'Important Note:
'    To run inside LibreOffice Basic editor, move the cursor inside the Main subroutine and hit F5.
'    If the cursor is in the findPrimes function, it tries to run it instead skipping main and produces
'    an error about arguments ("Argument is not optional").
'    If the cursor is outside all functions, a selection dialog shows up. Select "Main".
'Note: If the spreadsheet is saved and then re-opened, it doesn't allow Macro execution
'      unless "Tools -> Options -> LibreOffice -> Security -> Macro Security" is set to Medium
'      or lower. (Medium asks confirmation when opening the document).
'
'Run from the spreadsheet:
'    Create a cell with the contents:
'        =HYPERLINK("vnd.sun.star.script:Standard.Module1.Main?language=Basic&location=document")
'    and CTRL+click it.
'
'    Or hit CTRL+K to insert a hyperlink (menu "Insert -> Hyperlink...") and use the following as URL:
'        vnd.sun.star.script:Standard.Module1.Main?language=Basic&location=document
'    and use any text you want for displaying on the cell in the "Text" field.
'    Use it by doing CTRL+click over the cell.
'
'
'Limitations of LibreOffice Basic:
'    -An extra test (reconverted integer != original string) is necessary after parsing the integer
'     argument to exclude strings like "123abc", "123.", "123.0" or "12.3e1". Because of this extra test,
'     an integer with a plus sign is not considered valid: "+123".
'
'    -No line or console output (STDOUT, STDERR, etc.). Output has to be done using message boxes. Even
'     Print() outputs to message boxes but they cannot be multiline when used with Print() instead of MsgBox.
'
'    -The LibreOffice Basic message boxes have a width limitation, and the usage banner had to be adjusted.
'
'    -No (easy) Main arguments. The program gets the argument from an input box.
'
'    -Integers are 16bits so the program has to use Long variables (32bits).
'
'    -Format("#0.000", elapsed) doesn't add a space char, so a padLeft() function is implemented. Hash signs
'     don't add spaces in Format().
'
'    -No support for a clock with milliseconds in the language. Instead, the spreadsheet function NOW()
'     is used. The Basic function Timer() doesn't return milliseconds here.
'
'    -It seems to take nearly double the time in Win8.1 than in Linux, I can't think of why. Both Linux and
'     Windows are 64bit OSs.
'


'NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
'that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
'but puts the function in a loop and counts 10000 calls).
'Returns how many prime numbers exist between 2 and n:
Private Function findPrimes(n As Long) As Long
    Dim i As Long, j As Long, count As Long
    count = 0

    'For each number up to 'n':
    For i = 2 To n
        For j = 2 To i - 1  'NOT using the sqrt optimization (for easier benchmarking).
            'If i divisible by j, it wasn't a prime number:
            If i Mod j = 0 Then
                Exit For
            End If
        Next j
        If i = j Then
            'The previous loop ended without divisors found. It is a prime number.
            count = count + 1
        End If
    Next i

    findPrimes = count
End Function


Private Function SysTime() as Double
    Dim svc As Object

    'Create a service to use Calc functions
    svc = createUnoService("com.sun.star.sheet.FunctionAccess")

    'NOW is a Double expressed in days.
    'Multiply by 86400.0 (seconds in a day) to convert it to seconds
    SysTime = svc.callFunction("NOW",Array()) * 86400.0
End Function


Private Function padLeft(s, toLength)
    While Len(s) < toLength
        s = Chr(&H20) + s
    Wend
    padLeft = s
End Function


Sub Main()
    Dim n As Long, nStr, msgTitle, msg, count As Long, startTime, endTime, elapsed

    msg = "Quick and dirty single thread CPU benchmark - by JMC" & Chr(10)
    msg = msg & "Usage: " & Chr(10)
    msg = msg & "        Pass an argument up to which prime numbers will be searched with" & Chr(10)
    msg = msg & "        an inefficient algorithm, useful to compare the single thread performance" & Chr(10)
    msg = msg & "        of the CPU" & Chr(10)
    msg = msg & "Example: " & Chr(10)
    msg = msg & "        n=3045" & Chr(10)
    msg = msg & "Notes: " & Chr(10)
    msg = msg & "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel" & Chr(10)
    msg = msg & "        i7 4770K @ 3.5GHz with benchmark.c compiled without optimizations using" & Chr(10)
    msg = msg & "        GCC, and 8.85s with -O3." & Chr(10)
    msg = msg & "        LibreOffice Basic: it takes 4080.283s (1h 8m) using v5.4.5 on Ubuntu 17.10." & Chr(10)
    msg = msg & "          For n=3045 it takes 0.671s. For n=30450 it takes 50.060s" & Chr(10)
    msg = msg & "        LibreOffice Basic: it takes an estimated 7329s (2h 2m) using v4.2.5" & Chr(10)
    msg = msg & "          on Win7 64bits. For n=3045 it takes 1.180s. For n=30450 it takes 90.352s" & Chr(10)
    msg = msg & "        LibreOffice Basic: it takes 7628.750s (2h 7m) using v6.0.2 on Win8.1 64bits." & Chr(10)
    msg = msg & "          For n=3045 it takes 1.235s. For n=30450 it takes 93.313s" & Chr(10)
    msg = msg & Chr(10)
    msgTitle = "Benchmark"
    MsgBox msg, MB_OK + MB_ICONINFORMATION, msgTitle

    n = -1
    nStr = InputBox("Search primes up to?", msgTitle, "")
    On Error Resume Next
    n = CLng(nStr)   'Max value for CInt() Integer is 32767. Max for CLng and Long is 2147483647.
    On Error GoTo 0
    if Trim(nStr) <> CStr(n) Or n < 2 then
        'No STDERR (nor STDOUT) but at least we can show an error icon using MB_ICONSTOP:
        MsgBox "ERROR: Argument '" & nStr & "' not valid." & Chr(10), MB_OK + MB_ICONSTOP, msgTitle
        End
    end if

    startTime = SysTime()

    count = findPrimes(n)

    endTime = SysTime()
    elapsed = endTime - startTime
    msg = "Elapsed: " & padLeft(Format(elapsed, "0.000"), 6) & "s" & Chr(10)

    msg = msg & count & " prime numbers were found between 2 and " & n
    MsgBox msg, MB_OK, msgTitle
End Sub

