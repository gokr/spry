# Ni Language
#
# Copyright (c) 2015 Göran Krampe

## TODO: Fix closures, perhaps move to cloning funcs as activation records as Self does
## TODO: Add mold and fix string representation vs mold representation
## TODO: Rewrite sample as tutorial1 and make it complete
## TODO: Add some funky stuff like compose
## TODO: Add objects and delegation
## TODO: Implement load save of the world

import strutils, sequtils, tables, nimprof, typetraits
import niparser

type
  # Ni interpreter
  Interpreter* = ref object
    currentActivation*: Activation  # Execution spaghetti stack
    root*: Context                  # Root bindings
    trueVal: Node
    falseVal: Node
    nilVal: Node

  RuntimeException* = object of Exception

  # Binding nodes for set and get words
  BindingNode = ref object of Node
    binding*: Binding
  GetBinding* = ref object of BindingNode
  SetBinding* = ref object of BindingNode
  
  # Node type to hold Nim primitive procs
  ProcType* = proc(ni: Interpreter, a: varargs[Node]): Node
  NimProc* = ref object of Node
    prok*: ProcType
    infix*: bool
    arity*: int 

  # An executable Ni function 
  Funk* = ref object of Blok
    infix*: bool
    parent*: Activation

  # The activation record used by Interpreter for evaluating Block/Paren.
  # This is a so called Spaghetti Stack with only a parent pointer so that they
  # can get garbage collected if not referenced by any other record anymore.
  Activation* = ref object of RootObj
    last*: Node                     # Remember for infix
    nextInfix*: bool                # Remember we are gobbling
    infixArg*: Node                 # Temporary holding
    returned*: bool                  # Mark return
    parent*: Activation
    pos*: int          # Which node we are at
    body*: Composite   # The composite representing code (Blok, Paren, Funk)

  # We want to distinguish different activations
  BlokActivation* = ref object of Activation
    context*: Context  # Local context, this is where we put named args etc
  FunkActivation* = ref object of BlokActivation
  ParenActivation* = ref object of Activation
  RootActivation* = ref object of BlokActivation

# Extending Ni from other modules
type InterpreterExt = proc(ni: Interpreter)
var interpreterExts = newSeq[InterpreterExt]()

proc addInterpreterExtension*(prok: InterpreterExt) =
  interpreterExts.add(prok)

# Forward declarations
proc funk*(ni: Interpreter, body: Blok, infix: bool): Node
method resolveComposite*(self: Composite, ni: Interpreter): Node
method resolve*(self: Node, ni: Interpreter): Node
method eval*(self: Node, ni: Interpreter): Node
method evalDo*(self: Node, ni: Interpreter): Node

# String representations
method `$`*(self: NimProc): string =
  if self.infix:
    result = "proc-infix"
  else:
    result = "proc"
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

method `$`*(self: GetBinding): string =
  when false:
    "%" & $self.binding & "%"
  else:
    $self.binding.key

method `$`*(self: SetBinding): string =
  when false:
    ":%" & $self.binding & "%"
  else:
    ":" & $self.binding.val

# Base stuff
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

proc newGetBinding*(b: Binding): GetBinding =
  GetBinding(binding: b)

proc newSetBinding*(b: Binding): SetBinding =
  SetBinding(binding: b)

proc newRootActivation(root: Context): Activation =
  RootActivation(body: newBlok(), context: root)

proc newActivation*(funk: Funk): FunkActivation =
  FunkActivation(body: funk)

proc newActivation*(body: Blok): Activation =
  BlokActivation(body: body)

proc newActivation*(body: Paren): Activation =
  Activation(body: body)

# Resolving
method resolveComposite*(ni: Interpreter, self: Composite): Node =
  if not self.resolved:
    discard self.resolveComposite(ni)
    # TODO: self.resolved = true
  return self

# Stack iterator
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
  # Just go caller parent, which works for Paren and Blok
  self.parent

method outer(self: FunkActivation): Activation =
  # Instead of looking at my parent, which would be the caller
  # we go to the activation where I was created
  Funk(self.body).parent

