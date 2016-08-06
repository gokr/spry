import spryvm, sequtils

# An executable Spry polymorphic function
type
  # nodes hold Funk instances
  PolyMeth* = ref object of Meth

proc newPolyMeth*(funks: Blok, parent: Activation): Funk =
  PolyMeth(nodes: funks.nodes, parent: parent)

proc polymeth*(funks: Blok, spry: Interpreter): Node =
  newPolyMeth(funks, spry.currentActivation)

method `$`*(self: PolyMeth): string =
  return "polymethod [" & $self.nodes & "]"

method eval(self: PolyMeth, spry: Interpreter): Node =
  let receiver = evalArgInfix(spry)
  if receiver.isNil:
    return spry.nilVal
  let tags = receiver.tags
  if tags.isNil:
    return spry.nilVal
  let tagNodes = tags.nodes
  if tagNodes.isNil:
    return spry.nilVal
  for n in self.nodes:
    let fun = Funk(n)
    if any(tagNodes, proc (x: Node): bool = return fun.tags.nodes.contains(x)):
      return fun.eval(spry)
  return spry.nilVal

# Spry OO module
proc addOO*(spry: Interpreter) =
  # Create a polymeth with a block of tagged funcs/funcis as argument
  nimPrim("polymethod", false):
    polymeth(Blok(evalArg(spry)), spry)

  #nimPrim("polyfunci", false):
  #  polymeth(Blok(evalArg(spry)), true, spry)

  # Shorthand for making a tagged method
  nimPrim("->", true):
    let tags = evalArgInfix(spry)
    let result = spry.meth(Blok(evalArg(spry)))
    result.tags = Blok(tags)
    return result
