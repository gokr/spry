import spryvm, sequtils

# An executable Spry polymorphic function
type
  # nodes hold Funk instances
  PolyFunk* = ref object of Funk

proc newPolyFunk*(funks: Blok, infix: bool, parent: Activation): Funk =
  PolyFunk(nodes: funks.nodes, infix: infix, parent: parent)

proc polyfunk*(funks: Blok, infix: bool, spry: Interpreter): Node =
  newPolyFunk(funks, infix, spry.currentActivation)

method `$`*(self: PolyFunk): string =
  if self.infix:
    result = "polyfunci "
  else:
    result = "polyfunc "
  return result & "[" & $self.nodes & "]"

method eval(self: PolyFunk, spry: Interpreter): Node =
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
  # Create a polyfunc with a block of tagged funcs/funcis as argument
  nimPrim("polyfunc", false, 1):
    polyfunk(Blok(evalArg(spry)), false, spry)

  nimPrim("polyfunci", false, 1):
    polyfunk(Blok(evalArg(spry)), true, spry)

  # Shorthand for making a tagged funci
  nimPrim("->", true, 2):
    let tags = evalArgInfix(spry)
    let result = spry.funk(Blok(evalArg(spry)), true)
    result.tags = Blok(tags)
    return result
