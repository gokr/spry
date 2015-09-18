# Ni Language
#
# Copyright (c) 2015 Göran Krampe

## TODO: Add mold and fix string representation vs mold representation
## TODO: Rewrite sample as tutorial1 and make it complete
## TODO: Add some funky stuff like compose
## TODO: Add objects and delegation
## TODO: Implement load save of the world

import strutils, sequtils, tables, nimprof, typetraits #, threadpool
import niparser

#{.experimental.}

type
  # Ni interpreter
  Interpreter* = ref object
    currentActivation*: Activation  # Execution spaghetti stack
    rootActivation*: RootActivation # The first one
    root*: Context                  # Root bindings
    trueVal*: Node
    falseVal*: Node
    nilVal*: Node

  RuntimeException* = object of Exception

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
  Activation* = ref object of RootObj
    last*: Node                     # Remember for infix
    infixArg*: Node                 # Used to hold the infix arg, if pulled
    returned*: bool                 # Mark return
    parent*: Activation
    pos*: int          # Which node we are at
    body*: Composite   # The composite representing code (Blok, Paren, Funk)

  # We want to distinguish different activations
  BlokActivation* = ref object of Activation
    context*: Context  # Local context, this is where we put named args etc
  FunkActivation* = ref object of BlokActivation
  ParenActivation* = ref object of Activation
  RootActivation* = ref object of BlokActivation

# Extending Ni from other modules, these callbacks will be called when
# a new Interpreter is created, see extend.nim for examples.
type InterpreterExt = proc(ni: Interpreter)
var interpreterExts = newSeq[InterpreterExt]()

proc addInterpreterExtension*(prok: InterpreterExt) =
  interpreterExts.add(prok)

# Forward declarations to make Nim happy
proc funk*(ni: Interpreter, body: Blok, infix: bool): Node
method eval*(self: Node, ni: Interpreter): Node
proc evalDo*(self: Node, ni: Interpreter): Node

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
    
# Base stuff for accessing
proc `[]`(self: Composite, i: int): Node =
  self.nodes[i]

proc `[]=`(self: Composite, i: int, n: Node) =
  self.nodes[i] = n
  
proc `[]`(self: Activation, i: int): Node =
  self.body.nodes[i]

proc len(self: Activation): int =
  self.body.nodes.len

# Constructor procs
proc raiseRuntimeException*(msg: string) =
  raise newException(RuntimeException, msg)

proc newNimProc*(prok: ProcType, infix: bool, arity: int): NimProc =
  NimProc(prok: prok, infix: infix, arity: arity)

proc newFunk*(body: Blok, infix: bool, parent: Activation): Funk =
  Funk(nodes: body.nodes, infix: infix, parent: parent)

proc newRootActivation(root: Context): RootActivation =
  RootActivation(body: newBlok(), context: root)

proc newActivation*(funk: Funk): FunkActivation =
  FunkActivation(body: funk)

proc newActivation*(body: Blok): Activation =
  BlokActivation(body: body)

proc newActivation*(body: Paren): ParenActivation =
  ParenActivation(body: body)

# Stack iterator walking parent refs
iterator stack(ni: Interpreter): Activation =
  var activation = ni.currentActivation
  while activation.notNil:
    yield activation
    activation = activation.parent

method hasContext(self: Activation): bool =
  true
  
method hasContext(self: ParenActivation): bool =
  false

method outer(self: Activation): Activation =
  # Just go caller parent, which works for Paren and Blok since they are
  # not lexical closures.
  self.parent

method outer(self: FunkActivation): Activation =
  # Instead of looking at my parent, which would be the caller
  # we go to the activation where I was created, thus a Funk is a lexical
  # closure.
  Funk(self.body).parent

# Walk contexts for lookups and binds. Skips parens since they do not have
# a Context and uses outer() that will let Funks go to their "lexical parent"
iterator contextWalk(first: Activation): Activation =
  var activation = first
  while activation.notNil:
    while not activation.hasContext():
      activation = activation.outer()
    yield activation
    activation = activation.outer()

# Walk activations for pulling arguments, here we strictly use
# parent to walk only up through the caller chain. Skipping paren activations.
iterator callerWalk(first: Activation): Activation =
  var activation = first
  # First skip over immediate paren activations
  while not activation.hasContext():
    activation = activation.parent
  # Then pick parent
  activation = activation.parent
  # Then we start yielding
  while activation.notNil:
    yield activation
    activation = activation.parent
    # Skip paren activations
    while not activation.hasContext():
      activation = activation.parent

# Textual dump for debugging
method dump(self: Activation) =
  echo "ACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]

