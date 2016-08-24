import spryvm, sequtils

# An executable Spry polymorphic function
type
  # nodes hold Funk instances
  PolyMeth* = ref object of Meth

proc newPolyMeth*(methods: Blok, parent: Activation): Funk =
  PolyMeth(nodes: methods.nodes, parent: parent)

proc polymeth*(methods: Blok, spry: Interpreter): Node =
  newPolyMeth(methods, spry.currentActivation)

method `$`*(self: PolyMeth): string =
  return "polymethod [" & $self.nodes & "]"

method eval*(self: PolyMeth, spry: Interpreter): Node =
  let receiver = evalArgInfix(spry)
  if receiver.isNil:
    return spry.nilVal
  let tags = receiver.tags
  if tags.isNil:
    return spry.nilVal
  let nodeTags = tags.nodes
  if nodeTags.isNil:
    return spry.nilVal
  for n in self.nodes:
    let funTags = Funk(n).tags.nodes
    for nt in nodeTags:
      if funTags.contains(nt):
        return Funk(n).eval(spry)
    #if any(nodeTags, proc (x: Node): bool = return fun.tags.nodes.contains(x)):
    #  return fun.eval(spry)
  return spry.nilVal

# Spry OO module
proc addOO*(spry: Interpreter) =
  # Create a polymeth with a block of tagged methods as argument
  nimFunc("polymethod"):
    polymeth(Blok(evalArg(spry)), spry)

  # Shorthand for making a tagged method
  nimMeth("->"):
    let tags = evalArgInfix(spry)
    result = spry.meth(Blok(evalArg(spry)))
    result.tags = Blok(tags)

