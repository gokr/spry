# Ni Language Interpreter
#
# Copyright (c) 2015 Göran Krampe

import strutils, sequtils, tables
import niparser

type
  # Ni interpreter
  Interpreter* = ref object
    currentActivation*: Activation  # Execution spaghetti stack
    rootActivation*: RootActivation # The first one
    root*: Dictionary               # Root bindings
    trueVal*: Node
    falseVal*: Node
    undefVal*: Node
    nilVal*: Node

  # Node type to hold Nim primitive procs
  ProcType* = proc(ni: Interpreter): Node
  NimProc* = ref object of Node
    prok*: ProcType
    infix*: bool
    arity*: int 

  # An executable Ni function 
  Funk* = ref object of Blok
    infix*: bool
    parent*: Activation
  
  # The activation record used by the Interpreter.
  # This is a so called Spaghetti Stack with only a parent pointer so that they
  # can get garbage collected if not referenced by any other record anymore.
  Activation* = ref object of Node  # It's a Node since we can reflect on it!
    last*: Node                     # Remember for infix
    infixArg*: Node                 # Used to hold the infix arg, if pulled
    returned*: bool                 # Mark return
    parent*: Activation
    pos*: int          # Which node we are at
    body*: SeqComposite   # The composite representing code (Blok, Paren, Funk)

  # We want to distinguish different activations
  BlokActivation* = ref object of Activation
    locals*: Dictionary  # This is where we put named args and locals
  FunkActivation* = ref object of BlokActivation
  ParenActivation* = ref object of Activation
  CurlyActivation* = ref object of BlokActivation
  RootActivation* = ref object of BlokActivation


# Forward declarations to make Nim happy
proc funk*(ni: Interpreter, body: Blok, infix: bool): Node
method eval*(self: Node, ni: Interpreter): Node {.base.}
method evalDo*(self: Node, ni: Interpreter): Node {.base.}

# String representations
method `$`*(self: NimProc): string =
  if self.infix:
    result = "nimi"
  else:
    result = "nim"
  return result & "(" & $self.arity & ")"

method `$`*(self: Funk): string =
  when false:
    if self.infix:
      result = "funci"
    else:
      result = "func"
    return result & "(" & $self.arity & ")" & "[" & $self.nodes & "]"
  else:
    return "[" & $self.nodes & "]"

method `$`*(self: Activation): string =
  return "Activation(" & $self.body & "|" & $self.pos & ")"

# Base stuff for accessing

# Indexing Composites
proc `[]`*(self: Dictionary, key: Node): Node =
  if self.bindings.hasKey(key):
    return self.bindings[key].val

proc `[]`*(self: SeqComposite, key: Node): Node =
  self.nodes[IntVal(key).value]

proc `[]`*(self: SeqComposite, key: IntVal): Node =
  self.nodes[key.value]

proc `[]`*(self: SeqComposite, key: int): Node =
  self.nodes[key]

proc `[]=`*(self: Dictionary, key, val: Node) =
  discard self.makeBinding(key, val)

proc `[]=`*(self: SeqComposite, key, val: Node) =
  self.nodes[IntVal(key).value] = val

proc `[]=`*(self: SeqComposite, key: IntVal, val: Node) =
  self.nodes[key.value] = val

proc `[]=`*(self: SeqComposite, key: int, val: Node) =
  self.nodes[key] = val

# Indexing Activaton
proc `[]`*(self: Activation, i: int): Node =
  self.body.nodes[i]

proc len*(self: Activation): int =
  self.body.nodes.len

# Constructor procs
proc newNimProc*(prok: ProcType, infix: bool, arity: int): NimProc =
  NimProc(prok: prok, infix: infix, arity: arity)

proc newFunk*(body: Blok, infix: bool, parent: Activation): Funk =
  Funk(nodes: body.nodes, infix: infix, parent: parent)

proc newRootActivation(root: Dictionary): RootActivation =
  RootActivation(body: newBlok(), locals: root)

proc newActivation*(funk: Funk): FunkActivation =
  FunkActivation(body: funk)

proc newActivation*(body: Blok): Activation =
  BlokActivation(body: body)

proc newActivation*(body: Paren): ParenActivation =
  ParenActivation(body: body)