method dump(self: ParenActivation) =
  echo "PARENACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]

method dump(self: FunkActivation) =
  echo "FUNKACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]
  echo($self.context)

method dump(self: BlokActivation) =
  echo "BLOKACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]
  echo($self.context)
  
proc dump(ni: Interpreter) =
  echo "STACK:"
  for a in ni.stack:
    dump(a)
    echo "-----------------------------"
  echo "========================================"

# Methods supporting the Nim math primitives with coercions
method `+`(a: Node, b: Node): Node {.inline.} =
  raiseRuntimeException("Can not evaluate " & $a & " + " & $b)
method `+`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value + b.value)
method `+`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float + b.value)
method `+`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value + b.value.float)
method `+`(a: FloatVal, b: FloatVal): Node {.inline.} =
  newValue(a.value + b.value)

method `-`(a: Node, b: Node): Node {.inline.} =
  raiseRuntimeException("Can not evaluate " & $a & " - " & $b)
method `-`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value - b.value)
method `-`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float - b.value)
method `-`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value - b.value.float)
method `-`(a: FloatVal, b: FloatVal): Node {.inline.} =
  newValue(a.value - b.value)

method `*`(a: Node, b: Node): Node {.inline.} =
  raiseRuntimeException("Can not evaluate " & $a & " * " & $b)
method `*`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value * b.value)
method `*`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float * b.value)
method `*`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value * b.value.float)
method `*`(a: FloatVal, b: FloatVal): Node {.inline.} =
  newValue(a.value * b.value)

method `/`(a: Node, b: Node): Node {.inline.} =
  raiseRuntimeException("Can not evaluate " & $a & " / " & $b)
method `/`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value / b.value)
method `/`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float / b.value)
method `/`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value / b.value.float)
method `/`(a,b: FloatVal): Node {.inline.} =
  newValue(a.value / b.value)

method `<`(a: Node, b: Node): Node {.inline.} =
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

method `<=`(a: Node, b: Node): Node {.inline.} =
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

method `==`(a: Node, b: Node): Node {.inline.} =
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

method `&`(a: Node, b: Node): Node {.inline.} =
  raiseRuntimeException("Can not evaluate " & $a & " & " & $b)
method `&`(a, b: StringVal): Node {.inline.} =
  newValue(a.value & b.value)
method `&`(a, b: Composite): Node {.inline.} =
  a.add(b.nodes)
  return a

proc `[]`(a: Composite, b: IntVal): Node {.inline.} =
  a[b.value]

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

method doReturn*(self: Activation, ni: Interpreter) =
  ni.currentActivation = self.parent
  ni.currentActivation.returned = true

method doReturn*(self: FunkActivation, ni: Interpreter) =
  ni.currentActivation = Funk(self.body).parent

method lookup(self: Activation, key: string): Binding =
  # Base implementation needed for dynamic dispatch to work
  nil

method lookup(self: BlokActivation, key: string): Binding =
  if self.context.notNil:
    return self.context.lookup(key)

proc lookup(ni: Interpreter, key: string): Binding =
  for activation in contextWalk(ni.currentActivation):
    let hit = activation.lookup(key)
    if hit.notNil:
      return hit

proc lookupLocal(ni: Interpreter, key: string): Binding =
  return ni.currentActivation.lookup(key)

proc lookupParent(ni: Interpreter, key: string): Binding =
  # Silly way of skipping to get to parent
  var inParent = false
  for activation in contextWalk(ni.currentActivation):
    if inParent:
      return activation.lookup(key)
    else:
      inParent = true

method makeBinding(self: Activation, key: string, val: Node): Binding =
  nil

method makeBinding(self: BlokActivation, key: string, val: Node): Binding =
  if self.context.isNil:
    self.context = newContext()
  return self.context.makeBinding(key, val)

proc makeBinding(ni: Interpreter, key: string, val: Node): Binding =
  # Bind in first activation with a context
  for activation in contextWalk(ni.currentActivation):
    return activation.makeBinding(key, val)

proc setBinding(ni: Interpreter, word: Word, value: Node): Binding =
  result = ni.lookup(word.word)
  if result.notNil:
    result.val = value
  else:
    result = ni.makeBinding(word.word, value)

method infix(self: Node): bool =
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


# A template reducing boilerplate for registering nim primitives
template nimPrim(name: string, infix: bool, arity: int, body: stmt): stmt {.immediate, dirty.} =
  discard root.makeBinding(name, newNimProc(
    proc (ni: Interpreter): Node = body, infix, arity))

