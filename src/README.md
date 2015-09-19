Files and what they are.

Core Ni:

niparser.nim - The Nim parser which can be imported and used on its own.
ni.nim       - The Nim interpreter, imports niparser above
nitest.nim   - Accompanying tests for the Ni interpreter and parser
test.sh      - Trivial shell script to run nitest.nim

Ni interpreter extensions:

niextend     - A sample interpreter/parser extension module.
nipython     - Another sample extension module, needs the python Nim module which you can install using "nimble install python".


REPL:

nirepl.nim   - A trivial first shot at a read-eval-print loop for playing and for running interactive tutorials
