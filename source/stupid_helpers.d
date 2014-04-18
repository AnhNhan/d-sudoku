
module stupid_helpers;

import std.algorithm;
import std.array;
import std.range;
import std.traits;

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

bool opBinaryRight(string op, C)(string haystack, C needle) {
   static if (op == "in") return haystack.contains(needle);
   else static assert(0, "Operator " ~ op ~ " not implemented");
}
