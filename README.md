This is a parser & interpreter for the Ni language, inspired by Rebol.

Ni is meant to mix with Nim and is not Rebol compatible, however most of the
language follows Rebol ideas with Nim and Smalltalk
mixed in. It is also meant to be a much smaller language than Rebol which has a
"nucleus" that is small, but then some parts needlessly complicated IMHO.

And oh, this is just for fun and I am not a good Nim hacker nor a language
implementor. :)

Noteworthy compared to Rebol:

* Values use pluggable instances of ValueParser so its very easy to add
 more literal "datatypes". They are not hard coded in the Parser/Interpreter.
 Later on more and more of Ni will reflect so they will probably end up being
 set up in Ni, as well as implementable in Ni.

* Fundamental values now are: nil, int64, float64, string, bool

* true, false and nil are singleton nodes in the Interpreter

* The Parser is a very simple recursive descent parser using the normal Nim
 object variant for the AST Nodes. Before parsing words and blocks it tries
 to parse using all registered value parsers in order.

 * Curly braces are not used for multiline string literals. Instead they are
 meant to create Contexts (similar to a Nim object).

 * There is only one style of function and its a closure.

 * Comments use # instead of ;

 * Literals generally use Nim syntax.


A "block Node" is the AST Node representing a block. It just has a seq[Node]
and is "just data". But using bind we can turn it into an executable
BlockClosure:

First time we do a block Node, we lazily bind. bind calls resolve on the
block node so that words are resolved to bindings. Then bind creates a
BlockClosure wrapping the block Node with a Context.

See primDo, primResolve, primClosure.