proc newActivation*(body: Curly): CurlyActivation =
  result = CurlyActivation(body: body)
  result.locals = newDictionary()

# Stack iterator walking parent refs
iterator stack*(ni: Interpreter): Activation =
  var activation = ni.currentActivation
  while activation.notNil:
    yield activation
    activation = activation.parent

proc getLocals(self: BlokActivation): Dictionary =
  if self.locals.isNil:
    self.locals = newDictionary()
  self.locals

method hasLocals(self: Activation): bool {.base.} =
  true
  
method hasLocals(self: ParenActivation): bool =
  false

method outer(self: Activation): Activation {.base.} =
  # Just go caller parent, which works for Paren and Blok since they are
  # not lexical closures.
  self.parent

method outer(self: FunkActivation): Activation =
  # Instead of looking at my parent, which would be the caller
  # we go to the activation where I was created, thus a Funk is a lexical
  # closure.
  Funk(self.body).parent

# Walk dictionaries for lookups and binds. Skips parens since they do not have
# locals and uses outer() that will let Funks go to their "lexical parent"
iterator dictionaryWalk(first: Activation): Activation =
  var activation = first
  while activation.notNil:
    while not activation.hasLocals():
      activation = activation.outer()
    yield activation
    activation = activation.outer()

# Walk activations for pulling arguments, here we strictly use
# parent to walk only up through the caller chain. Skipping paren activations.
iterator callerWalk(first: Activation): Activation =
  var activation = first
  # First skip over immediate paren activations
  while not activation.hasLocals():
    activation = activation.parent
  # Then pick parent
  activation = activation.parent
  # Then we start yielding
  while activation.notNil:
    yield activation
    activation = activation.parent
    # Skip paren activations
    while not activation.hasLocals():
      activation = activation.parent

# Methods supporting the Nim math primitives with coercions
method `+`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " + " & $b)
method `+`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value + b.value)
method `+`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float + b.value)
method `+`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value + b.value.float)
method `+`(a: FloatVal, b: FloatVal): Node {.inline.} =
  newValue(a.value + b.value)

method `-`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " - " & $b)
method `-`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value - b.value)
method `-`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float - b.value)
method `-`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value - b.value.float)
method `-`(a: FloatVal, b: FloatVal): Node {.inline.} =
  newValue(a.value - b.value)

method `*`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " * " & $b)
method `*`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value * b.value)
method `*`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float * b.value)
method `*`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value * b.value.float)
method `*`(a: FloatVal, b: FloatVal): Node {.inline.} =
  newValue(a.value * b.value)

method `/`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " / " & $b)
method `/`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value / b.value)
method `/`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float / b.value)
method `/`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value / b.value.float)
method `/`(a,b: FloatVal): Node {.inline.} =
  newValue(a.value / b.value)

method `<`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " < " & $b)
method `<`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value < b.value)
method `<`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float < b.value)
method `<`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value < b.value.float)
method `<`(a,b: FloatVal): Node {.inline.} =
  newValue(a.value < b.value)
method `<`(a,b: StringVal): Node {.inline.} =
  newValue(a.value < b.value)

method `<=`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " <= " & $b)
method `<=`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value <= b.value)
method `<=`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float <= b.value)
method `<=`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value <= b.value.float)
method `<=`(a,b: FloatVal): Node {.inline.} =
  newValue(a.value <= b.value)
method `<=`(a,b: StringVal): Node {.inline.} =
  newValue(a.value <= b.value)
method `<=`(a, b: BoolVal): Node {.inline.} =
  newValue(a.value <= b.value)

method `==`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " == " & $b)
method `==`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value == b.value)
method `==`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float == b.value)
method `==`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value == b.value.float)
method `==`(a,b: FloatVal): Node {.inline.} =
  newValue(a.value == b.value)
method `==`(a,b: StringVal): Node {.inline.} =
  newValue(a.value == b.value)
method `==`(a, b: BoolVal): Node {.inline.} =
  newValue(a.value == b.value)

method `&`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " & " & $b)
method `&`(a, b: StringVal): Node {.inline.} =
  newValue(a.value & b.value)
method `&`(a, b: SeqComposite): Node {.inline.} =
  a.add(b.nodes)
  return a

# Support procs for eval()
template pushActivation*(ni: Interpreter, activation: Activation) =
  activation.parent = ni.currentActivation
  ni.currentActivation = activation