proc newInterpreter*(): Interpreter =
  result = Interpreter(root: newContext())
  # Singletons
  result.trueVal = newValue(true)
  result.falseVal = newValue(false)
  result.nilVal = newNilVal()
  let root = result.root
  discard root.makeBinding("false", result.falseVal)
  discard root.makeBinding("true", result.trueVal)
  discard root.makeBinding("nil", result.nilVal)
   
  # Primitives in Nim
  nimPrim("=", true, 2):
    result = evalArg(ni) # Perhaps we could make it eager here? Pulling in more?
    discard ni.setBinding(Word(argInfix(ni)), result)
    
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
  nimPrim("&", true, 2):
    evalArgInfix(ni) & evalArg(ni)
  
  
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
  nimPrim("len", true, 1):  newValue(Composite(evalArgInfix(ni)).nodes.len) # Called length in Rebol
  nimPrim("at:", true, 2):   Composite(evalArgInfix(ni))[IntVal(evalArg(ni))]
  nimPrim("at:put:", true, 3): # Called poke in Rebol
    result = evalArgInfix(ni);
    Composite(result)[IntVal(evalArg(ni)).value] = evalArg(ni)
  nimPrim("read", true, 1): # Called at in Rebol
    let comp = Composite(evalArgInfix(ni))
    comp[comp.pos]
  nimPrim("write:", true, 2): # Called change in Rebol
    result = evalArgInfix(ni)
    let comp = Composite(result)
    comp[comp.pos] = evalArg(ni)
  nimPrim("add:", true, 2): 
    result = evalArgInfix(ni)
    let comp = Composite(result)
    comp.add(evalArg(ni))
  nimPrim("removeLast", true, 1):
    result = evalArgInfix(ni)
    let comp = Composite(result)
    comp.removeLast()
  
  # Positioning
  nimPrim("reset", true, 1):  Composite(evalArgInfix(ni)).pos = 0 # Called change in Rebol
  nimPrim("pos", true, 1):    newValue(Composite(evalArgInfix(ni)).pos) # ? in Rebol 
  nimPrim("pos:", true, 2):    # ? in Rebol
    result = evalArgInfix(ni)
    let comp = Composite(result)
    comp.pos = IntVal(evalArg(ni)).value
 
  # Streaming
  nimPrim("next", true, 1):
    let comp = Composite(evalArgInfix(ni))
    if comp.pos == comp.nodes.len:
      return ni.nilVal
    result = comp[comp.pos]
    inc(comp.pos)
  nimPrim("prev", true, 1):
    let comp = Composite(evalArgInfix(ni))
    if comp.pos == 0:
      return ni.nilVal
    dec(comp.pos)
    result = comp[comp.pos]
  nimPrim("end?", true, 1):
    let comp = Composite(evalArgInfix(ni))
    newValue(comp.pos == comp.nodes.len)

  # These are like in Rebol/Smalltalk but we use infix like in Smalltalk
  nimPrim("first", true, 1):  Composite(evalArgInfix(ni))[0]
  nimPrim("second", true, 1): Composite(evalArgInfix(ni))[1]
  nimPrim("third", true, 1):  Composite(evalArgInfix(ni))[2]
  nimPrim("fourth", true, 1): Composite(evalArgInfix(ni))[3]
  nimPrim("fifth", true, 1):  Composite(evalArgInfix(ni))[4]
  nimPrim("last", true, 1):
    let nodes = Composite(evalArgInfix(ni)).nodes
    nodes[nodes.high]

  #discard root.makeBinding("bind", newNimProc(primBind, false, 1))
  nimPrim("func", false, 1):    ni.funk(Blok(evalArg(ni)), false)
  nimPrim("funci", false, 1):   ni.funk(Blok(evalArg(ni)), true)
  nimPrim("do", false, 1):      Composite(evalArg(ni)).evalDo(ni)
  nimPrim("eval", false, 1):    evalArg(ni)
  nimPrim("parse", false, 1):   newParser().parse(StringVal(evalArg(ni)).value)

  # IO
  nimPrim("echo", false, 1):    echo($evalArg(ni))
 
  # Control structures
  nimPrim("return", false, 1):
    ni.currentActivation.returned = true
    evalArg(ni)
  nimPrim("if", false, 2):
    if BoolVal(evalArg(ni)).value:
      return Composite(evalArg(ni)).evalDo(ni)
    else:
      discard arg(ni) # Consume the block
      return ni.nilVal
  nimPrim("ifelse", false, 3):
    if BoolVal(evalArg(ni)).value:
      let res = Composite(evalArg(ni)).evalDo(ni)
      discard arg(ni) # Consume second block
      return res
    else:
      discard arg(ni) # Consume first block
      return Composite(evalArg(ni)).evalDo(ni)
  nimPrim("timesRepeat:", true, 2):
    let times = IntVal(evalArgInfix(ni)).value
    let fn = Composite(evalArg(ni))
    for i in 1 .. times:
      result = fn.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("whileTrue:", true, 2):
    let blk1 = Composite(evalArgInfix(ni))
    let blk2 = Composite(evalArg(ni))
    while BoolVal(blk1.evalDo(ni)).value:
      result = blk2.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("whileFalse:", true, 2):
    let blk1 = Composite(evalArgInfix(ni))
    let blk2 = Composite(evalArg(ni))
    while not BoolVal(blk1.evalDo(ni)).value:
      result = blk2.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return

  # This is hard, because evalDo of fn wants to pull its argument from  
  # the parent activation, but there is none here. Hmmm.
  #nimPrim("do:", true, 2):
  #  let comp = Composite(evalArgInfix(ni))
  #  let blk = Composite(evalArg(ni))
  #  for node in comp.nodes:
  #    result = blk.evalDo(node, ni)

  # Parallel
  #nimPrim("parallel", true, 1):
  #  let comp = Composite(evalArgInfix(ni))
  #  parallel:
  #    for node in comp.nodes:
  #      let blk = Blok(node)
  #      discard spawn blk.evalDo(ni)

  # Debugging
  nimPrim("dump", false, 0):    dump(ni)
  
  # Some scripting prims
  nimPrim("quit", false, 1):    quit(IntVal(evalArg(ni)).value)

  # Create and push root activation
  result.rootActivation = newRootActivation(root)
  result.pushActivation(result.rootActivation)
  
  # Call registered extension procs to the interpreter
  for ex in interpreterExts:
    ex(result)

