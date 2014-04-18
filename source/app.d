
import std.algorithm;
import std.array;
import std.conv;
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

static squares = rows.cross(columns);
static unitlist = createUnitlist;

static string[][][string] units;
static string[][string] peers;

unittest {
    assert(81 == squares.length);
    assert(27 == unitlist.length);

    assert(units["C2"] == [["A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2", "I2"],
                           ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"],
                           ["A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"]]);

    assert(peers["C2"] == ["A2", "B2", "D2", "E2", "F2", "G2", "H2", "I2",
                           "C1", "C3", "C4", "C5", "C6", "C7", "C8", "C9",
                           "A1", "A3", "B1", "B3"]);

    writeln("All non-rt tests passed.");
}

static this()
{
    units = squares.map!(s => tuple(s, unitlist.filter!(u => u.assumeSorted.contains(s)).array)).assocArray;
    peers = squares.map!(s => tuple(s, units[s].join.filter!(x => x != s).unique.array)).assocArray;
}

int main(char[][] args) {
    return 0;
}

/**
 * Sudoku-related helper functions.
 */

/// Convert grid to a dict of possible values, {square: digits}, or
/// return False if a contradiction is detected.
auto parse_grid(string grid)
{
    auto values = squares.map!(s => tuple(s, digits)).assocArray;
    foreach (s, d; grid.grid_values)
    {
        if (digits.contains(d))
        {
            values[s] = [cast(char) d];
        }
    }

    return values;
}

/// Convert grid into a dict of {square: char} with '0' or '.' for empties.
auto grid_values(string grid)
{
    auto chars = grid
        .filter!(c => digits.contains(c) || "0.".contains(c))
        .map!(c => c == '.' ? '0' : c) // Normalize . and 0 to 0
        .array
    ;
    assert(81 == chars.length, to!string(chars.length));
    return squares.zip(chars).assocArray;
}

unittest {
    auto grid1 = "4.....8.5.3..........7......2.....6.....8.4......1.......6.3.7.5..2.....1.4......";
    auto grid2 = "
400000805
030000000
000700000
020000060
000080400
000010000
000603070
500200000
104000000";
    auto grid3 = "
4 . . |. . . |8 . 5
. 3 . |. . . |. . .
. . . |7 . . |. . .
------+------+------
. 2 . |. . . |. 6 .
. . . |. 8 . |4 . .
. . . |. 1 . |. . .
------+------+------
. . . |6 . 3 |. 7 .
5 . . |2 . . |. . .
1 . 4 |. . . |. . .
";

    auto grid1_vals = grid1.grid_values;
    auto grid2_vals = grid2.grid_values;
    auto grid3_vals = grid3.grid_values;

    assert(grid1_vals == grid2_vals);
    assert(grid2_vals == grid3_vals);
    assert(grid3_vals == grid1_vals);

    auto grid1_parsed = grid1.parse_grid;
    auto grid2_parsed = grid2.parse_grid;
    auto grid3_parsed = grid3.parse_grid;

    assert(grid1_parsed == grid2_parsed);
    assert(grid2_parsed == grid3_parsed);
    assert(grid3_parsed == grid1_parsed);

    writeln("All grid-parsing functions passed.");
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

bool contains(C)(string haystack, C needle)
{
    return haystack.countUntil(needle) != -1;
}
