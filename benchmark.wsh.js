//Benchmark in JavaScript for Windows Console by JMC
//
//
//Run with:
//    cscript //nologo benchmark.wsh.js 30450
//Otherwise it prints to message boxes instead of STDOUT.
//
//
//Notes:
//    -See "benchmark.js" for more notes about JavaScript.
//
//
//Limitations:
//    -An extra test (reconverted integer != original string) is necessary after parsing the integer
//     argument to exclude strings like "123.", "123.0" or "12.3e1" (subtracting 0 already returns NaN
//     for strings like "123abc"). Because of this extra test, an integer with a plus sign
//     is not considered valid: "+123".
//       I also check against the maximum number that is the biggest float that doesn't loose
//     precision in the last digit and that still satisfies 'n != n+1'.
//       If the check for the max safe integer wasn't there, a check should be added to exclude
//     exponential notation from input because reconverting to string numbers >= 1e21 in JavaScript
//     invariably uses exponential notation for those numbers.
//
//    -No built-in functions to format a float with fixed decimals and left space padding, so I had to
//     implement padLeft and floatToFixed (<number>.toFixed() is not available in all JavaScripts).
//


//Relaunch in console (with CScript instead of WScript) if run directly:
if (WScript.FullName.toLowerCase().indexOf("wscript.exe") != -1) {
    var args = "";
    for (var i=0; i < WScript.Arguments.Count(); ++i) {
        if (args != "") {
            args += " ";
        }
        args = args + "\"" + WScript.Arguments.Item(i) + "\"";
    }

    var shell = WScript.CreateObject("WScript.Shell");
    shell.Run("%comspec% /c cscript //nologo \"" + WScript.ScriptFullName + "\" " + args + " & pause");
    WScript.Quit(0);
}


//NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
//that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
//but puts the function in a loop and counts 10000 calls).
//Returns how many prime numbers exist between 2 and n:
function findPrimes(n) {
    var i, j;
    var count = 0;

    //For each number up to 'n':
    for (i=2; i <= n; ++i) {
        for (j=2; j < i; ++j) {  //NOT using the sqrt optimization (for easier benchmarking).
            //If i divisible by j, it wasn't a prime number:
            if (i % j == 0) {
                break;
            }
        }
        if (i == j) {
            //The previous loop ended without divisors found. It is a prime number.
            ++count;
        }
    }

    return count;
}


function padLeft(s, toLength) {
    while (s.length < toLength) {
        s = String.fromCharCode(0x20) + s;
    }
    return s;
}