proc atEnd*(ni: Interpreter): bool {.inline.} =
  return ni.currentActivation.atEnd

proc funk*(ni: Interpreter, body: Blok, infix: bool): Node =
  result = newFunk(body, infix, ni.currentActivation)

method canEval*(self: Node, ni: Interpreter):bool =
  false

method canEval*(self: EvalWord, ni: Interpreter):bool =
  let binding = ni.lookup(self.word)
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
  true

method canEval*(self: Paren, ni: Interpreter):bool =
  true

# The heart of the interpreter - eval
method eval(self: Node, ni: Interpreter): Node =
  raiseRuntimeException("Should not happen")

method eval(self: Word, ni: Interpreter): Node =
  ## Look up
  let binding = ni.lookup(self.word)
  if binding.isNil:
    raiseRuntimeException("Word not found: " & self.word)
  return binding.val.eval(ni)

method eval(self: GetWord, ni: Interpreter): Node =
  ## Look up only
  ni.lookup(self.word).val

method eval(self: GetLocalWord, ni: Interpreter): Node =
  ## Look up only
  ni.lookupLocal(self.word).val

method eval(self: GetParentWord, ni: Interpreter): Node =
  ## Look up only
  ni.lookup(self.word).val

method eval(self: LitWord, ni: Interpreter): Node =
  ## The word itself
  self

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
  ## Pull next argument, do not eval it and bind its word into a local word
  if ni.currentActivation.body.infix and ni.currentActivation.infixArg.isNil:
    ni.currentActivation.infixArg = argInfix(ni)
    return ni.setBinding(self, ni.currentActivation.infixArg).val
  else:
    return ni.setBinding(self, arg(ni)).val

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
 
proc evalDo(self: Node, ni: Interpreter): Node =
  newActivation(Blok(self)).eval(ni)

method evalRootDo(self: Node, ni: Interpreter): Node =
  ni.rootActivation.body = Blok(self)
  ni.rootActivation.pos = 0
  ni.rootActivation.eval(ni)

method eval(self: Blok, ni: Interpreter): Node =
  self

method eval(self: Value, ni: Interpreter): Node =
  self

method eval(self: Context, ni: Interpreter): Node =
  self

method eval(self: Binding, ni: Interpreter): Node =
  self.val

proc eval*(ni: Interpreter, code: string): Node =
  ## Evaluate code in a new activation
  Composite(newParser().parse(code)).evalDo(ni)
  
proc evalRoot*(ni: Interpreter, code: string): Node =
  ## Evaluate code in the root activation
  # First pop the root activation
  ni.popActivation()
  # This will push it back and... pop it too
  result = Composite(newParser().parse(code)).evalRootDo(ni)
  # ...so we need to put it back
  ni.pushActivation(ni.rootActivation)

when isMainModule:
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  discard newInterpreter().eval(code)