template popActivation*(ni: Interpreter) =
  ni.currentActivation = ni.currentActivation.parent

proc atEnd*(self: Activation): bool {.inline.} =
  self.pos == self.len

proc next*(self: Activation): Node {.inline.} =
  if self.atEnd:
    raiseRuntimeException("End of current block, too few arguments?")
  else:
    result = self[self.pos]
    inc(self.pos)

method doReturn*(self: Activation, ni: Interpreter) {.base.} =
  ni.currentActivation = self.parent
  if ni.currentActivation.notNil:
    ni.currentActivation.returned = true

method doReturn*(self: FunkActivation, ni: Interpreter) =
  ni.currentActivation = Funk(self.body).parent

method lookup(self: Activation, key: Node): Binding {.base.} =
  # Base implementation needed for dynamic dispatch to work
  nil

method lookup(self: BlokActivation, key: Node): Binding =
  if self.locals.notNil:
    return self.locals.lookup(key)

proc lookup(ni: Interpreter, key: Node): Binding =
  for activation in dictionaryWalk(ni.currentActivation):
    let hit = activation.lookup(key)
    if hit.notNil:
      return hit

proc lookupLocal(ni: Interpreter, key: Node): Binding =
  return ni.currentActivation.lookup(key)

proc lookupParent(ni: Interpreter, key: Node): Binding =
  # Silly way of skipping to get to parent
  var inParent = false
  for activation in dictionaryWalk(ni.currentActivation):
    if inParent:
      return activation.lookup(key)
    else:
      inParent = true

method makeBinding(self: Activation, key: Node, val: Node): Binding {.base.} =
  nil

method makeBinding(self: BlokActivation, key: Node, val: Node): Binding =
  self.getLocals().makeBinding(key, val)

proc makeBinding(ni: Interpreter, key: Node, val: Node): Binding =
  # Bind in first activation with locals
  for activation in dictionaryWalk(ni.currentActivation):
    return activation.makeBinding(key, val)

proc setBinding(ni: Interpreter, key: Node, value: Node): Binding =
  result = ni.lookup(key)
  if result.notNil:
    result.val = value
  else:
    result = ni.makeBinding(key, value)

method infix(self: Node): bool {.base.} =
  false

method infix(self: Funk): bool =
  self.infix
  
method infix(self: NimProc): bool =
  self.infix

method infix(self: Binding): bool =
  return self.val.infix

proc argParent(ni: Interpreter): Activation =
  # Return first activation up the parent chain that was a caller
  for activation in callerWalk(ni.currentActivation):
    return activation

proc parentArgInfix*(ni: Interpreter): Node =
  ## Pull the parent infix arg
  let act = ni.argParent()
  act.last

proc argInfix*(ni: Interpreter): Node =
  ## Pull the infix arg
  ni.currentActivation.last

proc parentArg*(ni: Interpreter): Node =
  ## Pull next argument from parent activation
  let act = ni.argParent()
  act.next()

proc arg*(ni: Interpreter): Node =
  ## Pull next argument from activation
  ni.currentActivation.next()

template evalArgInfix*(ni: Interpreter): Node =
  ## Pull the infix arg and eval
  ni.currentActivation.last.eval(ni)

proc evalArg*(ni: Interpreter): Node =
  ## Pull next argument from activation and eval
  ni.currentActivation.next().eval(ni)

proc makeWord*(self: Interpreter, word: string, value: Node) =
  discard self.root.makeBinding(newEvalWord(word), value)

# A template reducing boilerplate for registering nim primitives
template nimPrim*(name: string, infix: bool, arity: int, body: stmt): stmt {.immediate, dirty.} =
  ni.makeWord(name, newNimProc(
    proc (ni: Interpreter): Node = body, infix, arity))

