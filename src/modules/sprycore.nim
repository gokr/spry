import spryvm

import tables

# Spry core module, stuff you almost certainly want
# but doesn't have to be in spryvm.nim
proc addCore*(spry: Interpreter) =
  # Reflection words
  # Access to root Map. This is a prim to avoid root being a
  # recursive Map.
  nimFunc("root"):
    spry.root

  # Access to current Activation
  nimFunc("activation"):
    spry.currentActivation

  # Access to closest scope
  nimFunc("locals"):
    for activation in mapWalk(spry.currentActivation):
      return BlokActivation(activation).getLocals()

  # Access to self
  nimFunc("node"):
    let act = spry.argParent()
    if act.notNil:
      result = act.last
      if result.isNil:
        spry.currentActivation.self = spry.nilVal
        result = spry.nilVal
  nimFunc("self"):
    self(spry)
  nimFunc(";"):
    result = spry.lastSelf
    if result.isNil:
      result = spry.nilVal

  # Tags
  nimMeth("tag:"):
    result = evalArgInfix(spry)
    let tag = Word(evalArg(spry))
    if result.tags.isNil:
      result.tags = newBlok()
    if tag of LitWord:
      result.tags.add(tag)
    else:
      result.tags.add(spry.litify(tag))
  nimMeth("tag?"):
    let node = evalArgInfix(spry)
    let tag = evalArg(spry)
    if node.tags.isNil:
      return spry.falseVal
    if tag of LitWord:
      return boolVal(node.tags.contains(tag), spry)
    else:
      return boolVal(node.tags.contains(spry.litify(tag)), spry)
  nimMeth("tags"):
    let node = evalArgInfix(spry)
    if node.tags.isNil:
      return spry.emptyBlok
    return node.tags
  nimMeth("tags:"):
    result = evalArgInfix(spry)
    result.tags = Blok(evalArg(spry))

  # Assignment and tests
  nimMeth("="):
    result = evalArg(spry) # Perhaps we could make it eager here? Pulling in more?
    spry.assign(argInfix(spry), result)
  nimMeth("set:"):
    result = evalArg(spry)
    spry.assign(evalArgInfix(spry), result)
  nimMeth("?"):
    let binding = spry.lookup(argInfix(spry))
    if binding.isNil:
      return spry.falseVal
    return spry.trueVal
  nimMeth("nil?"):
    let binding = spry.lookup(argInfix(spry))
    if binding.isNil:
      return spry.falseVal
    if binding.val == spry.nilVal:
      return spry.trueVal
    return spry.falseVal
  nimMeth("set?"):
    newValue(not (evalArgInfix(spry) of UndefVal))

  # Arithmetic
  nimMeth("+"):  evalArgInfix(spry) + evalArg(spry)
  nimMeth("-"):  evalArgInfix(spry) - evalArg(spry)
  nimMeth("*"):  evalArgInfix(spry) * evalArg(spry)
  nimMeth("/"):  evalArgInfix(spry) / evalArg(spry)

  # Comparisons
  nimMeth("<"):   evalArgInfix(spry) < evalArg(spry)
  nimMeth(">"):   evalArgInfix(spry) > evalArg(spry)
  nimMeth("<="):  evalArgInfix(spry) <= evalArg(spry)
  nimMeth(">="):  evalArgInfix(spry) >= evalArg(spry)

  # Equality and identity
  nimMeth("=="):  eq(evalArgInfix(spry), evalArg(spry))
  nimMeth("==="): newValue(system.`==`(evalArgInfix(spry), evalArg(spry)))
  nimMeth("!="):  newValue(not BoolVal(eq(evalArgInfix(spry), evalArg(spry))).value)
  nimMeth("!=="): newValue(not system.`==`(evalArgInfix(spry), evalArg(spry)))

  # Booleans
  nimMeth("not"): newValue(not BoolVal(evalArgInfix(spry)).value)
  nimMeth("and"):
    let arg1 = BoolVal(evalArgInfix(spry)).value
    let arg2 = arg(spry) # We need to make sure we consume this one, since "and" is shortcutting
    newValue(arg1 and BoolVal(arg2.eval(spry)).value)
  nimMeth("or"):
    let arg1 = BoolVal(evalArgInfix(spry)).value
    let arg2 = arg(spry) # We need to make sure we consume this one, since "or" is shortcutting
    newValue(arg1 or BoolVal(arg2.eval(spry)).value)

  # Concatenation
  nimMeth(","):
    let val = evalArgInfix(spry)
    if val of StringVal:
      return val & evalArg(spry)
    elif val of Blok:
      return Blok(val).concat(SeqComposite(evalArg(spry)).nodes)
    elif val of Paren:
      return Paren(val).concat(SeqComposite(evalArg(spry)).nodes)
    elif val of Curly:
      return Curly(val).concat(SeqComposite(evalArg(spry)).nodes)

  # Conversions
  nimMeth("print"):
    newValue(print(evalArgInfix(spry)))
  nimMeth("asFloat"):
    let val = evalArgInfix(spry)
    if val of FloatVal:
      return val
    elif val of IntVal:
      return newValue(toFloat(IntVal(val).value))
    else:
      raiseRuntimeException("Can not convert to float")
  nimMeth("asInt"):
    let val = evalArgInfix(spry)
    if val of IntVal:
      return val
    elif val of FloatVal:
      return newValue(toInt(FloatVal(val).value))
    else:
      raiseRuntimeException("Can not convert to int")
  nimFunc("serialize"):
    newValue($evalArg(spry))
  nimFunc("parse"):
    spry.parser.parse(StringVal(evalArg(spry)).value)

  # Composite and String
  # Rebol head/tail collides too much with Lisp IMHO so not sure what to do with
  # those.
  # at: and at:put: in Smalltalk seems to be pick/poke in Rebol.
  # change/at is similar in Rebol but work at current pos.
  # Spry uses at/put instead of pick/poke and read/write instead of change/at

  # Left to think about is peek/poke (Rebol has no peek) and perhaps pick/drop
  # The old C64 Basic had peek/poke for memory at:/at:put: ... :) Otherwise I
  # generally associate peek with lookahead.
  # Idea here: Use xxx? for methods, arity 1, returning booleans
  nimMeth("size"):
    let comp = evalArgInfix(spry)
    if comp of StringVal:
      result = newValue(StringVal(comp).value.len)
    elif comp of SeqComposite:
      return newValue(SeqComposite(evalArgInfix(spry)).nodes.len)
    elif comp of Map:
      return newValue(Map(evalArgInfix(spry)).bindings.len)
  nimMeth("at:"):
    let comp = evalArgInfix(spry)
    if comp of SeqComposite:
      return SeqComposite(comp)[evalArg(spry)]
    elif comp of Map:
      let hit = Map(comp)[evalArg(spry)]
      if hit.isNil: return spry.undefVal else: return hit
  nimMeth("at:put:"):
    let comp = evalArgInfix(spry)
    let key = evalArg(spry)
    let val = evalArg(spry)
    if comp of SeqComposite:
      SeqComposite(comp)[key] = val
    elif comp of Map:
      Map(comp)[key] = val
    return comp
  nimMeth("get:"):
    let comp = evalArgInfix(spry)
    let word = arg(spry)
    let hit = Map(comp)[word]
    if hit.isNil: spry.undefVal else: hit
  nimMeth("set:to:"):
    let comp = Map(evalArgInfix(spry))
    let word = arg(spry)
    let val = evalArg(spry)
    comp[word] = val
    return comp
  nimMeth("contains:"):
    let comp = evalArgInfix(spry)
    let key = evalArg(spry)
    if comp of SeqComposite:
      return newValue(SeqComposite(comp).contains(key))
    elif comp of Map:
      return newValue(Map(comp).contains(key))
    return comp
  nimMeth("add:"):
    result = evalArgInfix(spry)
    let comp = SeqComposite(result)
    comp.add(evalArg(spry))
  nimMeth("removeLast"):
    result = evalArgInfix(spry)
    let comp = SeqComposite(result)
    comp.removeLast()
  nimMeth("copyFrom:to:"):
    let comp = evalArgInfix(spry)
    let frm = IntVal(evalArg(spry)).value
    let to = IntVal(evalArg(spry)).value
    if comp of StringVal:
      result = newValue(StringVal(comp).value[frm .. to])
    elif comp of Blok:
      result = newBlok(Blok(comp).nodes[frm .. to])
    elif comp of Paren:
      result = newParen(Paren(comp).nodes[frm .. to])
    elif comp of Curly:
      result = newCurly(Curly(comp).nodes[frm .. to])
    if comp.tags.notNil:
      result.tags = comp.tags

  # Collection primitives
  nimMeth("do:"):
    let blk1 = SeqComposite(evalArgInfix(spry))
    let blk2 = Blok(evalArg(spry))
    let current = spry.currentActivation
    # Ugly hack for now, we trick the activation into holding
    # each in pos 0
    let orig = current.body.nodes[0]
    let oldpos = current.pos
    current.pos = 0
    # We create and reuse a single activation
    let activation = newActivation(blk2)
    for each in blk1.nodes:
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
      current.pos = 0
    # Reset our trick
    current.body.nodes[0] = orig
    current.pos = oldpos
    return blk1

  # Quit
  nimFunc("quit"):    quit(IntVal(evalArg(spry)).value)

  #discard root.makeBinding("bind", newPrimFunc(primBind, false, 1))
  nimFunc("func"):    spry.funk(Blok(evalArg(spry)))
  nimFunc("method"):  spry.meth(Blok(evalArg(spry)))
  nimFunc("do"):      evalArg(spry).evalDo(spry)
  nimFunc("$"):       arg(spry)
  nimFunc("eva"):     evalArg(spry)
  nimFunc("eval"):    evalArg(spry).eval(spry)

  # Word conversions
  nimFunc("reify"):
    reify(LitWord(evalArg(spry)))
  nimFunc("litify"):
    spry.litify(evalArg(spry))
  nimFunc("quote"):
    spry.newLitWord($arg(spry))
  nimFunc("litword"):
    spry.newLitWord(StringVal(evalArg(spry)).value)
  nimFunc("word"):
    newWord(StringVal(evalArg(spry)).value)

  # Cloning
  nimMeth("clone"):
    evalArgInfix(spry).clone()

  # Control structures
  nimFunc("^"):
    result = evalArg(spry)
    spry.currentActivation.returned = true
  nimMeth("then:"):
    if BoolVal(evalArgInfix(spry)).value:
      return SeqComposite(evalArg(spry)).evalDo(spry)
    else:
      discard arg(spry) # Consume the block
      return spry.nilVal
  nimMeth("else:"):
    if BoolVal(evalArgInfix(spry)).value:
      discard arg(spry) # Consume the block
      return spry.nilVal
    else:
      return SeqComposite(evalArg(spry)).evalDo(spry)
  nimMeth("then:else:"):
    if BoolVal(evalArgInfix(spry)).value:
      let res = SeqComposite(evalArg(spry)).evalDo(spry)
      discard arg(spry) # Consume second block
      return res
    else:
      discard arg(spry) # Consume first block
      return SeqComposite(evalArg(spry)).evalDo(spry)
  nimMeth("else:then:"):
    if BoolVal(evalArgInfix(spry)).value:
      discard arg(spry) # Consume first block
      return SeqComposite(evalArg(spry)).evalDo(spry)
    else:
      let res = SeqComposite(evalArg(spry)).evalDo(spry)
      discard arg(spry) # Consume second block
      return res
  nimMeth("repeat:"):
    let times = IntVal(evalArgInfix(spry)).value
    let fn = SeqComposite(evalArg(spry))
    for i in 1 .. times:
      result = fn.evalDo(spry)
      # Or else non local returns don't work :)
      if spry.currentActivation.returned:
        return
  nimMeth("to:do:"):
    let self = IntVal(evalArgInfix(spry))
    let frm = self.value
    let to = IntVal(evalArg(spry)).value
    let fn = Blok(evalArg(spry))
    let current = spry.currentActivation
    # Ugly hack for now, we trick the activation into holding
    # each in pos 0
    let orig = current.body.nodes[0]
    let oldpos = current.pos
    current.pos = 0
    # We create and reuse a single activation
    let activation = newActivation(fn)
    for i in frm .. to:
      current.body.nodes[0] = newValue(i)
      # evalDo will increase pos, but we set it back below
      result = activation.eval(spry)
      activation.reset()
      current.pos = 0
      # Or else non local returns don't work :)
      if current.returned:
        # Reset our trick
        current.body.nodes[0] = orig
        current.pos = oldpos
        return
    # Reset our trick
    current.body.nodes[0] = orig
    current.pos = oldpos
    return self

  nimMeth("whileTrue:"):
    let blk1 = SeqComposite(evalArgInfix(spry))
    let blk2 = SeqComposite(evalArg(spry))
    result = blk1.evalDo(spry)
    if spry.currentActivation.returned:
      return
    while BoolVal(result).value:
      result = blk2.evalDo(spry)
      # Or else non local returns don't work :)
      if spry.currentActivation.returned:
        return
      result = blk1.evalDo(spry)
      if spry.currentActivation.returned:
        return
  nimMeth("whileFalse:"):
    let blk1 = SeqComposite(evalArgInfix(spry))
    let blk2 = SeqComposite(evalArg(spry))
    result = blk1.evalDo(spry)
    if spry.currentActivation.returned:
      return
    while not BoolVal(result).value:
      result = blk2.evalDo(spry)
      # Or else non local returns don't work :)
      if spry.currentActivation.returned:
        return
      result = blk1.evalDo(spry)
      if spry.currentActivation.returned:
        return
