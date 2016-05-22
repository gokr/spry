# Spry Language executable
#
# Copyright (c) 2015 Göran Krampe

# Enable when profiling
when defined(profiler):
  import nimprof

import os
import spryvm
import spryextend, sprymath, spryos, spryio, sprythread,
 spryoo, sprydebug, sprycompress, sprystring, sprymodules

# import sprypython

var spry = newInterpreter()

# Add extra modules
spry.addExtend()
spry.addMath()
spry.addOS()
spry.addIO()
spry.addThread()
#spry.addPython()
spry.addOO()
spry.addDebug()
spry.addCompress()
spry.addString()
spry.addModules()

# Just run a given file as argument, the hash-bang trick works also
let fn = commandLineParams()[0]
let code = readFile(fn)
discard spry.eval("[" & code & "]")
