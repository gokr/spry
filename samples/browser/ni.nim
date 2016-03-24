# Ni interpreter doing eval in a browser.
# Can be evolved into a trivial REPL-in-a-browser.

import nivm, niparser

proc newVM*(): Interpreter =
  result = newInterpreter()
  # Add extra modules
  #result.addExtend()

proc nieval*(code: cstring): cstring {.exportc.} =
  $newVM().eval($code)

when isMainModule and not defined(js):
  echo nieval("3 + 4")