proc newInterpreter*(): Interpreter =
  let ni = Interpreter(root: newDictionary())
  result = ni

  # Singletons
  ni.trueVal = newValue(true)
  ni.falseVal = newValue(false)
  ni.nilVal = newNilVal()
  ni.undefVal = newUndefVal()
  ni.makeWord("false", ni.falseVal)
  ni.makeWord("true", ni.trueVal)
  ni.makeWord("undef", ni.undefVal)
  ni.makeWord("nil", ni.nilVal)

  # Reflection words
  # Access to current Activation
  nimPrim("activation", false, 0):
    ni.currentActivation

  # Access to closest scope
  nimPrim("locals", false, 0):
    for activation in dictionaryWalk(ni.currentActivation):
      return BlokActivation(activation).getLocals()

  # Access to closest object
  nimPrim("self", false, 0):
    ni.undefVal
    
  # Creation of Ni types without literal syntax
  nimPrim("object", false, 1):
    ni.undefVal
  
  # Tags
  nimPrim("tag", false, 2):
    result = evalArg(ni)
    let tag = Word(evalArg(ni)).word
    if result.tags.isNil:
      result.tags = newSeq[string]()
    result.tags.add(tag)
  nimPrim("tag?", false, 2):
    let node = evalArg(ni)
    let tag = Word(evalArg(ni)).word
    if node.tags.isNil:
      return ni.falseVal
    if node.tags.contains(tag):
      return ni.trueVal
    else:
      return ni.falseVal
    
  # Lookups
  nimPrim("?", true, 1):
    let val = evalArgInfix(ni)
    newValue(not (val of UndefVal))
  
  # Assignments
  nimPrim("=", true, 2):
    result = evalArg(ni) # Perhaps we could make it eager here? Pulling in more?
    discard ni.setBinding(argInfix(ni), result)
    
  # Basic math
  nimPrim("+", true, 2):  evalArgInfix(ni) + evalArg(ni)
  nimPrim("-", true, 2):  evalArgInfix(ni) - evalArg(ni)
  nimPrim("*", true, 2):  evalArgInfix(ni) * evalArg(ni)
  nimPrim("/", true, 2):  evalArgInfix(ni) / evalArg(ni)
  
  # Comparisons
  nimPrim("<", true, 2):  evalArgInfix(ni) < evalArg(ni)
  nimPrim(">", true, 2):  evalArgInfix(ni) > evalArg(ni)
  nimPrim("<=", true, 2):  evalArgInfix(ni) <= evalArg(ni)
  nimPrim(">=", true, 2):  evalArgInfix(ni) >= evalArg(ni)
  nimPrim("==", true, 2):  evalArgInfix(ni) == evalArg(ni)
  nimPrim("!=", true, 2):  newValue(not (BoolVal(evalArgInfix(ni) == evalArg(ni))).value)

  # Booleans
  nimPrim("not", false, 1): newValue(not BoolVal(evalArg(ni)).value)
  nimPrim("and", true, 2):
    let arg1 = BoolVal(evalArgInfix(ni)).value
    let arg2 = arg(ni) # We need to make sure we consume this one, since "and" is shortcutting
    newValue(arg1 and BoolVal(arg2.eval(ni)).value)
  nimPrim("or", true, 2):
    let arg1 = BoolVal(evalArgInfix(ni)).value
    let arg2 = arg(ni) # We need to make sure we consume this one, since "or" is shortcutting
    newValue(arg1 or BoolVal(arg2.eval(ni)).value)

  # Concatenation
  nimPrim(",", true, 2):
    let val = evalArgInfix(ni)
    if val of StringVal:
      return val & evalArg(ni)
    elif val of Blok:
      return Blok(val).concat(SeqComposite(evalArg(ni)).nodes)
    elif val of Paren:
      return Paren(val).concat(SeqComposite(evalArg(ni)).nodes)
    elif val of Blok:
      return Curly(val).concat(SeqComposite(evalArg(ni)).nodes)

  # Conversions
  nimPrim("asFloat", true, 1):
    let val = evalArgInfix(ni)
    if val of FloatVal:
      return val
    elif val of IntVal:
      return newValue(toFloat(IntVal(val).value))
    else:
      raiseRuntimeException("Can not convert to float")
  nimPrim("asInt", true, 1):
    let val = evalArgInfix(ni)
    if val of IntVal:
      return val
    elif val of FloatVal:
      return newValue(toInt(FloatVal(val).value))
    else:
      raiseRuntimeException("Can not convert to int")
      
  # Basic blocks
  # Rebol head/tail collides too much with Lisp IMHO so not sure what to do with
  # those.
  # at: and at:put: in Smalltalk seems to be pick/poke in Rebol.
  # change/at is similar in Rebol but work at current pos.
  # Ni uses at/put instead of pick/poke and read/write instead of change/at
  
  # Left to think about is peek/poke (Rebol has no peek) and perhaps pick/drop
  # The old C64 Basic had peek/poke for memory at:/at:put: ... :) Otherwise I
  # generally associate peek with lookahead.
  # Idea here: Use xxx? for infix funcs, arity 1, returning booleans
  # ..and xxx! for infix funcs arity 0.
  nimPrim("size", true, 1):
    newValue(SeqComposite(evalArgInfix(ni)).nodes.len)
  nimPrim("at:", true, 2):
    ## Ugly, but I can't get [] to work as methods...
    let comp = evalArgInfix(ni)
    if comp of SeqComposite:
      return SeqComposite(comp)[evalArg(ni)]
    elif comp of Dictionary:
      return Dictionary(comp)[evalArg(ni)]
  nimPrim("at:put:", true, 3):
    let comp = evalArgInfix(ni)
    let key = evalArg(ni)
    let val = evalArg(ni)
    if comp of SeqComposite:
      SeqComposite(comp)[key] = val
    elif comp of Dictionary:
      Dictionary(comp)[key] = val
    return comp
  nimPrim("read", true, 1):
    let comp = SeqComposite(evalArgInfix(ni))
    comp[comp.pos]
  nimPrim("write:", true, 2):
    result = evalArgInfix(ni)
    let comp = SeqComposite(result)
    comp[comp.pos] = evalArg(ni)
  nimPrim("add:", true, 2): 
    result = evalArgInfix(ni)
    let comp = SeqComposite(result)
    comp.add(evalArg(ni))
  nimPrim("removeLast", true, 1):
    result = evalArgInfix(ni)
    let comp = SeqComposite(result)
    comp.removeLast()
  
  # Positioning
  nimPrim("reset", true, 1):  SeqComposite(evalArgInfix(ni)).pos = 0 # Called change in Rebol
  nimPrim("pos", true, 1):    newValue(SeqComposite(evalArgInfix(ni)).pos) # ? in Rebol 
  nimPrim("pos:", true, 2):    # ? in Rebol
    result = evalArgInfix(ni)
    let comp = SeqComposite(result)
    comp.pos = IntVal(evalArg(ni)).value
 
  # Streaming
  nimPrim("next", true, 1):
    let comp = SeqComposite(evalArgInfix(ni))
    if comp.pos == comp.nodes.len:
      return ni.undefVal
    result = comp[comp.pos]
    inc(comp.pos)
  nimPrim("prev", true, 1):
    let comp = SeqComposite(evalArgInfix(ni))
    if comp.pos == 0:
      return ni.undefVal
    dec(comp.pos)
    result = comp[comp.pos]
  nimPrim("end?", true, 1):
    let comp = SeqComposite(evalArgInfix(ni))
    newValue(comp.pos == comp.nodes.len)

  # These are like in Rebol/Smalltalk but we use infix like in Smalltalk
  nimPrim("first", true, 1):  SeqComposite(evalArgInfix(ni))[0]
  nimPrim("second", true, 1): SeqComposite(evalArgInfix(ni))[1]
  nimPrim("third", true, 1):  SeqComposite(evalArgInfix(ni))[2]
  nimPrim("fourth", true, 1): SeqComposite(evalArgInfix(ni))[3]
  nimPrim("fifth", true, 1):  SeqComposite(evalArgInfix(ni))[4]
  nimPrim("last", true, 1):
    let nodes = SeqComposite(evalArgInfix(ni)).nodes
    nodes[nodes.high]

  #discard root.makeBinding("bind", newNimProc(primBind, false, 1))
  nimPrim("func", false, 1):    ni.funk(Blok(evalArg(ni)), false)
  nimPrim("funci", false, 1):   ni.funk(Blok(evalArg(ni)), true)
  nimPrim("do", false, 1):      evalArg(ni).evalDo(ni)
  nimPrim("^", false, 1):       arg(ni)
  nimPrim("eva", false, 1):     evalArg(ni)
  nimPrim("eval", false, 1):    evalArg(ni).eval(ni)
  nimPrim("parse", false, 1):   newParser().parse(StringVal(evalArg(ni)).value)

  # Control structures
  nimPrim("return", false, 1):
    ni.currentActivation.returned = true
    evalArg(ni)
  nimPrim("if", false, 2):
    if BoolVal(evalArg(ni)).value:
      return SeqComposite(evalArg(ni)).evalDo(ni)
    else:
      discard arg(ni) # Consume the block
      return ni.nilVal
  nimPrim("ifelse", false, 3):
    if BoolVal(evalArg(ni)).value:
      let res = SeqComposite(evalArg(ni)).evalDo(ni)
      discard arg(ni) # Consume second block
      return res
    else:
      discard arg(ni) # Consume first block
      return SeqComposite(evalArg(ni)).evalDo(ni)
  nimPrim("timesRepeat:", true, 2):
    let times = IntVal(evalArgInfix(ni)).value
    let fn = SeqComposite(evalArg(ni))
    for i in 1 .. times:
      result = fn.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("whileTrue:", true, 2):
    let blk1 = SeqComposite(evalArgInfix(ni))
    let blk2 = SeqComposite(evalArg(ni))
    while BoolVal(blk1.evalDo(ni)).value:
      result = blk2.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("whileFalse:", true, 2):
    let blk1 = SeqComposite(evalArgInfix(ni))
    let blk2 = SeqComposite(evalArg(ni))
    while not BoolVal(blk1.evalDo(ni)).value:
      result = blk2.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return

  # This is hard, because evalDo of fn wants to pull its argument from  
  # the parent activation, but there is none here. Hmmm.
  #nimPrim("do:", true, 2):
  #  let comp = SeqComposite(evalArgInfix(ni))
  #  let blk = SeqComposite(evalArg(ni))
  #  for node in comp.nodes:
  #    result = blk.evalDo(node, ni)

  # Parallel
  #nimPrim("parallel", true, 1):
  #  let comp = SeqComposite(evalArgInfix(ni))
  #  parallel:
  #    for node in comp.nodes:
  #      let blk = Blok(node)
  #      discard spawn blk.evalDo(ni)

  # Some scripting prims
  nimPrim("quit", false, 1):    quit(IntVal(evalArg(ni)).value)

  # Create and push root activation
  ni.rootActivation = newRootActivation(ni.root)
  ni.pushActivation(ni.rootActivation)

