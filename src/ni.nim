# Ni Language executable
#
# Copyright (c) 2015 Göran Krampe

import os
import nivm
import niextend, nimath, nios, niio, nithread, nipython, nidebug

var ni = newInterpreter()

# Add extra modules
ni.addExtend()
ni.addMath()
ni.addOS()
ni.addIO()
ni.addThread()
ni.addPython()
ni.addDebug()

# Just run a given file as argument, the hash-bang trick works also
let fn = commandLineParams()[0]
let code = readFile(fn)
discard ni.eval(code)
