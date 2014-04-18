
import std.algorithm;
import std.array;
import std.range;
import std.stdio;
import std.traits;
import std.typecons;

enum digits  = "123456789";
enum rows    = "ABCDEFGHI";
enum columns = digits;

auto cross(A, B)(A a, B b)
{
    string[] product;
    // Cluster-fuck
    static if (isArray!A)
        foreach (char _a; a)
            static if (isArray!B) // (string, string)
                foreach (char _b; b)
                    product ~= [_a, _b];
            else                  // (string, char)
                product ~= [_a, cast(char) b];
    else
        static if (isArray!B)     // (char, string)
            foreach (char _b; b)
                product ~= [cast(char) a, _b];
        else                      // (char, char)
            static assert(0, "Can't cross (char, char)");

    return product;
}

auto createUnitlist()
{
    string[][] product;

    product ~= columns.map!(c => rows.cross(c)).array;
    product ~= rows.map!(r => r.cross(columns)).array;
    product ~=
        ["123", "456", "789"]
        .map!(
            cs =>
                ["ABC", "DEF", "GHI"].map!(
                    rs => rs.cross(cs)
                ).array
        ).array
        .join
    ;

    return product;
}

enum squares = rows.cross(columns);
enum unitlist = createUnitlist;

unittest {
    assert(81 == squares.length);
    assert(27 == unitlist.length);

    writeln("All non-rt tests passed.");
}

int main(char[][] args) {
    // Associative arrays can not be created at compile-time or statically.
    string[][][string] units;
    string[][string] peers;

    // Generate units dict
    foreach (s; squares)
        units[s] = unitlist.filter!(u => u.assumeSorted.contains(s)).array;

    // Generate peers dict
    foreach (s; squares)
        peers[s] = units[s].join.filter!(x => x != s).unique.array;

    version(unittest) {
        assert(units["C2"] == [["A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2", "I2"],
                                   ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"],
                                   ["A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"]]);

        assert(peers["C2"] == ["A2", "B2", "D2", "E2", "F2", "G2", "H2", "I2",
                                           "C1", "C3", "C4", "C5", "C6", "C7", "C8", "C9",
                                           "A1", "A3", "B1", "B3"]);

        writeln("All rt tests passed.");
    }
    return 0;
}

/**
 * Simple helper functions.
 */

/// Eager unique set that does *not* require the input to be sorted.
string[] unique(R)(R input)
    if (isInputRange!R && !isInfinite!R && is(ElementType!R == string))
{
    bool[string] uniq;
    string[] result;
    foreach (str; input)
    {
        if (str in uniq)
            continue;

        uniq[str] = true;
        result ~= str;
    }
    return result;
}