# Walk activations for lookups and binds
iterator parentWalk(first: Activation): Activation =
  var activation = first
  while activation.notNil:
    yield activation
    activation = activation.outer()
    if activation.notNil:
      while not activation.hasContext():
        activation = activation.outer()      

# Debugging
method isFunk(self: Activation):bool =
  false
method isFunk(self: FunkActivation):bool =
  true

method dump(self: Activation) =
  echo "ACTIVATION POS: " & $self.pos

method dump(self: FunkActivation) =
  echo "FUNKACTIVATION POS: " & $self.pos

method dump(self: BlokActivation) =
  echo "BLOKACTIVATION POS: " & $self.pos
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


proc `[]`(a: Composite, b: IntVal): Node {.inline.} =
  a[b.value]

proc pushActivation*(ni: Interpreter, activation: Activation)  {.inline.} =
  activation.parent = ni.currentActivation
  ni.currentActivation = activation
  ni.currentActivation.last = nil

proc popActivation*(ni: Interpreter)  {.inline.} =
  ni.currentActivation = ni.currentActivation.parent

# A template reducing boilerplate for registering nim primitives
template nimPrim(name: string, infix: bool, arity: int, body: stmt): stmt {.immediate, dirty.} =
   discard root.bindit(name, newNimProc(
    proc (ni: Interpreter, a: varargs[Node]): Node =
      body, infix, arity))

proc newInterpreter*(): Interpreter =
  result = Interpreter(root: newContext())
  # Singletons
  result.trueVal = newValue(true)
  result.falseVal = newValue(false)
  result.nilVal = newNilVal()
  let root = result.root
  discard root.bindit("false", result.falseVal)
  discard root.bindit("true", result.trueVal)
  discard root.bindit("nil", result.nilVal)
    
  # Primitives in Nim
  # Basic math
  nimPrim("+", true, 2):  a[0] + a[1]
  nimPrim("-", true, 2):  a[0] - a[1]
  nimPrim("*", true, 2):  a[0] * a[1]
  nimPrim("/", true, 2):  a[0] / a[1]
  
  # Comparisons
  nimPrim("<", true, 2):  a[0] < a[1]
  nimPrim(">", true, 2):  a[1] < a[0]
  nimPrim("<=", true, 2):  a[0] <= a[1]
  nimPrim(">=", true, 2):  a[1] <= a[0]
  nimPrim("==", true, 2):  a[0] == a[1]

  # Booleans
  nimPrim("not", false, 1): newValue(not BoolVal(a[0]).value)
  nimPrim("and", true, 2):  newValue(BoolVal(a[0]).value and BoolVal(a[1]).value)
  nimPrim("or", true, 2):   newValue(BoolVal(a[0]).value or BoolVal(a[1]).value)

  # Strings
  nimPrim("&", true, 2):    newValue(StringVal(a[0]).value & StringVal(a[1]).value)  
  
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
  nimPrim("len", true, 1):  newValue(Composite(a[0]).nodes.len) # Called length in Rebol
  nimPrim("at", true, 2):   Composite(a[0])[IntVal(a[1])]
  nimPrim("put", true, 3): # Called poke in Rebol
    result = a[0];
    Composite(result)[IntVal(a[1]).value] = a[2]
  nimPrim("read", true, 1): # Called at in Rebol
    let comp = Composite(a[0])
    comp[comp.pos]
  nimPrim("write", true, 2): # Called change in Rebol
    result = a[0]
    let comp = Composite(result)
    comp[comp.pos] = a[1]