//Format a float to string as fixed point with the specified number of decimals - by JMC
//
//This is mostly equivalent to toFixed(), compatible with the EcmaScript standard definition of toFixed(),
//for older browsers (IE5, IE4, Netscape 4.79) and older javascripts (WSH in Win2000 and JS/ASP in IIS 5.0).
//If toFixed() exists, that is used instead.
//
//The fractional digits argument must be between 0 and 100 (same as modern toFixed() implementations).
//
//Examples:
//    floatToFixed(1.234, 0)   -->  "1"
//    floatToFixed(1.234, 2)   -->  "1.23"
//    floatToFixed(-1.995, 2)  -->  "-2.00"
//    floatToFixed(5, 3)       -->  "5.000
//    floatToFixed(5.3)        -->  "5"
//    floatToFixed(-0.002, 2)  -->  "-0.00"  (negative zero!, same as EcmaScript standard)
//    floatToFixed(1e21, 2)    -->  "1e21"   (exponential notation if abs(n) >= 1e21, same as EcmaScript standard)
//    floatToFixed(NaN, 2)     -->  "NaN"
//
//Good algorithms for conversion of floats to string are found in:
//    "How to Print Floating-Point Numbers Accurately" - 1990 - Guy Steele and Jon White.
//but those might require an arbitrary precision integer library.
//There is also a famous, a very long, self contained, C implementation based on that paper in:
//    "dtoa.c" - http://www.netlib.org/fp/index.html
//dtoa.c uses its own implementation of arbitrary precision integers, all contained in a single file.
//Similar algorithms are already used by the language when returning a float in string form (just not
//with a specific fixed number of decimals).
//
//  The algorithm below prints the number to string, and parses the exponent (if the number was big or
//small enough to be returned with exponential notation with toString()). It applies the exponent and
//then it adds or removes fractional digits to complete the number of requested decimals (by filling
//with 0s or truncating and rounding).
//  This approach is more precise than the approach of trying to extract the digits one by one by
//shifting and truncating: Since there is no access to the binary representation of the float, and
//since these floats are base-2, small errors would be accumulated when multiplying by 10 and
//subtracting the integer part to shift and extract the fractional digits.
//  So it is better to rely on the algorithm inside toString() for converting to base-10 digits first,
//like the present algorithm does.
//
function floatToFixed(x, decimalPlaces) {
    if (typeof (1.0).toFixed == "function") {
        return x.toFixed(decimalPlaces);
    }

    //Truncate digits argument to integer. If non numeric, NaN or undefined, take it as 0
    //(as in the toFixed() defined in EcmaScript):
    decimalPlaces = Math.floor(decimalPlaces);
    if (isNaN(decimalPlaces)) {
        decimalPlaces = 0;
    }
    //The EcmaScript standard toFixed definition requires supports of the digits argument to be at
    //least up to 20. Chrome and Firefox's toFixed() supports up to 100 fractional digits.
    if (decimalPlaces < 0 || decimalPlaces > 100) {
        //Can't throw a RangeError in old JavaScripts without the "throw" statement.
        //This will have to do:
        return "ERROR: decimalPlaces argument must be between 0 and 100";
    }

    if (isNaN(x) || x == Infinity || x == -Infinity) {
        return x.toString();
    }

    //The EcmaScript standard toFixed() function returns toString (exponential notation)
    //when the magnitude is greater than or equal to 1e21:
    //This can be commented out to always have fixed point notation (but that wouldn't be standard):
    if (Math.abs(x) >= 1e21) {
        return x.toString();
    }

    //Parse exponent:
    var str = x.toString();
    var f = str;
    var exponent = 0;
    var expPos = str.indexOf("e");
    if (expPos != -1) {
        f = str.substring(0, expPos);
        exponent = str.substring(expPos + 1, str.length);
        exponent = exponent - 0;  //Convert to number
    }

    //Get negative sign and remove it:
    var isNegative = false;
    if (f.charAt(0) == "-") {
        f = f.substring(1);
        isNegative = true;
    }

    //Turn ".44" into "0.44" (needed at least for Netscape 4.79)
    if (f.charAt(0) == ".") {
        f = "0" + f;
    }

    //Get decimal point position and remove it:
    var integerDigits = f.length;
    var fractionalDigits = 0;
    var pointPos = f.indexOf(".");
    if (pointPos != -1) {
        integerDigits = pointPos;
        f = f.substring(0, pointPos) + f.substring(pointPos + 1, f.length);
        fractionalDigits = f.length - integerDigits;
    }

    //Shift according to exponent:
    fractionalDigits -= exponent;
    integerDigits += exponent;
    if (exponent < 0) {
        while (integerDigits < 1) {
            f = "0" + f;
            integerDigits += 1;
        }
    } else if (exponent > 0) {
        while (fractionalDigits < 0) {
            f += "0";
            fractionalDigits += 1;
        }
    }

    //Add 0's up to decimalPlaces if we have less than asked for:
    while (fractionalDigits < decimalPlaces) {
        f += "0";
        fractionalDigits += 1;
    }

    //Remove digits if we have more than asked for:
    if (fractionalDigits > decimalPlaces) {
        var firstDigitLeftOff = f.charAt(integerDigits + decimalPlaces);
        f = f.substring(0, integerDigits + decimalPlaces);
        fractionalDigits = decimalPlaces;

        //Propagate rounding if the first digit left off is greater than or equal to "5":
        if (firstDigitLeftOff >= "5") {
            var digitList = f.split("");
            var carry = true;
            var pos = digitList.length - 1;
            while (carry && pos >= 0) {
                var newChar = digitList[pos].charCodeAt(0) + 1;
                if (newChar > 0x39) {
                    newChar = 0x30;
                } else {
                    carry = false;
                }
                digitList[pos] = String.fromCharCode(newChar);
                --pos;
            }
            f = digitList.join("");
            if (carry && pos == -1) {
                f = "1" + f;
                integerDigits += 1;
            }
        }
    }

    //Add decimal point:
    if (decimalPlaces > 0) {
        f = f.substring(0, integerDigits) + "." + f.substring(integerDigits, f.length);
    }

    //Add negative sign:
    if (isNegative) {
        f = "-" + f;
    }

    return f;
}


function main() {
    if (WScript.Arguments.Count() != 1) {
        WScript.Echo("Quick and dirty single thread CPU benchmark - by JMC");
        WScript.Echo("Usage: ");
        WScript.Echo("        Pass an argument up to which prime numbers will be searched with");
        WScript.Echo("        an inefficient algorithm, useful to compare the single thread performance");
        WScript.Echo("        of the CPU");
        WScript.Echo("Example: ");
        WScript.Echo("        cscript //nologo " + WScript.ScriptName + " 304500");
        WScript.Echo("Notes: ");
        WScript.Echo("        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz");
        WScript.Echo("        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3.");
        WScript.Echo("        JavaScript/WSH: it takes 281.066s using WSH 5.8 in a 64bit Win8.1 VM.");
        WScript.Echo("        JavaScript/WSH: it takes 299.681s using WSH 5.7 in a 32bit WinXP SP3 VM.");
        WScript.Echo("        JavaScript/WSH: it takes 323.934s using WSH 5.8 in a 32bit Win7 SP1 VM.");
        WScript.Echo("        JavaScript/WSH: it takes 330.489s using WSH 5.8 in a 64bit Win7 SP1 BareMetal.");
        WScript.Echo("        JavaScript/WSH: it takes 410.531s using WSH 5.1 in a 32bit Win2000 SP4 VM.");
        WScript.Echo("");
        WScript.Quit(1);
    }

    var n = Math.floor(WScript.Arguments.Item(0) - 0);
    var MAX_SAFE_INTEGER = 9007199254740991;  //2^53 - 1. Max double that can act as a safe integer (n != n+1).
    if (isNaN(n) || Math.abs(n) > MAX_SAFE_INTEGER || WScript.Arguments.Item(0) != n + "" || n < 2) {
        WScript.StdErr.Write("ERROR: Argument '" + WScript.Arguments.Item(0) + "' not valid.\n");
        WScript.Quit(1);
    }

    var startTime = new Date().getTime();

    var count = findPrimes(n);

    var endTime = new Date().getTime();
    var elapsed = (endTime - startTime) / 1000.0;
    WScript.Echo("Elapsed: " + padLeft(floatToFixed(elapsed, 3), 6) + "s");  //Padding up to 6 places, and rouding to 3 decimals.

    WScript.Echo(count + " prime numbers were found between 2 and " + n);
}


main();

