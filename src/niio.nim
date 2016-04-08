import spryvm

# Ni IO module
proc addIO*(ni: Interpreter) =
  # IO
  nimPrim("echo", false, 1):
    echo(form(evalArg(ni)))
  nimPrim("probe", false, 1):
    result = arg(ni)
    echo(form(result))
  nimPrim("readFile", false, 1):
    let fn = StringVal(evalArg(ni)).value
    let contents = readFile(fn).string
    newValue(contents)
  nimPrim("writeFile", false, 2):
    let fn = StringVal(evalArg(ni)).value
    result = evalArg(ni)
    writeFile(fn, StringVal(result).value)
