# Ni - We are the knights who say...

This is a parser & interpreter for the Ni language, inspired by Rebol.

Ni is meant to mix with Nim and is not Rebol compatible, however most of the
language follows Rebol ideas with Nim and Smalltalk
mixed in. It is also meant to be a much smaller language than Rebol which has a
"nucleus" that is small, but then some parts needlessly complicated IMHO.

And oh, this is just for fun and I am not a good Nim hacker nor a language
implementor. :)

## Noteworthy

* Values use pluggable instances of ValueParser so its very easy to add
 more literal "datatypes". They are not hard coded in the Parser/Interpreter.
 Later on more and more of Ni will reflect so they will probably end up being
 set up in Ni, as well as implementable in Ni.

* Fundamental values now are: nil, int, float, string, bool

* true, false and nil are singleton nodes in the Interpreter

* The Parser is a very simple recursive descent parser using objects for
 AST Nodes. Before parsing words and blocks it tries to parse using all
 registered value parsers in order. This makes it very easy to add literals.

* Curly braces are not used for multiline string literals. Exactly what to use
  them for I am undecided.

* There are two kinds of functions, builtins in Nim or funcs created from blocks
  in Rebol style, that are closures.

* Comments use # instead of ;

* Literals generally use Nim syntax.


A "block Node" is the AST Node representing a block. It just has a seq[Node]
and is "simply data". But using the func word we can turn it into an executable
function.

Resolving is currently done lazily the first time a block is used as code.

For example snippets, see nitest.nim.
