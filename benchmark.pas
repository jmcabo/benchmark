#!/usr/bin/instantfpc -O3
{Compile and run manually (first comment the shebang first line):}
{   fpc -O3 -obenchmark benchmark.pas  &&  ./benchmark 304500   }

program benchmark;

{To enable ObjectPascal Mode (to have Try Except, etc.), remove "DISABLED ":}
{DISABLED $mode objfpc}

uses SysUtils, DateUtils;


function findPrimes(n : Int32) : Int32;
var
    i : Int32;
    j : Int32;
    count : Int32;
    m : Int32;
begin
    count := 0;

    {For each number up to 'n':}
    for i := 2 to n do
    begin
        j := 2;
        while j < i do  {NOT using the sqrt optimization (for easier benchmarking).}
        begin
            {If i divisible by j, it wasn't a prime number:}
            m := i mod j;  {Putting mod in an Int32 variable before the if is 10% faster.}
            if m = 0 then
                break;
            j := j + 1;
        end;

        if i = j then
            {The previous loop ended without divisors found. It is a prime number.}
            count := count + 1;
    end;

    exit(count);
end;


procedure main;
var
    n : Int32;
    count : Int32;
    startTime : TDateTime;
    endTime : TDateTime;
    elapsed : Double;
begin
    if ParamCount <> 1 then
    begin
        writeln('Quick and dirty single thread CPU benchmark - by JMC');
        writeln('Usage: ');
        writeln('        Pass an argument up to which prime numbers will be searched with');
        writeln('        an inefficient algorithm, useful to compare the single thread performance');
        writeln('        of the CPU');
        writeln('Example: ');
        writeln('        ' + ExtractFileName(ParamStr(0)) + ' 304500');
        writeln('Notes: ');
        writeln('        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz');
        writeln('        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.');
        writeln('        Pascal32bits: it takes 8.851s using freepascal 2.6.2 with flag -O3.');
        writeln('        Pascal: it takes 27.653s using freepascal 2.6.2 with flag -O3.');
        writeln('');
        ExitCode := 1;
        exit;
    end;

    {
    try
        n := StrToInt(ParamStr(1));
    except
        On E : EConvertError do
            n := -1;
    end;
    }
    n := StrToIntDef(ParamStr(1), -1);
    if n < 2 then
    begin
        writeln(StdErr, Format('ERROR: Argument ''%s'' not valid.', [ParamStr(1)]));
        ExitCode := 1;
        exit;
    end;

    startTime := Now;

    count := findPrimes(n);

    endTime := Now;
    elapsed := SecondSpan(endTime, startTime);
    writeln(Format('Elapsed: %6.3fs', [elapsed]));

    writeln(count, ' prime numbers were found between 2 and ', IntToStr(n));
end;


begin
    main();
end.


