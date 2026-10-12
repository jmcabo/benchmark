#!/usr/bin/lua

--Benchmark in Lua by JMC
--
--
--Run:
--    ./benchmark.lua 304500
--
--
--Notes:
--    -Lua was created by Roberto Ierusalimschy, Luiz Henrique de Figueiredo, and Waldemar Celes in
--     1993 in a brazilian university.
--       Lua is an embeddable scripting language. It supports procedural programming, object-oriented
--     programming, functional programming, data-driven programming, and data description.
--       It is known for being a common choice of extension language for game engines, or other apps
--     that need to embed an extension language.
--
--    -In Lua 5.2 all numbers are represented as double precision floats, even integers.
--     The max and min doubles are:
--            1.7976931348623157e+308
--            -1.7976931348623157e+308
--     The max and min doubles that can work as "safe integers" ('n != n+1' and 'n != n-1') are:
--            9007199254740991    #2^53 - 1
--            -9007199254740991   #-2^53 + 1
--     The number '2^53 + 1 = 9007199254740993' cannot be represented exactly as double.
--
--    -From Lua 5.3 there are integers (64-bit in 64-bit linux), and also floats.
--
--    -Ensuring an integer input can be tricky: the 'tonumber' function also accepts floats as numbers
--     such as: "3.", "3.0", "3.5", "3.5e1", etc. In Lua 5.2, there are no ints internally, all numbers
--     are floats. Starting from Lua 5.3 there are ints and floats, and the new function math.tointeger(),
--     but that function accepts "3.5e1" as an int (35). The function math.floor() returns an int, but
--     just testing for 'n == math.floor(n)' will pass for "3.0" and for "12.3e1".
--
--
--Limitations:
--    -An extra test (reconverted integer != original string) is necessary after parsing the integer
--     argument to exclude strings like "123.", "123.0" or "12.3e1" (the tonumber() function already
--     returns nil for strings like "123abc"). Because of this extra test, an integer with a plus sign
--     is not considered valid: "+123".
--       I had to use string.format("%d", n) instead of tostring(n) to exclude "1e+14" too (tostring(n)
--     prints exponential notation, sprintf("%d", n) doesn't). But that function fails if the number
--     exceeds what can be represented as an integer. That is why I first check with pcall (protected call).
--       In Lua 5.2, I check against the maximum number that is the biggest float that doesn't loose
--     precision in the last digit and that still satisfies 'n != n+1'.
--     In Lua 5.3 we have true ints up to the biggest positive integer '2^63 - 1'.
--     The following can be used in the linux/mac shell to test the cases in Lua5.2:
--            for a in 123a 123. 123.0 123.5 123.9 12.3e1 1e+10 1e+20 1e+21 9007199254740993 9007199254740994 inf -inf nan -nan; do ./benchmark.lua $a; done
--     And this for Lua 5.3:
--            for a in 123a 123. 123.0 123.5 123.9 12.3e1 1e+10 1e+20 1e+21 9223372036854775808 inf -inf nan -nan; do lua5.3 ./benchmark.lua $a; done
--     Tested in: Lua 5.2 and Lua 5.3.
--


--NAIVE implementation. horribly O(n^2), and WITHOUT using sqrt optimization (on purpose so
--that it takes longer and is easier to benchmark. The 'sysbench' utility, uses the optimization
--but puts the function in a loop and counts 10000 calls).
--Returns how many prime numbers exist between 2 and n:
function findPrimes(n)
    local i, j
    local count = 0

    --For each number up to 'n':
    for i=2, n, 1 do
        j = 2
        while j < i do  --NOT using the sqrt optimization (for easier benchmarking).
            --If i divisible by j, it wasn't a prime number:
            if i % j == 0 then
                break
            end
            j = j + 1
        end

        if i == j then
            --The previous loop ended without divisors found. It is a prime number.
            count = count + 1
        end
    end

    return count
end


function main()
    if #arg ~= 1 then
        print "Quick and dirty single thread CPU benchmark - by JMC"
        print "Usage: "
        print "        Pass an argument up to which prime numbers will be searched with"
        print "        an inefficient algorithm, useful to compare the single thread performance"
        print "        of the CPU"
        print "Example: "
        print(string.format("        %s 304500", arg[0]))
        print "Notes: "
        print "        Searching up to 304500 takes almost exactly 10 seconds (9.7s) on an Intel i7 4770K @ 3.5GHz"
        print "        with benchmark.c compiled without optimizations using GCC, and 8.85s with -O3."
        print "        Lua: it takes 95.018s using Lua 5.2.3."
        print ""
        os.exit(1)
    end

    local n = tonumber(arg[1])
    if n ~= nil then
        n = math.floor(n)
    end
    local luaVersion = string.sub(_VERSION, -3)  --Example _VERSION: "Lua 5.2", "Lua 5.3", etc.
    local MAX_SAFE_INTEGER = 9007199254740991    --2^53 - 1. Max double that can act as a safe integer (n != n+1).
    if n == nil
       or (luaVersion < "5.3" and math.abs(n) > MAX_SAFE_INTEGER)
       or not pcall(string.format, "%d", n)
       or arg[1] ~= string.format("%d", n)
       or n < 2
    then
        io.stderr:write("ERROR: Argument '" .. arg[1] .. "' not valid.\n")
        os.exit(1)
    end

    collectgarbage()
    local startTime = os.clock()

    local count = findPrimes(n)

    local endTime = os.clock()
    local elapsed = endTime - startTime
    print(string.format("Elapsed: %6.3fs", elapsed))

    print(string.format("%d prime numbers were found between 2 and %d", count, n))
end


main()

