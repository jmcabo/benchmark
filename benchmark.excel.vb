'Benchmark for Excel Visual Basic by JMC
'
'
'Run:
'    1. Open a new Excel spreadsheet.
'    2. Save it as a Macro-Enabled Workbook ".XLSM", for example "benchmark.excel.xlsm".
'    3. Go to menu or ribbon "Developer -> Visual Basic".
'    4. Go to menu "Insert -> Module" in Visual Basic. A new module called "Module1" is inserted
'       in the project tree to the left. Double-click "Module1".
'    5. In the editor window, paste the contents of this file.
'    6. Hit F5 to Run or click on the play button in the toolbar.
'    (For Excel 2010, use the ribbon "View -> Macros -> View Macros" then type a
'    name, select This workbook and click Create.)
'Important Note:
'    To run inside Visual Basic editor, move the cursor inside the Main subroutine and hit F5.
'    If the cursor is outside of the Main subroutine, a dialog shows up that lets select "Main"
'    to run it. The dialog is avoided if the cursor is in Main.
'Note: The spreadsheet must be of type .XLSM to be able to save the macro. If it is of type .XLSX,
'      then the macro can't be saved.
'Note: If the spreadsheet is saved and then re-opened, it doesn't allow Macro execution
'      unless it is enabled for that session by clicking in the notification shade that slides down
'      from the menu/ribbon when opened. Excel has general settings to disable macro security but
'      that is not recommended.
'The benchmark can be interrupted by hitting ESC.
'
'Run from the spreadsheet:
'A) Button:
'    1. Go to menu or ribbon "Developer -> Controls -> Insert -> Button (Form Control)".
'       Draw the button somewhere in the worksheet.
'    2. An "Assign Macro" dialog shows up. Select "Main".
'    3. Right-click the button and click "Edit Text" to rename it to "Benchmark Macro" for instance.
'    4. You can change or reassign the macro to the button by Right-Clicking on it and selecting
'       "Assign Macro..." in the context menu.
'    5. DONE. Click the button to run the benchmark.
'B) Hyperlink:
'    1. Create a hyperlink to itself. Go to menu or ribbon "Insert -> Hyperlink" (or hit CTRL+K).
'    2. In the creation dialog, select "Place in This Document" in the bar at the left.
'       Then select its own workbook and sheet, and type the cell number, for instance: "C9", it
'       has to be the same cell of the hyperlink (a link to itself).
'       At the top of the creation dialog, in "Text to Display", enter for instance "Benchmark Macro".
'    3. Right-click in the sheet tab (ie: the tab at the bottom called for instance "Sheet1"),
'       and click on "View Code" in the context menu. Alternatively, go to ribbon
'       "Developer -> Controls -> View Code" and double-click the hyperlink sheet (ie: Sheet1) in the
'       project tree to the left.
'    4. Paste the following in the editor. You must change $C$9 to be the cell you actually used
'       for the hyperlink:
'               Private Sub Worksheet_FollowHyperlink(ByVal Target As Hyperlink)
'                   If Target.Range.Address = "$C$9" Then
'                       Call Module1.Main
'                   End If
'               End Sub
'    5. DONE. You can run the macro by just clicking on the hyperlink cell. (No CTRL+click necessary
'       as it was in LibreOffice).
'
'
'Limitations of Excel Visual Basic:
'    -An extra test (reconverted integer != original string) is necessary after parsing the integer
'     argument to exclude strings like "123.", "123.0" or "12.3e1" (using CLng() already produces an
'     error for strings like "123abc"). Because of this extra test, an integer with a plus sign is not
'     considered valid: "+123".
'
'    -No line or console output (STDOUT, STDERR, etc.). Output has to be done using message boxes. Print()
'     is not allowed in the macro module but it is allowed in the Immediate window.
'
'    -With Win8.1 and both Excel 2010 and Excel 2016, the message boxes have a width limitation, and the
'     usage banner had to be adjusted. This wasn't a problem with older versions of Windows.
'
'    -No (easy) Main arguments. The program gets the argument from an input box.
'
'    -Integers are 16bits so the program has to use Long variables (32bits).
'
'    -Format("#0.000", elapsed) doesn't add a space char, so a padLeft() function is implemented. Hash signs
'     don't add spaces in Format().
'
'    -The Basic function Timer() returns the seconds since midnight as a floating point number.
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
    msg = msg & "        n=304500" & Chr(10)
    msg = msg & "Notes: " & Chr(10)
    msg = msg & "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel" & Chr(10)
    msg = msg & "        i7 4770K @ 3.5GHz with benchmark.c compiled without optimizations using" & Chr(10)
    msg = msg & "        GCC, and 8.85s with -O3." & Chr(10)
    msg = msg & "        Excel VB: it takes 41.766s using Excel 2007 VB 6.5. For n=30450 it takes 0.516s" & Chr(10)
    msg = msg & "        Excel VB: it takes 42.074s using Excel 2010 VB 7.0. For n=30450 it takes 0.516s" & Chr(10)  '32bit version
    msg = msg & "        Excel VB: it takes 42.109s using Excel 2003 VB 6.3. For n=30450 it takes 0.516s" & Chr(10)
    msg = msg & "        Excel VB: it takes 42.172s using Excel 2016 VB 7.1. For n=30450 it takes 0.516s" & Chr(10)  '64bit version
    msg = msg & "        Excel VB: it takes 42.578s using Excel 2000. For n=30450 it takes 0.531s" & Chr(10)
    msg = msg & "        Excel VB: it takes 42.625s using Excel 97 VB 1997. For n=30450 it takes 0.531s" & Chr(10)
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
    End If

    startTime = Timer()

    count = findPrimes(n)

    endTime = Timer()
    elapsed = endTime - startTime
    msg = "Elapsed: " & padLeft(Format(elapsed, "0.000"), 6) & "s" & Chr(10)

    msg = msg & count & " prime numbers were found between 2 and " & n
    MsgBox msg, MB_OK, msgTitle
End Sub

