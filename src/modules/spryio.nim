import spryvm

import os

# Spry IO module
proc addIO*(spry: Interpreter) =
  # IO
  nimPrim("echo", false, 1):
    echo(form(evalArg(spry)))
  nimPrim("probe", false, 1):
    result = arg(spry)
    echo(form(result))
  nimPrim("existsFile", false, 1):
    let fn = StringVal(evalArg(spry)).value
    newValue(existsFile(fn))
  nimPrim("readFile", false, 1):
    let fn = StringVal(evalArg(spry)).value
    let contents = readFile(fn).string
    newValue(contents)
  nimPrim("writeFile", false, 2):
    let fn = StringVal(evalArg(spry)).value
    result = evalArg(spry)
    writeFile(fn, StringVal(result).value)

