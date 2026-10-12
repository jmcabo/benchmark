#ifdef shell_shebang
#Compile and run when invoked as ./parseInt.c (Note: shell stops at first exec call):
gcc -Wall -O3 -o parseInt "$0"  &&  exec -a "$0" ./parseInt "$@"  ;  exec /bin/false
#endif
// parseInt testing file in C - by JMC

#include <stdio.h>
//For INT_MAX:
#include <limits.h>
//For errno:
#include <errno.h>
//For strtol (and malloc, free in test code):
#include <stdlib.h>
//For strlen in test code:
#include <string.h>


//Parses an int from a string in base 10, by correctly wrapping strtol() which returns a long.
//
//Returns the number and sets parseOk == 1 if the string represents a valid int. Returns 0 and sets
//parseOk == 0 and errno to EINVAL if the string is non numeric ("abc", "", " ", "a12" and "+" are
//considered non numeric).
//When the value underflows, INT_MIN is returned and parseOk is set to 0 and errno to ERANGE.
//When the value overflows, INT_MAX is returned and parseOk is set to 0 and errno to ERANGE..
//
//When 'junkAllowed' is non-zero, it allows extra non numeric chars and non space or tab chars after
//the number (example: "123a"). Otherwise returns 0 and sets parseOk to 0 and errno to EINVAL in that case.
//
//Spaces at the beginning or end are always allowed no matter the value of 'junkAllowed', as in " 123 ".
//
//The variable parseOk can be NULL if the caller is not interested in it.
//
//Notes:
//    -The standard functions atoi() and sscanf() produce undefined behaviour if the number in
//     the string is between INT_MAX and LONG_MAX in x86-x64 Linux, and they both always allow "junk"
//     after the number. In glibc, atoi() is equivalent to casting strtol() from long to int and ignoring
//     'end', which is wrong when sizeof(int) < sizeof(long) but it is allowed by the standard.
//    -Example: atoi("4294967419") returns 123 in 64-bit Linux, where an int is 4 bytes and a long is 8.
//    -This function fixes those issues, correctly wrapping strtol().
//    -Also, all three standard functions, atoi, sscanf and strtol allow spaces at the beginning, but if we
//     were to only check end != s && end != '\0' as strtol's man page suggests, we would introduce the
//     asymmetry of not allowing spaces at the end.
//    -The CommonLisp 'parse-integer' function always allows spaces at the end and has a ':junk-allowed'
//     argument, so parseInt is similar in those ways.
int parseInt(char* s, int junkAllowed, int* parseOk) {
    long parsedLong;
    char* end = s;
    int didParseSomething;
    int oldErrno = errno;
    //Parse:
    errno = 0;  //'errno' is the only correct way to know when the value underflows or overflows
                //Testing for LONG_MAX is wrong since in 32bits LONG_MAX == INT_MAX, and strtoll()
                //isn't always implemented by compilers. 'errno' is a thread-safe macro these days.
    parsedLong = strtol(s, &end, 10);
    //Before skipping trailing spaces, we need to make sure that the last char was numeric (Cases: "  ", " + ").
    didParseSomething = (end != s && (*(end - 1) >= '0' && *(end - 1) <= '9'));
    //Consider spaces or tabs after the number to be always ok:
    while (*end == 0x20 || *end == '\t') {
        ++end;
    }
    //Detect parsing error. If !junkAllowed, reject strings that are not fully numeric at the end (but accept " \t  +123  \t "):
    if ((errno != 0 && errno != ERANGE) || !didParseSomething || (*end != '\0' && !junkAllowed)) {
        if (parseOk) *parseOk = 0;
        errno = EINVAL;
        return 0;
    }
    //Fix undefined behaviour of atoi(s) and sscanf(s, "%d", &n):
    if (parsedLong > INT_MAX) {
        parsedLong = INT_MAX;
        errno = ERANGE;
    } else if (parsedLong < INT_MIN) {
        parsedLong = INT_MIN;
        errno = ERANGE;
    }
    //Whether strtol() set errno to ERANGE (bigger than LONG_MAX) or we did (bigger than INT_MAX),
    //return INT_MAX or INT_MIN and parseOk == 0:
    if (errno == ERANGE) {
        if (parseOk) *parseOk = 0;
        return (int) parsedLong;
    }
    //Return successfully parsed value:
    if (parseOk) *parseOk = 1;
    errno = oldErrno;
    return (int) parsedLong;
}


