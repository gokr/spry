# Spry Language executable
#
# Copyright (c) 2015 Göran Krampe

# Enable when profiling
when defined(profiler):
  import nimprof

import os
import spryvm
import niextend, nimath, nios, niio, nithread, nipython, nidebug, nicompress

var spry = newInterpreter()

# Add extra modules
spry.addExtend()
spry.addMath()
spry.addOS()
spry.addIO()
spry.addThread()
spry.addPython()
spry.addDebug()
spry.addCompress()

# Just run a given file as argument, the hash-bang trick works also
let fn = commandLineParams()[0]
let code = readFile(fn)
discard spry.eval("[" & code & "]")
