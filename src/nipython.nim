import nivm, niparser, python

proc primPython*(ni: Interpreter): Node =
  Py_Initialize()
  discard PyRun_SimpleString(StringVal(evalArg(ni)).value)
  Py_Finalize()

# This proc does the work extending an Interpreter instance
proc addPython*(ni: Interpreter) =
  ni.makeWord("python", newNimProc(primPython, false, 1))