//The same as parseInt() but having no dependencies and without setting 'errno'. I figured that correctly
//wrapping strtol() required almost as many lines as implementing it from scratch (not really).
//This is what happens when APIs such as atoi, sscanf or strtol() are not specified the "right" way
//(just try atoi("4294967419") which returns 123 in 64-bit Linux, or atoi("123abc")).
//
//
//Parses an int from a string in base 10, from scratch, with no dependencies other than INT_MIN and INT_MAX.
//
//Returns the number and sets parseOk == 1 if the string represents a valid int. Returns 0 and sets
//parseOk == 0 if the string is non numeric ("abc", "", " ", "a12" and "+" are considered non numeric).
//When the value underflows, INT_MIN is returned and parseOk is set to 0.
//When the value overflows, INT_MAX is returned and parseOk is set to 0.
//
//When 'junkAllowed' is non-zero, it allows extra non numeric chars and non space or tab chars after
//the number (example: "123a"). Otherwise returns 0 and sets parseOk to 0 in that case.
//
//Spaces at the beginning or end are always allowed no matter the value of 'junkAllowed', as in " 123 ".
//
//The variable parseOk can be NULL if the caller is not interested in it.
//
//Notes:
//    -The standard functions atoi() and sscanf() produce undefined behaviour if the number in
//     the string is between INT_MAX and LONG_MAX in x86-x64 Linux, and they both always allow "junk"
//     after the number. In glibc, atoi() is equivalent to casting strtol() from long to int and ignoring
//     'end', which is wrong when sizeof(int) < sizeof(long) but it is allowed by the standard.
//    -Example: atoi("4294967419") returns 123 in 64-bit Linux, where an int is 4 bytes and a long is 8.
//    -This function fixes those issues, parsing an int from scratch.
//    -Also, all three standard functions, atoi, sscanf and strtol allow spaces at the beginning, but if we
//     were to use strtol and only check end != s && end != '\0' as strtol's man page suggests, we would
//     introduce the asymmetry of not allowing spaces at the end.
//    -The CommonLisp 'parse-integer' function always allows spaces at the end and has a ':junk-allowed'
//     argument, so parseInt is similar in those ways.
int parseInt_FromScratch(char* s, int junkAllowed, int* parseOk) {
    unsigned int r = 0;       //Need unsigned to represent -INT_MIN == INT_MAX+1 as a positive number.
    unsigned int preMultMax;  //Overflow limit for previous value.
    int preMultMaxDigit;      //Overflow limit for next digit.
    int sign = 0;
    int didParseSomething = 0;
    int overflow = 0;
    //Skip spaces and tabs:
    while (*s == 0x20 || *s == '\t') ++s;
    //Read optional sign:
    if (*s == '+') {
        ++s;
    } else if (*s == '-') {
        //Negative sign. Conversion will happen with positive intermediate values and neg at the end.
        sign = 1;
        ++s;
    }
    //Compute limits for overflow detection. For 32-bit sign=0: preMultMax=214748364, preMultMaxDigit=7.
    //Note: Since in C we don't have access to the JO assembly instruction (jump if integer overflow),
    //it is necessary to check for overflow like this. Another way is to divide by 10 after the
    //multiplication and see if it matches, and also check the result of the digit addition.
    preMultMax = (sign)? -(INT_MIN / 10) : INT_MAX / 10;
    preMultMaxDigit = (sign)? -(INT_MIN % 10) : INT_MAX % 10;
    //Convert decimal digits:
    while (*s >= '0' && *s <= '9') {
        didParseSomething = 1;
        if (r > preMultMax || (r == preMultMax && (*s - 0x30) > preMultMaxDigit)) {
            overflow = 1;
            break;
        }
        r *= 10;  //Shift existing digits to the left.
        r += *s - 0x30;  //Convert digit. ASCII digits go from 0x30 to 0x39.
        ++s;
    }
    //Skip remaining digits after overflow detected. If the string ends with non numeric chars,
    //that error has priority over overflow (ie: return 0 instead of MAX or MIN).
    if (overflow) {
        while (*s >= '0' && *s <= '9') ++s;
    }
    //Skip spaces to see if the string is well formed, ie: would match this regex /^\s*[+-]\?[0-9]\+\s*$/
    while (*s == 0x20 || *s == '\t') ++s;
    //Validate:
    if (!didParseSomething || (*s != '\0' && !junkAllowed)) {
        if (parseOk) *parseOk = 0;
        return 0;
    }
    //Overflow / Underflow:
    if (overflow) {
        if (parseOk) *parseOk = 0;
        return (sign)? INT_MIN : INT_MAX;
    }
    //Success. Return value:
    if (parseOk) *parseOk = 1;
    if (sign) {
        return - (int) r;
    }
    return (int) r;
}


