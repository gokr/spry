# Ni - We are the knights who say...

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)

[![Build Status](https://travis-ci.org/gokr/ni.svg?branch=master)](https://travis-ci.org/gokr/ni)

This is the **Ni** language, inspired by Rebol/Smalltalk/Self/Forth and Nim. Characteristics:

* A dynamically typed minimalistic language with a free form syntax similar to Rebol/Forth
* Parser produces an AST which in turn is interpreted by the interpreter
* Functional in nature and has closures and non local return
* Homoiconic which means code and data has the same form
* Meant to be 100% live and support interactive development

For the moment Ni is procedural, but an object model facilitating polymorphic dispatch is planned.

Here are [my articles about Ni](http://goran.krampe.se/category/ni)

## Why would I play with this?

* You love Rebol/Ren/Red but think it could perhaps be simplified, smaller and different :)
* You love Smalltalk but can imagine a simplified Smalltalkish language 
* You love Smalltalk but want to play with multicore or small platforms and more easily use the C/C++ eco system
* You love Nim but want to have a dynamic language running inside Nim
* ...or you just love freaky programming language ideas!

## Installation

Ni should only depend on Nim, so it should work fine on Windows, OSX, Linux etc, but
for the moment **I only use Linux for Ni development**. The shell scripts can probably be rewritten
in nimscript and thus everything can be fully cross platform.

### Linux

1. Get [Nim](http://www.nim-lang.org)! I recommend following the [instructions at the bottom](http://nim-lang.org/download.html).
2. Install Nimble, [the Nim package manager](https://github.com/nim-lang/nimble). Yeah, its very nice and simple to use. Its not really needed but makes some things easier.
3. Clone this repo. Then `cd ni/src && ./test.sh`. If it ends with "ALL GOOD"... **its all good :)**


The tests in `nitest.nim` is simply a range of asserts verifying that small Ni
programs execute and produce the expected output.

At this point you can use nimble to build & install Ni:

	nimble install

For the other platforms the steps are basically the same.

So now that you have installed Ni, you can proceed to play with the samples in the `samples` directory.
See README in there for details.

### Other platforms

...same procedure modulo platform differences :)


## Playing with it

1. If you want to build the interpreter manually, go into `src` and run
`nim c -d:release ni` to build the ni interpreter. It should produce a single binary.
That's the standard invocation to build a nim program in release mode.

2. Then go into samples and look at `hello.ni` is of course the next mandatory step :).
Its simply ni source being run by the `ni` executable interpreter using the "shebang" trick.

4. Then you can cd into bench and run `bench.sh` which starts by building the standalone ni interpreter
and then use it to run `factorial.ni` which is a Ni program that calculates `factorial 12`
100k times. It takes 2.7 seconds on my laptop which is quite slow, about 6x slower than
Rebol3, 20x slower than Python and 100x slower than Pharo Smalltalk. :) You can run `compare.sh`
to see yourself. With a bit of work removing unneeded silly stuff in the interpreter it should
be reasonable to reach Rebol3 in performance.

4. Ok, so at this point **you want to learn a bit more how Ni works**. Not much material around
yet since its evolving but you can:

* Look at `src/nitest.nim` which is a series of low level Ni code snippets and expected output.
* Look at the various `samples`
* Try running `tutorial1.ni` in tutorials, which is just showing we can do interactive tutorials with the repl
* Try out the repl by running `nirepl`
* And of course, read the source code `ni.nim` and `niparser.nim`. Its hopefully not that messy.

## History

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