# This is hard, because evalDo of fn wants to pull its argument from
# the parent activation, but there is none here. Hmmm.
#  nimPrim("do", true, 2):
#    let fn = ni.resolveComposite(Composite(a[1]))
#    for node in Composite(a[0]).nodes:
#      result = fn.evalDo(ni)

  
  # Positioning
  nimPrim("reset", true, 1):  Composite(a[0]).pos = 0 # Called change in Rebol
  nimPrim("pos", true, 1):    newValue(Composite(a[0]).pos) # ? in Rebol 
  nimPrim("setpos", true, 2):    # ? in Rebol
    result = a[0]
    let comp = Composite(result)
    comp.pos = IntVal(a[1]).value
 
  # Streaming
  nimPrim("next", true, 1):
    let comp = Composite(a[0])
    result = comp[comp.pos]
    inc(comp.pos)
  nimPrim("end?", true, 1):
    let comp = Composite(a[0])
    newValue(comp.pos == comp.nodes.len)

  # These are like in Rebol/Smalltalk but we use infix like in Smalltalk
  nimPrim("first", true, 1):  Composite(a[0])[0]
  nimPrim("second", true, 1): Composite(a[0])[1]
  nimPrim("third", true, 1):  Composite(a[0])[2]
  nimPrim("fourth", true, 1): Composite(a[0])[3]
  nimPrim("fifth", true, 1):  Composite(a[0])[4]
  nimPrim("last", true, 1):   Composite(a[0]).nodes[^1]

  #discard root.bindit("bind", newNimProc(primBind, false, 1))
  nimPrim("func", false, 1):    ni.funk(Blok(a[0]), false)
  nimPrim("funci", false, 1):   ni.funk(Blok(a[0]), true)
  nimPrim("resolve", false, 1): ni.resolveComposite(Composite(a[0]))
  nimPrim("do", false, 1):    ni.resolveComposite(Composite(a[0])).evalDo(ni)
  nimPrim("eval", false, 1):    Composite(a[0]).evalDo(ni)
  nimPrim("parse", false, 1):   newParser().parse(StringVal(a[0]).value)

  # IO
  nimPrim("echo", false, 1):    echo($a[0])
 
  # Control structures
  nimPrim("return", false, 1):
    ni.currentActivation.returned = true
    a[0]
  nimPrim("if", false, 2):
    if BoolVal(a[0]).value:
      ni.resolveComposite(Composite(a[1])).evalDo(ni)
    else:
      ni.nilVal
  nimPrim("ifelse", false, 3):
    if BoolVal(a[0]).value:
      ni.resolveComposite(Composite(a[1])).evalDo(ni)
    else:
      ni.resolveComposite(Composite(a[2])).evalDo(ni)
  nimPrim("loop", false, 2):
    let fn = ni.resolveComposite(Composite(a[1]))
    for i in 1 .. IntVal(a[0]).value:
      result = fn.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("timesRepeat", true, 2):
    let fn = ni.resolveComposite(Composite(a[1]))
    for i in 1 .. IntVal(a[0]).value:
      result = fn.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("whileTrue", true, 2):
    let blk1 = ni.resolveComposite(Composite(a[0]))
    let blk2 = ni.resolveComposite(Composite(a[1]))
    while BoolVal(blk1.evalDo(ni)).value:
      result = blk2.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return
  nimPrim("whileFalse", true, 2):
    let blk1 = ni.resolveComposite(Composite(a[0]))
    let blk2 = ni.resolveComposite(Composite(a[1]))
    while not BoolVal(blk1.evalDo(ni)).value:
      result = blk2.evalDo(ni)
      # Or else non local returns don't work :)
      if ni.currentActivation.returned:
        return

  # Debugging
  nimPrim("dump", false, 0):    dump(ni)
  
  # Some scripting prims
  nimPrim("quit", false, 1):    quit(IntVal(a[0]).value)

  # Create root activation
  result.pushActivation(newRootActivation(root))
  
  # Call registered extension procs to the interpreter
  for ex in interpreterExts:
    ex(result)


proc top*(ni: Interpreter): Activation =
  ni.currentActivation

method lookup(self: Activation, key: string): Binding =
#  echo "OOPS"
  nil

method lookup(self: BlokActivation, key: string): Binding =
#  echo "BLOKLOOKUP"
  if self.context.notNil:
#    echo "LOOKING"
    return self.context.lookup(key)

method bindit(self: Activation, key: string, val: Node): Binding =
#  echo "ACTIVATION BINDIT!"
  nil

method bindit(self: BlokActivation, key: string, val: Node): Binding =
#  echo "BLOKACTIVATION BINDIT!"
  if self.context.isNil:
    self.context = newContext()
  return self.context.bindit(key, val)

