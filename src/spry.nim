# Spry Language executable
#
# Copyright (c) 2015 Göran Krampe

# Enable when profiling
when defined(profiler):
  import nimprof

import os
import spryvm
import spryextend, sprymath, spryos, spryio, sprythread,
 spryoo, sprydebug, sprycompress, sprystring, sprymodules, spryreflect,
 spryblock

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
spry.addReflect()
#spry.addUI()
spry.addBlock()

# Just run a given file as argument, the hash-bang trick works also
let params = commandLineParams()
let fn = params[0]
var code: string
if fn == "-e":
  code = params[1]
else:
  code = readFile(fn)
discard spry.eval("[" & code & "]")
