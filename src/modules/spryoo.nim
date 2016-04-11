import spryvm

# An executable Spry polymorphic function
type
  PolyFunk* = ref object of Funk

proc newPolyFunk*(body: Blok, parent: Activation): Funk =
  PolyFunk(nodes: body.nodes, infix: true, parent: parent)

proc polyfunk*(spry: Interpreter, body: Blok): Node =
  newPolyFunk(body, spry.currentActivation)

# Spry OO module
proc addOO*(spry: Interpreter) =
  # OO prims
  nimPrim("polyfunc", false, 1):    spry.polyfunk(Blok(evalArg(spry)))

  # OO Spry suppport code
  discard spry.evalRoot """[
  # Convenience func to create a tagged func
  -> = funci [:tags :blk (func blk) tags: tags]
]"""

