import threadpool
import spryvm

# Spry threading. Both the block and the whole interpreter is deep copied by Nim.
proc spawnDo(node: Blok, spry: Interpreter) {.gcsafe.} =
  discard node.evalRootDo(spry)

proc addThread*(spry: Interpreter) =
  nimFunc("spawn"):
    spawn spawnDo(Blok(evalArg(spry)), spry)
