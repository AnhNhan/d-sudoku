
import std.algorithm;
import std.array;
import std.conv;
import std.range;
import std.stdio;
import std.string;
import std.traits;
import std.typecons;

import stupid_helpers;

alias string[string] Grid;


/// Cross-product between string and chars.
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

template SudokuSolver(size_t size)
    if (size == 9 || size == 16 || size == 25)
{
    private string generate_range(A, B)(A start, B end)
    {
        string result;
        foreach (s; start..end + 1)
            result ~= s;
        return result;
    }

    enum digits = generate_range('1', '1' - 1 + size);
    enum rows   = generate_range('A', 'A' - 1 + size);
    static if (size < 10)
        enum cols = digits;
    else // Use lower case letters instead of numbers when we run out of digits
        enum cols = generate_range('a', 'a' - 1 + size);

    static squares = rows.cross(cols);
    static unitlist = [
        cols.map!(c => rows.cross(c)).array,
        rows.map!(r => r.cross(cols)).array,
        // TODO: Make this more generic, this currently is hard-coded for size 9
        ["123", "456", "789"]
            .map!(
                cs =>
                    ["ABC", "DEF", "GHI"].map!(
                        rs => rs.cross(cs)
                    ).array
            ).array
            .join
    ].join;

    static string[][][string] units;
    static string[][string] peers;

    static this()
    {
        units = squares.map!(s => tuple(s, unitlist.filter!(u => u.assumeSorted.contains(s)).array)).assocArray;
        peers = squares.map!(s => tuple(s, units[s].join.filter!(x => x != s).unique.array)).assocArray;
    }

    /// Convert grid to a dict of possible values, {square: digits}, or
    /// return False if a contradiction is detected.
    auto parse_grid(string grid)
    {
        auto values = squares.map!(s => tuple(s, digits)).assocArray;

        foreach (s, d; grid.grid_values)
            if (digits.contains(d) && !values.assign(s, cast(char) d))
                throw new Exception("Contradiction!");

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
        assert(size ^^ 2 == chars.length, to!string(chars.length));
        return squares.zip(chars).assocArray;
    }

    /// Eliminate all the other values (except d) from values[s] and propagate.
    /// Return values, except return False if a contradiction is detected.
    bool assign(ref Grid values, string s, char d)
    {
        auto other_values = values[s].replace([d], "");
        return all!"a"(other_values.map!(d2 => values.eliminate(s, cast(char) d2)));
    }

    /// Eliminate d from values[s]; propagate when values or places <= 2.
    /// Return values, except return False if a contradiction is detected.
    bool eliminate(ref Grid values, string s, char d)
    {
        if (!values[s].contains(d))
            return true;

        values[s] = values[s].replace([d], "");

        // (1) If a square s is reduced to one value d2, then eliminate d2 from the
        // peers
        if (values[s].length == 0)
            return false; // Contradiction: removed last value
        else if (values[s].length == 1)
        {
            auto d2 = values[s][0]; // [0] so we get the char
            if (!all!"a"(peers[s].map!(s2 => values.eliminate(s2, cast(char) d2))))
                return false;
        }

        // (2) If a unit u is reduced to only one place for a value d, then put it
        // there.
        foreach (u; units[s])
        {
            auto dplaces = u.filter!(_s => values[_s].contains(d)).array;
            if (dplaces.length == 0)
                return false; // Contradiction: no place for this value
            else if (dplaces.length == 1)
            {
                // d can only be in one place in unit; assign it there
                if (!values.assign(dplaces[0], cast(char) d))
                    return false;
            }
        }

        return true;
    }

    /// Render these values as a 2D grid into a string.
    string render(Grid values)
    {
        // TODO: Generice this function for other grid sizes
        auto width = 1 + squares.map!(s => values[s].length).reduce!max;
        auto line = "-".repeat(width * 3).array.join.repeat(3).array.join("+");

        auto appender = appender!string;

        foreach (char r; rows)
        {
            appender.put(
                cols.map!(c => values[[r, cast(char) c]].center(width) ~ ("36".contains(c) ? "|" : ""))
                    .join
                    ~ "\n"
            );
            if ("CF".contains(r))
                appender.put(line ~ "\n");
        }
        return appender.data;
    }
}

unittest {
    static assert( __traits(compiles, SudokuSolver!9.digits ));
    static assert( __traits(compiles, SudokuSolver!16.digits));
    static assert( __traits(compiles, SudokuSolver!25.digits));

    static assert(!__traits(compiles, SudokuSolver!10.digits));

    alias SudokuSolver!9 Solver;
    assert(Solver.digits == "123456789", Solver.digits);
    assert(Solver.rows   == "ABCDEFGHI", Solver.rows  );

    assert(81 == Solver.squares.length );
    assert(27 == Solver.unitlist.length);

    assert(Solver.units["C2"] == [["A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2", "I2"],
                           ["C1", "C2", "C3", "C4", "C5", "C6", "C7", "C8", "C9"],
                           ["A1", "A2", "A3", "B1", "B2", "B3", "C1", "C2", "C3"]]);

    assert(Solver.peers["C2"] == ["A2", "B2", "D2", "E2", "F2", "G2", "H2", "I2",
                           "C1", "C3", "C4", "C5", "C6", "C7", "C8", "C9",
                           "A1", "A3", "B1", "B3"]);

    writeln("Static stuff passed.");

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

    auto grid1_vals = Solver.grid_values(grid1);
    auto grid2_vals = Solver.grid_values(grid2);
    auto grid3_vals = Solver.grid_values(grid3);

    assert(grid1_vals == grid2_vals);
    assert(grid2_vals == grid3_vals);
    assert(grid3_vals == grid1_vals);

    auto grid1_parsed = Solver.parse_grid(grid1);
    auto grid2_parsed = Solver.parse_grid(grid2);
    auto grid3_parsed = Solver.parse_grid(grid3);

    assert(grid1_parsed == grid2_parsed);
    assert(grid2_parsed == grid3_parsed);
    assert(grid3_parsed == grid1_parsed);

    writeln("All grid-parsing functions passed.");

    auto grid4 = "003020600900305001001806400008102900700000008006708200002609500800203009005010300";

    // Note: This test already solves its first sudoku. This is because of all
    //       the processing all the processing already happening while parsing.

    // One line, because trailing whitespace :/
    auto grid4_rendered = "4 8 3 |9 2 1 |6 5 7 \n9 6 7 |3 4 5 |8 2 1 \n2 5 1 |8 7 6 |4 9 3 \n------+------+------\n5 4 8 |1 3 2 |9 7 6 \n7 2 9 |5 6 4 |1 3 8 \n1 3 6 |7 9 8 |2 4 5 \n------+------+------\n3 7 2 |6 8 9 |5 1 4 \n8 1 4 |2 5 3 |7 6 9 \n6 9 5 |4 1 7 |3 8 2 \n";

    assert(grid4_rendered == Solver.render(Solver.parse_grid(grid4)));

    writeln("Grid rendering passed.");
}