void testParseInt(char* s, int junkAllowed, int expectedN, int expectedParseOk) {
    int n;
    int parseOk;
    int MSG_SIZE = 1024;
    char* msgLeft;
    size_t sLength;
    char* sTabs;
    char* sTabsIt;

    //Parse:
    n = parseInt(s, junkAllowed, &parseOk);
    //n = parseInt_FromScratch(s, junkAllowed, &parseOk);

    //Show tabs as one 'T' char, otherwise it breaks the alignment. Replacing '\t' for 'T':
    sLength = strlen(s);
    sTabs = malloc(sLength + 1);
    strncpy(sTabs, s, sLength + 1);
    sTabsIt = sTabs;
    while (*sTabsIt != '\0') {
        if (*sTabsIt == '\t') {
            *sTabsIt = 'T';
        }
        ++sTabsIt;
    }

    //Print part to the left of the arrow to a string, so we can pad it to 28 chars and align it:
    msgLeft = malloc(MSG_SIZE);
    msgLeft[0] = 0;
    snprintf(msgLeft, MSG_SIZE, "'%s', %d", sTabs, junkAllowed);

    //Print results:
    printf("%s: %28s   -->  %11d, %d (expected: %d, %d)\n",
        ((n == expectedN && parseOk == expectedParseOk)? "OK" : "ERROR"),
        msgLeft,
        n, parseOk, expectedN, expectedParseOk
    );

    //Cleanup:
    free(msgLeft);
    free(sTabs);
}


int main(int argc, char** argv) {
    printf("Status:           s, junkAllowed   -->            n, parseOk\n");
    printf("============================================================\n");
    testParseInt("123", 0, 123, 1);
    testParseInt(" \t  123", 0, 123, 1);
    testParseInt("a 123", 0, 0, 0);
    testParseInt("123a", 0, 0, 0);
    testParseInt("123a", 1, 123, 1);
    testParseInt("+123", 0, 123, 1);
    testParseInt("-123", 0, -123, 1);
    testParseInt("--123", 0, 0, 0);
    testParseInt("++123", 0, 0, 0);
    testParseInt("+", 0, 0, 0);
    testParseInt("", 0, 0, 0);
    testParseInt("+", 1, 0, 0);
    testParseInt(" + ", 0, 0, 0);
    testParseInt(" + ", 1, 0, 0);
    testParseInt("", 1, 0, 0);
    testParseInt("  ", 0, 0, 0);
    testParseInt("  ", 1, 0, 0);
    testParseInt(" \t 123 \t ", 1, 123, 1);
    testParseInt(" \t 123 \t ", 0, 123, 1);
    testParseInt(" \t 123 \t a", 0, 0, 0);
    testParseInt(" \t 123 \t a", 1, 123, 1);
    testParseInt("123 0", 0, 0, 0);
    testParseInt("123 0", 1, 123, 1);
    testParseInt("2147483647", 0, 2147483647, 1);
    testParseInt("-2147483648", 0, INT_MIN, 1);
    testParseInt("1000000000", 0, 1000000000, 1);
    testParseInt("10000000000", 0, 2147483647, 0);
    testParseInt("10000000000abc", 0, 0, 0);
    testParseInt("10000000000abc", 1, 2147483647, 0);
    testParseInt("-2147483649", 0, INT_MIN, 0);
    testParseInt("-21474836400", 0, INT_MIN, 0);
    testParseInt("2147483648", 0, 2147483647, 0);
    testParseInt("2147483649", 0, 2147483647, 0);
    testParseInt("21474836400", 0, 2147483647, 0);
    testParseInt("92000000000000", 0, 2147483647, 0);
    testParseInt("9200000000000000000000", 0, 2147483647, 0);
    testParseInt("9223372036854775807", 0, 2147483647, 0);
    testParseInt("9223372036854775808", 0, 2147483647, 0);
    //This test case exercises the IF that checks for overflow after the multiplication in parseInt_FromScratch():
    testParseInt("4294967296", 0, 2147483647, 0);
    testParseInt("-4294967296", 0, INT_MIN, 0);
    return 0;
}


