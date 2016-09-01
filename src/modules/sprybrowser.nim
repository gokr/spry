import spryvm

# So we can call echoSpry in the HTML file
proc echoSpry*(a: cstring) {.importc.}

# Spry browser module
proc addBrowser*(spry: Interpreter) =
  # stdin/stdout
  nimFunc("echo"):
    result = spry.nilVal
    echoSpry(print(evalArg(spry)))
  nimFunc("probe"):
    result = evalArg(spry)
    echoSpry($result)