proc lookup(ni: Interpreter, key: string): Binding =
  #ni.dump()
  #debug "LOOKUP OF: " & key
  # This stack walk will not go up past a FunkActivation
  for activation in parentWalk(ni.currentActivation):
    #dump(activation)
    let hit = activation.lookup(key)
    if hit.notNil:
      #echo "FOUND: " & $hit
      return hit
  
proc bindit(ni: Interpreter, key: string, val: Node): Binding =
  for activation in parentWalk(ni.currentActivation):
    let binding = activation.bindit(key, val)
    if binding.notNil: return binding
    
method infix(self: Node): bool =
  false

method infix(self: Funk): bool =
  self.infix
  
method infix(self: NimProc): bool =
  self.infix

method infix(self: GetBinding): bool =
  self.binding.val.infix

proc atEnd(self: Activation): bool {.inline.} =
  self.pos == self.len

proc next*(self: Activation): Node {.inline.} =
  if self.atEnd:
    raiseRuntimeException("End of current block, too few arguments?")
  else:
    result = self[self.pos]
    inc(self.pos)

proc peek*(self: Activation): Node {.inline.} =
  ## Peek next node in the current block Activation.
  self[self.pos]

proc isNextInfix*(self: Activation): bool {.inline.} =
  not self.atEnd and self.peek.infix 

proc evalNext*(self: Activation, ni: Interpreter): Node {.inline.} =
  ## Evaluate the next node in this Activation.
  ## We use a flag to know if we are going ahead to gobble an infix
  ## so we only do it once. Otherwise prefix words will go right to left...
  self.last = self.next.eval(ni)
  if self.nextInfix:
    self.nextInfix = false
    return self.last
  if self.isNextInfix:
    self.nextInfix = true
    self.last = self.next.eval(ni)
  return self.last

proc evalNext*(ni: Interpreter): Node =
  ## Evaluate the next node in the current block Activation.
  return ni.currentActivation.evalNext(ni)

proc atEnd*(ni: Interpreter): bool {.inline.} =
  return ni.currentActivation.atEnd

method resolve(self: Node, ni: Interpreter): Node =
  ## Base case, we only resolve GetWord and SetWord
#  echo "NOT RESOLVING (NOT A GETSETWORD): " & $self
  nil

method resolve(self: GetBinding, ni: Interpreter): Node =
  let hit = ni.lookup(self.binding.key)
  if hit.notNil:
#    echo "REFOUND GETBINDING: " & self.binding.key & " = " & $hit
    return newGetBinding(hit)
#  else:
#    echo "NOT REFOUND GETWORD: " & self.binding.key

method resolve(self: SetBinding, ni: Interpreter): Node =
  let hit = ni.lookup(self.binding.key)
  if hit.notNil:
#    echo "REFOUND SETBINDING: " & self.binding.key & " = " & $hit
    return newSetBinding(hit)
#  else:
#    echo "NOT REFOUND SETWORD: " & self.binding.key

method resolve(self: Word, ni: Interpreter): Node =
  let hit = ni.lookup(self.word)
  if hit.notNil:
#    echo "FOUND GETBINDING: " & self.word & " = " & $hit
    return newGetBinding(hit)
#  else:
#    echo "NOT FOUND GETWORD: " & self.word

method resolve(self: SetWord, ni: Interpreter): Node =
  let hit = ni.lookup(self.word)
  if hit.notNil:
#    echo "FOUND SETBINDING: " & self.word & " = " & $hit
    return newSetBinding(hit)
#  else:
#    echo "NOT FOUND SETWORD: " & self.word

method resolve(self: Composite, ni: Interpreter): Node =
  ## Go through nodes (no recurse) and do lookups of words, replacing with the binding.
  for pos,child in mpairs(self.nodes):
    let binding = child.resolve(ni)
    if binding.notNil:
#      echo "BINDING IN COMPOSITE: " & $binding
      self.nodes[pos] = binding
  return nil

method resolveComposite(self: Composite, ni: Interpreter): Node =
  ## Go through nodes (no recurse) and do lookups of words, replacing with the binding.
  for pos,child in mpairs(self.nodes):
    let binding = child.resolve(ni)
    if binding.notNil:
