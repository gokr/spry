# Ni - We are the knights who say...

This is a parser & interpreter for the Ni language, inspired by
Rebol/Smalltalk/Self/Forth and Nim. Characteristics:

* Ni is dynamically typed with a free form syntax similar to Rebol/Forth
* Parser produces an AST which in turn is interpreted by the interpreter
* Ni is functional in nature and has closures
* Ni is homoiconic which means code and data has the same form

For the moment Ni is procedural, but an object model based on cloning and
delegation is planned.

## Evolving

Ni started out as a Rebol inspired interpreter - since I felt the homoiconicity
of Rebol was interesting to experiment with. Lispish, but not insanely filled
with parenthesis :)

Then I started sliding towards Smalltalk when I added both support for infix
arguments (so that a "receiver" can be on the left, similar to Nim), and later
even keyword syntax for functions taking multiple arguments. I also changed func
definitions to be more light weight (compared to Rebol) like Smalltalk blocks.

Ni is meant to mix with Nim. The idea is to use Nim for heavylifting and binding
with the outside world, and then let Ni be a 100% live dynamically typed
scripting engine inside Nim. Ni will stay a very small language, but hopefully useful.

And oh, this is just for fun and I am not a good Nim hacker nor a language
implementor. :)

## Playing with it

Sorry, I am only bothering with Linux right now, but Ni should run fine wherever
Nim works.

1. Start by running `test.sh`, it should build nitest.nim and run it verifying all
tests are green. nitest.nim is simply a range of asserts verifying that small Ni
programs execute and produce the expected output.

2. Run `nim c -d:release ni` to build the ni interpreter.

3. `./hello.ni` is of course the next mandatory step :). Its simply ni source being
run by the `ni` executable interpreter using the "shebang" trick.

4. Then you can run `bench.sh` which starts by building the standalone ni interpreter
and then use it to run `factorial.ni` which is a Ni program that calculates 12 factorial
100k times. It takes 2.6 seconds on my laptop which is quite slow, about 6x slower than
Rebol3, 20x slower than Python and 100x slower than Pharo Smalltalk. :) See compare.sh
but you need to download `r3` for Rebol3. With a bit of work removing unneeded silly
stuff in the interpreter it should be reasonable to reach Rebol3 in performance.

4. Ok, so at this point you want to learn a bit more how Ni works. Not much material around
yet since its evolving but you can:

* Look at nitest.nim
* Look at all the *.ni files
* Try running tutorial1.ni which is just showing we can do interactive tutorials with the repl
* Try out the repl

5. To see a silly example of how you can add primitives to the Ni interpreter for
being able to call into Nim, see `ni2nim.nim`. Also see `extend.nim` that shows how a Nim
module can extend the Ni interpreter.
