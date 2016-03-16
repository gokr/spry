import nivm, niparser

# An executable Ni polymorphic function 
type
  PolyFunk* = ref object of Funk

proc newPolyFunk*(body: Blok, parent: Activation): Funk =
  PolyFunk(nodes: body.nodes, infix: true, parent: parent)

proc polyfunk*(ni: Interpreter, body: Blok): Node =
  newPolyFunk(body, ni.currentActivation)  

# Ni OO module
proc addOO*(ni: Interpreter) =
  # OO prims
  nimPrim("polyfunc", false, 1):    ni.polyfunk(Blok(evalArg(ni)))
  
  # OO Ni suppport code
  discard ni.eval """
  # Convenience func to create a tagged func
  -> = funci [:tags :blk (func blk) tags: tags]
"""

