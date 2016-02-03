import nivm, niparser

# Ni IO module
proc addIO*(ni: Interpreter) =
  # IO
  nimPrim("echo", false, 1):
    echo(form(evalArg(ni)))
  nimPrim("probe", false, 1):
    result = arg(ni)
    echo(form(result))
