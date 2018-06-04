# Spry

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)

[![Build Status](https://travis-ci.org/gokr/spry.svg?branch=master)](https://travis-ci.org/gokr/spry)

[![Join the chat at https://gitter.im/gokr/spry](https://badges.gitter.im/gokr/spry.svg)](https://gitter.im/gokr/spry?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge)


This is the [Spry language](http://sprylang.se), inspired by Rebol/Smalltalk/Self/Forth and Nim. Characteristics:

* A dynamically typed minimalistic language with a free form syntax similar to Rebol/Forth
* Parser produces an AST which in turn is interpreted by the interpreter
* Functional in nature and has closures and non local return
* Homoiconic which means code and data has the same form
* Meant to be 100% live and support interactive development

Here are [my articles about Spry](http://goran.krampe.se/category/spry)

## Why would I play with this?

* You find ideas in Rebol/Ren/Red interesting but would like something different :)
* You love Smalltalk but can imagine a simplified similar language and want to play with multicore or small platforms and more easily use the C/C++/Nim eco system
* You love Nim but want to have a dynamic language running inside Nim
* ...or you just love freaky programming language ideas!

## Installation

Spry only depends on Nim, so it should work fine on Windows, OSX, Linux etc, but
for the moment **I only use Linux for Spry development**. The shell scripts will probably be rewritten in nimscript and thus everything can be fully cross platform - feel free to help me with that!

### Vagrant
Included is a VagrantFile for Ubuntu 16.04. Just do `vagrant up` and `vagrant ssh` into it to find spry installed. Test with `ispry` - the "interactive spry" REPL.

### Docker
Thales Macedo Garitezi also made a Docker image for testing out Spry:

* Github: https://github.com/thalesmg/docker-spry
* Docker Hub: https://hub.docker.com/r/thalesmg/spry/

### Linux
The following should work on a Ubuntu/Debian, adapt accordingly for other distros.

1. Get [Nim](http://www.nim-lang.org)! I recommend using [choosenim](https://github.com/dom96/choosenim) or just following the official [instructions](http://nim-lang.org/download.html). Using choosenim it's as simple as:

    ```
    sudo apt install gcc
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh
    ```

2. Install dependencies, currently this is libsnappy-dev (or libsnappy1v5):
    ```
    sudo apt install libsnappy-dev
    ```
3. Clone this repo. Then run `nimble install` in it.
4. Finally run all tests using `cd tests && ./run.sh` (runjs.sh is for running them in nodejs, but not fully green right now)

So now that you have installed Spry, you can proceed to play with the samples in the `samples` directory, see README in there for details.

### OSX
The following should work on OSX.

0. Install [Homebrew](https://brew.sh) unless you already have it.

1. Get [Nim](http://www.nim-lang.org)! I recommend using [choosenim](https://github.com/dom96/choosenim) or just following the official [instructions](http://nim-lang.org/download.html). Using choosenim it's as simple as:

    ```
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh
    ```

2. Install dependencies, currently this is only snappy and we can get it using:
    ```
    brew install snappy
    ```

3. Clone this repo. Then run `nimble install` in it. That should hopefully end up with `spry` and `ispry` built and in your path.

4. Try with say `spry --version` or `spry -e "echo (3 + 4)"`. And you can also try the REPL with `ispry`.

5. Finally run all tests using `cd tests && ./run.sh` (runjs.sh is for running them in nodejs, but not fully green right now)

So now that you have installed Spry, you can proceed to play with the samples in the `samples` directory, see README in there for details.

### Windows
First you want to have git installed, and most happily with the unix utilities included so that some of the basic unix commands work on the Windows Command prompt.

1. Installing Nim on Windows using choosenim doesn't fly ([blocked by issue 35](https://github.com/dom96/choosenim/issues/35), well, ok, the older version worked but that created a 32 bit Nim compiler which may be less optimal. You will need to follow [official installation procedure](https://nim-lang.org/install_windows.html), which is quite easy, just download the zip, unpack it and run `finish.exe` from a command prompt and follow the interactive questions.

2. Install dependencies, currently this is the snappy dll which is used for fast compression. The most reasonable place I found a precompiled version of it was on [https://snappy.machinezoo.com/downloads/](https://snappy.machinezoo.com/downloads/). Download, unpack and take the `native/snappy64.dll` or `native/snappy32.dll` and copy the proper one (presumably 64 bits) to a place where it can be found, for example in `c:\Users\<youruser>\.nimble\bin` and rename it to `libsnappy.dll`. I will fix so that it's included somehow.

3. Clone this repo. Then run `nimble install` in it. That should hopefully end up with `spry` and `ispry` built and in your path.

4. Try with say `spry --version` or `spry -e "echo (3 + 4)"`. And you can also try the REPL with `ispry`.

5. Finally run all tests using `cd tests && sh run.sh` (runjs.sh is for running them in nodejs, but not fully green right now). On windows two tests fail as of writing this.


## Playing with it

1. If you want to build the interpreter manually, go into `src` and run
`nim c -d:release spry` to build the Spry interpreter, or `nim c -d:release ispry` for the REPL. It should produce a single binary each. That's the standard invocation to build a nim program in release mode.

2. Then go into samples and look at `hello.sy` as the next mandatory step :).
Its simply Spry source being run by the `spry` executable interpreter using the "shebang" trick.

4. Then you can cd into bench and run `bench.sh` which starts by building the standalone Spry interpreter
and then use it to run `factorial.sy` which is a program that calculates `factorial 12`
100k times. It takes 2.7 seconds on my laptop which is quite slow, about 6x slower than
Rebol3, 20x slower than Python and 100x slower than Pharo Smalltalk. :) You can run `compare.sh`
to see yourself. With a bit of work removing unneeded silly stuff in the interpreter it should
be reasonable to reach Rebol3 in performance.

4. Ok, so at this point **you want to learn a bit more how Spry works**. Not much material around yet since its evolving but you can:

* On Linux or OSX you should be able to build a trivial "IDE", see below.
* Look at `tests/*.nim` which is a series of low level Spry code snippets and expected output.
* Look at the various `samples`
* Try running `tutorial1.sy` in tutorials, which is just showing we can do interactive tutorials with the repl
* Try out the interactive REPL by running `ispry`
* And of course, read the source code `spryvm.nim`. Its hopefully not that messy.

## IDE
There is also a beginning of a Spry VM module (src/modules/spryrawui.nim) for making GUI stuff using the excellent [libui](http://github.com/andlabs/libui) project. A small trivial little IDE written in Spry itself exists and you can build it on Linux or OSX.

* **OSX:** Just run `./makeideosx.sh` in `src` and if you are lucky that produces a binary file called `ideosx`. Try running it with `./ideosx`.
* **Linux:** Just run `./makeide.sh` in `src` and if you are lucky that produces a binary file called `ide`. Try running it with `./ide`.

## History
Spry started out as a Rebol inspired interpreter - since I felt the homoiconicity
of Rebol was interesting to experiment with. Lispish, but not insanely filled
with parenthesis :)

Then I started sliding towards Smalltalk when I added both support for infix
arguments (so that a "receiver" can be on the left, similar to Nim), and later
even keyword syntax for functions taking multiple arguments. I also changed func
definitions to be more light weight (compared to Rebol) like Smalltalk blocks.

Spry is meant to mix with Nim. The idea is to use Nim for heavy lifting and binding
with the outside world, and then let Spry be a 100% live dynamically typed
language inside Nim. Spry will stay a very small language, but hopefully useful.

And oh, this is just for fun and I am not a good Nim hacker nor a language
implementor. :)
