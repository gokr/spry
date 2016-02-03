Files and what they are.

# Core Ni

* niparser.nim - The Nim parser which can be imported and used on its own. Produces an AST.
* nivm.nim     - The Nim interpreter, imports niparser above. Only core language.

* nitest.nim   - Accompanying tests for the Ni interpreter and parser
* test.sh      - Trivial shell script to run nitest.nim
* testjs.sj    - Trivial shell script to run nitest.nim compiled to javascript for NodeJS

# Ni executables

* ni - The kitchen sink Ni interpreter useful for scripting
* nirepl.nim  - A first shot at a read-eval-print loop for playing and for running interactive tutorials
* nimin - A minimal core Ni interpreter 
* nimicro - As small as it can get, source is embedded, testing how small we can be.

# Basic modules

* nimath       - Wrapped Nim math library
* nios         - Wrapped Nim OS library
* niio         - Nim IO functions
* nithread     - Native threading functions
* nidebug      - Debugging functions

# Extra modules

niextend     - A sample interpreter/parser extension module.
nipython     - Integrates CPython, needs the python Nim module which you can install using "nimble install python".


# Going small
The Ni interpreter is fairly small, only around 1100 lines of code but it does include the Nim soft realtime GC so we can't
go ultra small. But using for example musl-libc or diet-libc you can make a statically linked stripped 64 bit x86_64 VM
that is only around 100kb. Clang makes a smaller non-size optimized binary, but larger size optimized.

## musl-libc
If you want to try building with musl-libc (which seems to be the most competent small libc) you need to install
musl-dev and then use a build command like this (replace nimin with ni/nimicro/nirepl)::

```
nim -d:release --opt:size --passL:-static --gcc.exe:musl-gcc --gcc.linkerexe:musl-gcc c nimin && strip -s nimin
```
On my machine that produces a nimin around 124kb and nimicro around 95kb.

## diet-libc
If you want to try building with diet-libc you need to install dietlibc-dev and add this file:

gokr@yoda:~/nim/ni/src$ cat /usr/bin/dietgcc 
diet gcc $@

...then use a build command like this (replace nimin with ni/nimicro/nirepl), nimicro is the absolute smallest:

```
nim -d:release --opt:size --passL:-static --gcc.exe:dietgcc --gcc.linkerexe:dietgcc c nimin && strip -s nimin
```
On my machine that produces a nimin around 103kb and nimicro around 95kb.
