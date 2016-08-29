import spryvm

import algorithm

proc newBlok*(size: int): Blok =
  Blok(nodes: newSeq[Node](size))

# Spry block module
proc addBlock*(spry: Interpreter) =
  # Explicit creation
  nimFunc("newBlock"):
    return newBlok()
  nimFunc("newBlock:"):
    let size = IntVal(evalArg(spry))
    let blok = newBlok(size.value)
    blok.nodes.fill(spry.nilVal)
    return blok
  nimMeth("fill:"):
    let self = Blok(evalArgInfix(spry))
    let filler = evalArg(spry)
    self.nodes.fill(filler)
    return self
  nimMeth("reverse"):
    let self = Blok(evalArgInfix(spry))
    self.nodes.reverse()
    return self
  nimMeth("select:"):
    let self = SeqComposite(evalArgInfix(spry))
    let blk = Blok(evalArg(spry))
    let returnBlok = newBlok()
    let current = spry.currentActivation
    # Ugly hack for now, we trick the activation into holding
    # each in pos 0
    let orig = current.body.nodes[0]
    let oldpos = current.pos
    current.pos = 0
    # We create and reuse a single activation
    let activation = newActivation(blk)
    for each in self.nodes:
      current.body.nodes[0] = each
      # evalDo will increase pos, but we set it back below
      result = activation.eval(spry)
      activation.reset()
      # Or else non local returns don't work :)
      if current.returned:
        # Reset our trick
        current.body.nodes[0] = orig
        current.pos = oldpos
        return
      if BoolVal(result).value:
        returnBlok.add(each)
      current.pos = 0
    # Reset our trick
    current.body.nodes[0] = orig
    current.pos = oldpos
    return returnBlok

  # Just for benchmark, this is the fastest we can do it with boxed ints
  nimMeth("selectLarger8"):
    let self = SeqComposite(evalArgInfix(spry))
    let returnBlok = newBlok()
    for each in self.nodes:
      if IntVal(each).value > 8:
        returnBlok.add(each)
    return returnBlok
