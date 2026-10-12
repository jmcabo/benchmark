#!/usr/bin/nodejs
// floatToFixed testing file in JavaScript for NodeJS - by JMC


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
    //testing:
    //if (typeof (1.0).toFixed == "function") {
    //    return x.toFixed(decimalPlaces);
    //}

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


//DEPRECATED:
//Format a float to string as fixed point with the specified number of decimals - by JMC
//
//This is mostly equivalent to toFixed(), compatible with the EcmaScript standard definition of toFixed(),
//for older browsers (IE5, IE4, Netscape 4.79) and older javascripts (WSH in Win2000 and JS/ASP in IIS 5.0).
//If toFixed() exists, that is used instead.
//
//The fractional digits argument must be between 0 and 100 (same as modern toFixed() implementations).
//
//Examples:
//    floatToFixed(1.12, 3)    -->  "1.120"
//    floatToFixed(9.999, 2)   -->  "10.00"
//    floatToFixed(5.3, 0)     -->  "5"
//    floatToFixed(5.3)        -->  "5"
//    floatToFixed(-0.001, 2)  -->  "-0.00"  (negative zero!, same as EcmaScript standard)
//    floatToFixed(1e21, 2)    -->  "1e21"   (exponential notation if abs(n) >= 1e21, same as EcmaScript standard)
//    floatToFixed(NaN, 2)     -->  "NaN"
//
//Note: Beware of results with 16 digits or more (counting both the integer and fractional parts).
//The mantissa of a double precision floating point number is only 53 bits wide. That means that
//the mantissa is not guaranteed to represent more than 15 decimal digits, and digits printed
//after that could be an approximation or garbage.
//
//Better algorithms for conversion of floats to string are found in:
//    "How to Print Floating-Point Numbers Accurately" - 1990 - Guy Steele and Jon White.
//but those might require an arbitrary precision integer library.
//There is also a famous, a very long, self contained, C implementation based on that paper in:
//    "dtoa.c" - http://www.netlib.org/fp/index.html
//dtoa.c uses its own implementation of arbitrary precision integers, all contained in a single file.
//
//BUGS:
//    floatToFixed_ShiftDigitsToInt(12.0002, 20)  -->  12.00019999999999684268  (should be "12.00020000000000000000")
//
//    Also, if commenting exp notation above 1e21, it goes into infinite loop with (1e308, 3), and gives nasty
//    approximation errors with (1e308, 0).
//
function floatToFixed_ShiftDigitsToInt(n, digits) {
    //testing:
    //if (typeof (1.0).toFixed == "function") {
    //    return n.toFixed(digits);
    //}

    //Truncate digits argument to integer. If non numeric, NaN or undefined, take it as 0
    //(as in the toFixed() defined in EcmaScript):
    digits = Math.floor(digits);
    if (isNaN(digits)) {
        digits = 0;
    }
    //The EcmaScript standard toFixed definition requires supports of the digits argument to be at
    //least up to 20. Chrome and Firefox's toFixed() supports up to 100 fractional digits.
    if (digits < 0 || digits > 100) {
        //Can't throw a RangeError in old JavaScripts without the "throw" statement.
        //This will have to do:
        return "ERROR: digits argument must be between 0 and 100";
    }

    if (isNaN(n) || n == Infinity || n == -Infinity) {
        return n.toString();
    }

    var isNeg = false;
    var f = n;
    if (n < 0) {
        isNeg = true;
        f = -n; //abs
    }
    //The EcmaScript standard toFixed() function returns toString (exponential notation)
    //when the magnitude is greater than or equal to 1e21:
    if (f >= 1e21) {
        return n.toString();
    }
    //Shift digits to integer, round and convert digits to string one by one:
    f = Math.round(f * Math.pow(10, digits));
    var str = "";
    while (f != 0) {
        str = Math.floor(f % 10) + str;
        f = Math.floor(f / 10);
    }
    //Fill with zeros up to digits:
    var zeros = "";
    while (zeros.length + str.length < digits + 1) {
        zeros += "0";
    }
    str = zeros + str;
    //Insert decimal dot:
    if (digits > 0) {
        str = str.substr(0, str.length - digits) + "." + str.substr(str.length - digits);
    }
    //Negative sign:
    if (isNeg) {
        str = "-" + str;
    }
    return str;
}


function padRight(s, toLength) {
    while (s.length < toLength) {
        s += String.fromCharCode(0x20);
    }
    return s;
}


function testFloatToFixed(x, decimalPlaces) {
    var msg = padRight(x + " " + decimalPlaces, 10);
    msg += "  -->  " + floatToFixed(x, decimalPlaces);
    msg += "  -->  " + floatToFixed_ShiftDigitsToInt(x, decimalPlaces);
    console.log(msg);
}


function main() {
    testFloatToFixed(1.2, 3.6);
    testFloatToFixed(1.2, 3);
    testFloatToFixed(0.2, 3);
    testFloatToFixed(1.2e-7, 3);
    testFloatToFixed(1.2e-7, 8);
    testFloatToFixed("1.2e5", 3);
    testFloatToFixed(123, 3);
    testFloatToFixed(-0.2, 3);
    testFloatToFixed(-0.002, 2);
    testFloatToFixed(9.999, 2);
    testFloatToFixed(NaN, 2);
    testFloatToFixed(12.0002, 20);
    testFloatToFixed(1e30, 0);
    testFloatToFixed(12.099, 2);
    testFloatToFixed(-1.996, 2);
    testFloatToFixed(0.9, 0);
    testFloatToFixed(3/4, 3);
}


main();