proc atEnd*(ni: Interpreter): bool {.inline.} =
  return ni.currentActivation.atEnd

proc funk*(ni: Interpreter, body: Blok, infix: bool): Node =
  result = newFunk(body, infix, ni.currentActivation)

method canEval*(self: Node, ni: Interpreter):bool {.base.} =
  false

method canEval*(self: EvalWord, ni: Interpreter):bool =
  let binding = ni.lookup(self)
  if binding.isNil:
    return false
  else:
    return binding.val.canEval(ni)

method canEval*(self: Binding, ni: Interpreter):bool =
  return self.val.canEval(ni)

method canEval*(self: Funk, ni: Interpreter):bool =
  true

method canEval*(self: NimProc, ni: Interpreter):bool =
  true

method canEval*(self: EvalArgWord, ni: Interpreter):bool =
  # Since arg words have a side effect they are "actions"
  true

method canEval*(self: GetArgWord, ni: Interpreter):bool =
  # Since arg words have a side effect they are "actions"
  true

method canEval*(self: Paren, ni: Interpreter):bool =
  true

method canEval*(self: Curly, ni: Interpreter):bool =
  true

# The heart of the interpreter - eval
method eval(self: Node, ni: Interpreter): Node =
  raiseRuntimeException("Should not happen")

method eval(self: Word, ni: Interpreter): Node =
  ## Look up
  let binding = ni.lookup(self)
  if binding.isNil:
    raiseRuntimeException("Word not found: " & $self)
  return binding.val.eval(ni)

