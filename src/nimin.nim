# Ni Minimal Language interpreter.
#
# This Ni interpreter has no extra modules linked, only core language.
#
# NOTE:
# * Clang makes a smaller non-size optimized binary, but larger size optimized.
# * You can get a statically linked VM using musl-libc down to 100kb.
#
# Following sizes as compiled on Linux x86-64, uname -a
# Linux yoda 3.13.0-76-generic #120-Ubuntu SMP Mon Jan 18 15:59:10 UTC 2016 x86_64 x86_64 x86_64 GNU/Linux
#
# Regular compiled, no optimization for size, dynamically linked:
# nim -d:release c nimin && strip -s nimin
# nimin: ELF 64-bit LSB  executable, x86-64, version 1 (SYSV), dynamically linked (uses shared libs), for GNU/Linux 2.6.24, BuildID
# [sha1]=6f077730253072f0aca983264e444dcdf8393048, stripped
# Size: 186720 bytes
#
# Statically compiled optimized for size:
# nim -d:release --opt:size --passL:-static c nimin && strip -s nimin
# nimin: ELF 64-bit LSB  executable, x86-64, version 1 (SYSV), statically linked, for GNU/Linux 2.6.24, BuildID
# [sha1]=c7c972a96e1fc04a5e1a95953c20f7dc301a8321, stripped
# Size: 890080 bytes
#
# Statically compiled optimized for size using musl-libc:
# nim -d:release --opt:size --passL:-static --gcc.exe:dietgcc --gcc.linkerexe:dietgcc c nimin && strip -s nimin
# nimin: ELF 64-bit LSB  executable, x86-64, version 1 (SYSV), statically linked, stripped
# Size: 128648 bytes
#
# Statically compiled optimized for size using diet-libc (had to create /usr/bin/dietgcc containing "diet gcc $@"):
# nim -d:release --opt:size --passL:-static --gcc.exe="dietgcc" --gcc.linkerexe="dietgcc" c nimin && strip -s nimin
# nimin: ELF 64-bit LSB  executable, x86-64, version 1 (SYSV), statically linked, BuildID[sha1]=727e7658285c51ca27485b22af78b14d6d844e5b, stripped
# Size: 107920 bytes
#
# Copyright (c) 2015 Göran Krampe

import os
import nivm

# Just run a given file as argument, the hash-bang trick works also
let fn = commandLineParams()[0]
let code = readFile(fn)
discard newInterpreter().eval(code)
