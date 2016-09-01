import spryvm

import os

# Spry IO module
proc addIO*(spry: Interpreter) =
  # stdin/stdout
  nimFunc("echo"):
    result = spry.nilVal
    echo(print(evalArg(spry)))
  nimFunc("probe"):
    result = evalArg(spry)
    echo($result)
  
  # Files
  nimFunc("existsFile"):
    let fn = StringVal(evalArg(spry)).value
    newValue(existsFile(fn))
  nimFunc("readFile"):
    let fn = StringVal(evalArg(spry)).value
    let contents = readFile(fn).string
    newValue(contents)
  nimFunc("writeFile"):
    let fn = StringVal(evalArg(spry)).value
    result = evalArg(spry)
    writeFile(fn, StringVal(result).value)