method eval(self: GetWord, ni: Interpreter): Node =
  ## Look up only
  let hit = ni.lookup(self)
  if hit.isNil: ni.undefVal else: hit.val

method eval(self: GetSelfWord, ni: Interpreter): Node =
  ## Look up only
  let hit = ni.lookupLocal(self)
  if hit.isNil: ni.undefVal else: hit.val

method eval(self: GetOuterWord, ni: Interpreter): Node =
  ## Look up only
  let hit = ni.lookupParent(self)
  if hit.isNil: ni.undefVal else: hit.val

method eval(self: EvalWord, ni: Interpreter): Node =
  ## Look up only
  let hit = ni.lookup(self)
  if hit.isNil: ni.undefVal else: hit.val.eval(ni)

method eval(self: EvalSelfWord, ni: Interpreter): Node =
  ## Look up only
  let hit = ni.lookupLocal(self)
  if hit.isNil: ni.undefVal else: hit.val.eval(ni)

method eval(self: EvalOuterWord, ni: Interpreter): Node =
  ## Look up only
  let hit = ni.lookupParent(self)
  if hit.isNil: ni.undefVal else: hit.val.eval(ni)

method eval(self: LitWord, ni: Interpreter): Node =
  ## Evaluating a LitWord means creating a new word by stripping off \'
  newWord(self.word)

