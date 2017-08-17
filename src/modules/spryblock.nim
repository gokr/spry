import spryvm

import algorithm

proc newBlok*(size: int): Blok =
  Blok(nodes: newSeq[Node](size))

# Spry block module
proc addBlock*(spry: Interpreter) =
  # Accessing
  nimMeth("first"):  SeqComposite(evalArgInfix(spry))[0]
  nimMeth("second"): SeqComposite(evalArgInfix(spry))[1]
  nimMeth("third"):  SeqComposite(evalArgInfix(spry))[2]
  nimMeth("fourth"): SeqComposite(evalArgInfix(spry))[3]
  nimMeth("fifth"):  SeqComposite(evalArgInfix(spry))[4]
  nimMeth("last"):
    let nodes = SeqComposite(evalArgInfix(spry)).nodes
    nodes[high(nodes)]

  # Streaming
  nimMeth("reset"):  Blok(evalArgInfix(spry)).pos = 0 # Called change in Rebol
  nimMeth("pos"):    newValue(Blok(evalArgInfix(spry)).pos) # ? in Rebol
  nimMeth("pos:"):    # ? in Rebol
    result = evalArgInfix(spry)
    let comp = Blok(result)
    comp.pos = IntVal(evalArg(spry)).value
  nimMeth("read"):
    let comp = Blok(evalArgInfix(spry))
    comp[comp.pos]
  nimMeth("write:"):
    result = evalArgInfix(spry)
    let comp = Blok(result)
    comp[comp.pos] = evalArg(spry)
  nimMeth("next"):
    let comp = Blok(evalArgInfix(spry))
    if comp.pos == comp.nodes.len:
      return spry.undefVal
    result = comp[comp.pos]
    inc(comp.pos)
  nimMeth("prev"):
    let comp = Blok(evalArgInfix(spry))
    if comp.pos == 0:
      return spry.undefVal
    dec(comp.pos)
    result = comp[comp.pos]
  nimMeth("end?"):
    let comp = Blok(evalArgInfix(spry))
    newValue(comp.pos == comp.nodes.len)

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

  nimMeth("map:"):
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
      returnBlok.add(result)
      current.pos = 0
    # Reset our trick
    current.body.nodes[0] = orig
    current.pos = oldpos
    return returnBlok

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
  nimMeth("sum"):
    let blk = SeqComposite(evalArgInfix(spry))
    var sum:int = 0
    var sum2:float = 0
    var foundFloat = false
    for each in blk.nodes:
      if each of IntVal:
        sum = sum + IntVal(each).value
      elif each of FloatVal:
        foundFloat = true
        sum2 = sum2 + FloatVal(each).value
      else:
        raiseRuntimeException("Block contained something other than an int or float, can not sum.")
    if foundFloat:
      return newValue(sum2 + sum.float)
    else:
      return newValue(sum)
  # Just for benchmark, this is the fastest we can do it with boxed ints
  nimMeth("selectLarger8"):
    let self = SeqComposite(evalArgInfix(spry))
    let returnBlok = newBlok()
    for each in self.nodes:
      if IntVal(each).value > 8:
        returnBlok.add(each)
    return returnBlok

  # Library code
  discard spry.evalRoot """[
    # Collections
    sprydo: = method [:fun
      self reset
      [self end?] whileFalse: [do fun (self next)]
    ]

    detect: = method [:pred
      self reset
      [self end?] whileFalse: [
        n = (self next)
        do pred n then: [^n]]
      ^nil
    ]

    spryselect: = method [:pred
      result = ([] clone)
      self reset
      [self end?] whileFalse: [
        n = (self next)
        do pred n then: [result add: n]]
      ^result]

    spryselectdo: = method [:pred
      result = ([] clone)
      self do: [
        do pred :n then: [result add: n]]
      ^result]
]"""