#      echo "BINDING IN COMPOSITE: " & $binding
      self.nodes[pos] = binding
  return nil

proc funk*(ni: Interpreter, body: Blok, infix: bool): Node =
  result = newFunk(body, infix, ni.top)
  # Resolve recursively for now
  for pos,child in mpairs(body.nodes):
    let binding = child.resolve(ni)
    if binding.notNil:
      body.nodes[pos] = binding

# The heart of the interpreter - eval
method eval(self: Node, ni: Interpreter): Node =
  raiseRuntimeException("Should not happen")

method eval(self: Word, ni: Interpreter): Node =
  ## Look up and evaluate
  let binding = ni.lookup(self.word)
  if binding.isNil:
    raiseRuntimeException("Word not found: " & self.word)
  binding.val.eval(ni)

method eval(self: SetWord, ni: Interpreter): Node =
  ## Evaluate next, bind it and return result
  ni.bindit(self.word, ni.evalNext()).val

method eval(self: GetWord, ni: Interpreter): Node =
  ## Look up only
  ni.lookup(self.word).val

method eval(self: LitWord, ni: Interpreter): Node =
  ## The word itself
  self

method eval(self: ArgWord, ni: Interpreter): Node =
  ## Pull next argument from parent activation
  if ni.currentActivation.infixArg.isNil:
    return ni.currentActivation.bindit(self.word, ni.currentActivation.parent.evalNext(ni)).val
  else:
    let arg = ni.currentActivation.infixArg
    ni.currentActivation.infixArg = nil
    return ni.currentActivation.bindit(self.word, arg).val
    
method eval(self: NimProc, ni: Interpreter): Node =
  ## This code uses an array to avoid allocating a seq every time
  var args: array[1..20, Node]
  if self.infix:
    # If infix we use the last one
    args[1] = ni.currentActivation.last  
    # Pull remaining args to reach arity
    for i in 2 .. self.arity:
      args[i] = ni.evalNext()
  else:
    # Pull remaining args to reach arity
    for i in 1 .. self.arity:
      args[i] = ni.evalNext()
  result = self.prok(ni, args)

method eval(self: Funk, ni: Interpreter): Node =
  let previous = ni.currentActivation
  let current: FunkActivation = newActivation(self)
  ni.pushActivation(current)
  if self.infix:
    # If infix we use the last one
    current.infixArg = previous.last  
  while not current.atEnd:
    discard current.evalNext(ni)
    if current.returned:
      echo "RETURN FROM FUNK"
      ni.currentActivation = Funk(current.body).parent
      return current.last
  ni.popActivation()
  return current.last

method eval(self: Paren, ni: Interpreter): Node =
  let current = newActivation(self)
  ni.pushActivation(current)
  while not current.atEnd:
    discard current.evalNext(ni)
    if current.returned:
      echo "RETURN FROM PAREN"
      ni.popActivation()
      ni.currentActivation.returned = true
      return current.last
  ni.popActivation()
  return current.last

method evalDo(self: Node, ni: Interpreter): Node =
  let current = newActivation(Blok(self))
  ni.pushActivation(current)
  while not current.atEnd:
    discard current.evalNext(ni)
    if current.returned:
      echo "RETURN FROM BLOK"
      ni.popActivation()
      ni.currentActivation.returned = true
      return current.last
  ni.popActivation()
  return current.last

  
method eval(self: Blok, ni: Interpreter): Node =
  self

method eval(self: Value, ni: Interpreter): Node =
  self

method eval(self: Context, ni: Interpreter): Node =
  self

method eval(self: GetBinding, ni: Interpreter): Node =
  # Eval of a niBinding is like a static fast niWord
  self.binding.val.eval(ni)

method eval(self: SetBinding, ni: Interpreter): Node =
  # Eval of a niSetBinding is like a static fast niSetWord
  result = ni.evalNext()
  self.binding.val = result

proc eval*(ni: Interpreter, code: string): Node =
  ni.resolveComposite(Composite(newParser().parse(code))).evalDo(ni)

when isMainModule:
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  discard newInterpreter().eval(code)