method eval(self: EvalArgWord, ni: Interpreter): Node =
  var arg: Node
  let previousActivation = ni.argParent()
  if ni.currentActivation.body.infix and ni.currentActivation.infixArg.isNil:
    arg = previousActivation.last # arg = parentArgInfix(ni)
    ni.currentActivation.infixArg = arg
  else:
    arg = previousActivation.next() # parentArg(ni)
  # This evaluation needs to be done in parent activation!
  let here = ni.currentActivation
  ni.currentActivation = previousActivation
  let ev = arg.eval(ni)
  ni.currentActivation = here
  discard ni.setBinding(self, ev)
  return ev

method eval(self: GetArgWord, ni: Interpreter): Node =
  var arg: Node
  let previousActivation = ni.argParent()
  if ni.currentActivation.body.infix and ni.currentActivation.infixArg.isNil:
    arg = previousActivation.last # arg = parentArgInfix(ni)
    ni.currentActivation.infixArg = arg
  else:
    arg = previousActivation.next() # parentArg(ni)
  discard ni.setBinding(self, arg)
  return arg

method eval(self: NimProc, ni: Interpreter): Node =
  return self.prok(ni)

proc eval(current: Activation, ni: Interpreter): Node =  
  ## This is the inner chamber of the heart :)
  ni.pushActivation(current)
  while not current.atEnd:
    let next = current.next()
    # Then we eval the node if it canEval
    if next.canEval(ni):
      current.last = next.eval(ni)
      if current.returned:
        ni.currentActivation.doReturn(ni)
        return current.last
    else:
      current.last = next
  if current.last of Binding:
    current.last = Binding(current.last).val
  ni.popActivation()
  return current.last

method eval(self: Funk, ni: Interpreter): Node =
  newActivation(self).eval(ni)

method eval(self: Paren, ni: Interpreter): Node =
  newActivation(self).eval(ni)

method eval(self: Curly, ni: Interpreter): Node =
  let activation = newActivation(self)
  discard activation.eval(ni)
  return activation.locals

method evalDo(self: Node, ni: Interpreter): Node =
  raiseRuntimeException("Do only works for sequences")

method evalDo(self: Blok, ni: Interpreter): Node =
  newActivation(self).eval(ni)

method evalDo(self: Paren, ni: Interpreter): Node =
  newActivation(self).eval(ni)

method evalDo(self: Curly, ni: Interpreter): Node =
  # Calling do on a curly doesn't do the locals trick
  newActivation(self).eval(ni)

proc evalRootDo*(self: Node, ni: Interpreter): Node =
  # Evaluate a node in the root activation
  # Ugly... First pop the root activation
  ni.popActivation()
  # This will push it back and... pop it too
  ni.rootActivation.body = Blok(self)
  ni.rootActivation.pos = 0
  result = ni.rootActivation.eval(ni)
  # ...so we need to put it back
  ni.pushActivation(ni.rootActivation)

method eval(self: Blok, ni: Interpreter): Node =
  self

method eval(self: Value, ni: Interpreter): Node =
  self

method eval(self: Dictionary, ni: Interpreter): Node =
  self

method eval(self: Binding, ni: Interpreter): Node =
  self.val

proc eval*(ni: Interpreter, code: string): Node =
  ## Evaluate code in a new activation
  SeqComposite(newParser().parse(code)).evalDo(ni)
  
proc evalRoot*(ni: Interpreter, code: string): Node =
  ## Evaluate code in the root activationevalRootDo
  SeqComposite(newParser().parse(code)).evalRootDo(ni)

