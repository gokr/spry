# Spry

[![nimble](https://raw.githubusercontent.com/yglukhov/nimble-tag/master/nimble_js.png)](https://github.com/yglukhov/nimble-tag)

[![Build Status](https://travis-ci.org/gokr/spry.svg?branch=master)](https://travis-ci.org/gokr/spry)

[![Chat on Discord](https://img.shields.io/discord/605489766028541972?label=chat%20about%20Spry)](https://discord.gg/mK8HZNd)


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
* You find Spry cool and would like to port it to another host language
* ...or you just love freaky programming language ideas!

## Installation

Spry only depends on Nim, so it should work fine on Windows, OSX, Linux etc, but for the moment **I only use Linux for Spry development**. The shell scripts will probably be rewritten in nimscript and thus everything can be fully cross platform - feel free to help me with that!

### Vagrant
Included is a VagrantFile for Ubuntu 18.04. If you have vagrant just do `vagrant up` and `vagrant ssh` into it to find spry installed. Test with `ispry` - the "interactive spry" REPL, or `spry --version`.

### LXC
The following commands can get you running inside LXC very quickly, tested on Ubuntu 19.04:

Start a Ubuntu 20.04 (Focal Fossa, LTS) LXC machine and login to it:

    lxc launch ubuntu:20.04 spry
    lxc exec spry -- su --login ubuntu

Install dependencies, Nim and eventually Spry itself. Note that this is not a minimal Spry but one that includes RocksDB, GUI, Python wrapper etc:

    sudp apt update
    sudo apt install gcc pkg-config libgtk-3-dev librocksdb-dev libpython2.7
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh
    export PATH=/home/ubuntu/.nimble/bin:$PATH
    echo "export PATH=/home/ubuntu/.nimble/bin:$PATH" >> .profile
    nimble refresh
    nimble install spry

Then make sure Spry works:

    ubuntu@spry:~$ spry --version
    Spry 0.8.0
    ubuntu@spry:~$ spry -e "echo (3 + 4)"
    7
    ubuntu@spry:~$ ispry
    Welcome to interactive Spry!
    An empty line will evaluate previous lines, so hit enter twice.
    >>> 3 + 4
    >>> 
    7

### Docker
Thales Macedo Garitezi also made a Docker image for testing out the Spry REPL (ispry):

* Github: https://github.com/thalesmg/docker-spry
* Docker Hub: https://hub.docker.com/r/thalesmg/spry/

You can run it like this (with or without sudo):

    docker run --rm -it thalesmg/spry

...and that should get you into the REPL.

### Linux
The following should work on a Ubuntu/Debian, adapt accordingly for other distros.

1. Get GCC and [Nim](http://www.nim-lang.org)! I recommend using [choosenim](https://github.com/dom96/choosenim) or just following the official [instructions](http://nim-lang.org/download.html). Using choosenim it's as simple as:

    ```
    sudo apt install gcc pkg-config libgtk-3-dev librocksdb-dev libpython2.7
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh
    ```

2. Clone this repo. Then run `nimble install` in it. That should hopefully end up with `spry` and `ispry` built and in your path. You can also just run `nimble install spry` but then you have no access to examples etc in this git repository.

3. Try with say `spry --version` or `spry -e "echo (3 + 4)"`. And you can also try the REPL with `ispry`.

So now that you have installed Spry, you can proceed to play with the examples in the `examples` directory, see README in there for details.

### OSX
The following should work on OSX.

1. Install [Homebrew](https://brew.sh) unless you already have it.

2. Get [Nim](http://www.nim-lang.org)! I recommend using [choosenim](https://github.com/dom96/choosenim) or just following the official [instructions](http://nim-lang.org/download.html). Using choosenim it's as simple as:

    ```
    curl https://nim-lang.org/choosenim/init.sh -sSf | sh
    ```
You can also use brew (although not sure how good it follows Nim releases):
    ```
    brew install nim
    ```
3. Install extra dependencies, at the moment Rocksdb is one:
    ```
    brew install rocksdb
    ```
4. Clone this repo. Then run `nimble install` in it. That should hopefully end up with `spry` and `ispry` built and in your path. You can also just run `nimble install spry` but then you have no access to examples etc in this git repository.

5. Try with say `spry --version` or `spry -e "echo (3 + 4)"`. And you can also try the REPL with `ispry`.

So now that you have installed Spry, you can proceed to play with the examples in the `examples` directory, see README in there for details.

### Windows
You can "cheat" and try out Spry using a [zip with binaries]().
1. First you want to have [git installed](https://git-scm.com/download/win), and ideally **with the unix utilities** included so that some of the basic unix commands work on the Windows Command prompt.

2. Install Nim [using binaries](https://nim-lang.org/install_windows.html). Just follow the instructions and make sure to answer yes to include the directories in the PATH as **finish.exe** asks you if you want. NOTE: Currently using Choosenim on Windows will produce a 32 bit Nim and Spry, even on a 64 bit Windows, so I don't recommend Choosenim on Windows just yet.

3. There are no dependencies other than some dlls that are included in the Nim bin directory.

4. Clone this repo. Then run `nimble install` in it. That should hopefully end up with `spry` and `ispry` built and in your path. You can also just run `nimble install spry` but then you have no access to examples etc in this git repository.

5. Try with say `spry --version` or `spry -e "echo (3 + 4)"`. And you can also try the REPL with `ispry`.

So now that you have installed Spry, you can proceed to play with the examples in the `examples` directory, see README in there for details.

## Playing with it

1. If you want to build the interpreter manually, go into `src` and run
`nim c -d:release spry` to build the Spry interpreter, or `nim c -d:release ispry` for the REPL. It should produce a single binary each. That's the standard invocation to build a nim program in release mode.

2. Then go into examples and look at `hello.sy` as the next mandatory step :).
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
* Look at the various `examples`
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
