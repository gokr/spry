import nivm, niparser, nimath, nios, niio
import threadpool

# Ni threading
proc spawnDo(node: Node) {.gcsafe.} =
  let ni = newInterpreter()
  ni.addMath()
  ni.addOS()
  ni.addIO()
  discard node.evalRootDo(ni)

proc addThread*(ni: Interpreter) =
  nimPrim("spawn", false, 1):
    spawn spawnDo(evalArg(ni))
