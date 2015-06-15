# Ni Language
#
# Copyright (c) 2015 Göran Krampe

## TODO: Move to slimmer func syntax with new word formats using > ->

import strutils, sequtils, tables, nimprof, typetraits
import niparser

type
  # Ni interpreter
  Interpreter* = ref object
    last*: Node                     # Remember for infix
    nextInfix*: bool                # Remember we are gobbling
    currentActivation*: Activation  # Execution spaghetti stack
    currentActivationLen*: int
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

  # An executable Ni function, 1st element is spec, 2nd element is body 
  Funk* = ref object of Blok
    infix*: bool
    parent*: Activation

  # The activation record used by Interpreter for evaluating Block/Paren.
  # This is a so called Spaghetti Stack with only a parent pointer.
  Activation* = ref object of RootObj
    parent*: Activation
    pos*: int          # Which node we are at
    body*: Composite   # The composite representing code (Blok, Paren, Funk body)

  # We want to distinguish different activations
  BlokActivation = ref object of Activation
    context*: Context  # Local context, this is where we put named args etc
  FunkActivation* = ref object of BlokActivation
    funk*: Funk
  ParenActivation* = ref object of Activation
  RootActivation* = ref object of BlokActivation

# Extending Ni from other modules
type InterpreterExt = proc(ni: Interpreter)
var interpreterExts = newSeq[InterpreterExt]()

proc addInterpreterExtension*(prok: InterpreterExt) =
  interpreterExts.add(prok)

# Forward declarations
proc funk*(ni: Interpreter, spec, body: Blok, infix: bool): Node
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
      result = "func-infix"
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

# Funk stuff
proc spec(self: Funk): Blok =
  Blok(self[0])

proc body(self: Funk): Blok =
  Blok(self[1])

proc arity(self: Funk): int =
  self.spec.nodes.len

# Constructor procs
proc raiseRuntimeException*(msg: string) =
  raise newException(RuntimeException, msg)

proc newNimProc*(prok: ProcType, infix: bool, arity: int): NimProc =
  NimProc(prok: prok, infix: infix, arity: arity)

proc newFunk*(spec: Blok, body: Blok, infix: bool, parent: Activation): Funk =
  var nodes: seq[Node] = @[]
  nodes.add(spec)
  nodes.add(body)
  Funk(nodes: nodes, infix: infix, parent: parent)

proc newGetBinding*(b: Binding): GetBinding =
  GetBinding(binding: b)

proc newSetBinding*(b: Binding): SetBinding =
  SetBinding(binding: b)

proc newRootActivation(root: Context): Activation =
  RootActivation(body: newBlok(), context: root)

proc newActivation*(funk: Funk, args: openarray[Node]): Activation =
  var cont: Context
  # Skipping newContext if no arguments
  if funk.arity > 0:
    cont = newContext()
    # Bind arguments into the activation context
    let spec = funk.spec
    for i,param in pairs(args):
#      echo "BINDING ARGUMENT: " & Word(spec[i]).word & " = " & $param 
      discard cont.bindit(Word(spec[i]).word, param)
  FunkActivation(funk: funk, body: funk.body, context: cont)

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
  self.funk.parent

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
method dump(self: Activation) =
  echo "POS: " & $self.pos

method dump(self: BlokActivation) =
  echo "POS: " & $self.pos
  echo($self.context)
  
proc dump(ni: Interpreter) =
  echo "STACK:"
  for a in ni.stack:
    dump(a)
    echo "-----------------------------"
  echo "========================================"

# Primitives written in Nim
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
proc primAdd(ni: Interpreter, a: varargs[Node]): Node =
  a[0] + a[1]

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
proc primSub(ni: Interpreter, a: varargs[Node]): Node =
  a[0] - a[1]

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
proc primMul(ni: Interpreter, a: varargs[Node]): Node =
  a[0] * a[1]

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
proc primDiv(ni: Interpreter, a: varargs[Node]): Node =
  a[0] / a[1]

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
proc primLt(ni: Interpreter, a: varargs[Node]): Node =
  a[0] < a[1]

method `>`(a: Node, b: Node): Node {.inline.} =
  raiseRuntimeException("Can not evaluate " & $a & " < " & $b)
method `>`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value > b.value)
method `>`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float > b.value)
method `>`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value > b.value.float)
method `>`(a,b: FloatVal): Node {.inline.} =
  newValue(a.value > b.value)
method `>`(a,b: StringVal): Node {.inline.} =
  newValue(a.value > b.value)
proc primGt(ni: Interpreter, a: varargs[Node]): Node =
  a[0] > a[1]

proc `[]`(a: Composite, b: IntVal): Node {.inline.} =
  a[b.value]
#proc `[]=`(a: Composite, b: IntVal, c: Node): Node {.inline.} =
#  a[b.value] = c
proc primLen(ni: Interpreter, a: varargs[Node]): Node =
  newValue(Composite(a[0]).nodes.len)
proc primAt(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0])[IntVal(a[1])]
proc primPut(ni: Interpreter, a: varargs[Node]): Node =
  result = a[0]
  Composite(result)[IntVal(a[1]).value] = a[2]
proc primRead(ni: Interpreter, a: varargs[Node]): Node =
  let comp = Composite(a[0])
  comp[comp.pos]
proc primWrite(ni: Interpreter, a: varargs[Node]): Node =
  result = a[0]
  let comp = Composite(result)
  comp[comp.pos] = a[1]

proc primReset(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0]).pos = 0
proc primPos(ni: Interpreter, a: varargs[Node]): Node =
  newValue(Composite(a[0]).pos)
proc primSetPos(ni: Interpreter, a: varargs[Node]): Node =
  result = a[0]
  let comp = Composite(result)
  comp.pos = IntVal(a[1]).value
proc primNext(ni: Interpreter, a: varargs[Node]): Node =
  let comp = Composite(a[0])
  result = comp[comp.pos]
  inc(comp.pos)

proc primFirst(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0])[0]
proc primSecond(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0])[1]
proc primThird(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0])[2]
proc primFourth(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0])[3]
proc primFifth(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0])[4]
proc primLast(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0]).nodes[^1]


proc primDo(ni: Interpreter, a: varargs[Node]): Node =
  ni.resolveComposite(Composite(a[0])).evalDo(ni)

proc primEval(ni: Interpreter, a: varargs[Node]): Node =
  Composite(a[0]).evalDo(ni)

proc primFunk(ni: Interpreter, a: varargs[Node]): Node =
  ni.funk(Blok(a[0]), Blok(a[1]), false)

proc primFunkInfix(ni: Interpreter, a: varargs[Node]): Node =
  ni.funk(Blok(a[0]), Blok(a[1]), true)
  
proc primResolve(ni: Interpreter, a: varargs[Node]): Node =
  ni.resolveComposite(Composite(a[0]))
  
proc primParse(ni: Interpreter, a: varargs[Node]): Node =
  newParser().parse(StringVal(a[0]).value)
  
proc primEcho(ni: Interpreter, a: varargs[Node]): Node =
  echo($a[0])

proc primIf(ni: Interpreter, a: varargs[Node]): Node =
  if BoolVal(a[0]).value: ni.primDo(a[1]) else: ni.nilVal

proc primIfelse(ni: Interpreter, a: varargs[Node]): Node =
  if BoolVal(a[0]).value: ni.primDo(a[1]) else: ni.primDo(a[2])

proc primLoop(ni: Interpreter, a: varargs[Node]): Node =
  let fn = ni.resolveComposite(Composite(a[1]))
  for i in 1 .. IntVal(a[0]).value:
    result = fn.evalDo(ni)

proc primDump(ni: Interpreter, a: varargs[Node]): Node =
  dump(ni)

proc pushActivation*(ni: Interpreter, activation: Activation)  {.inline.} =
  activation.parent = ni.currentActivation
  ni.currentActivation = activation
  ni.currentActivationLen = activation.len
  ni.last = nil

proc popActivation*(ni: Interpreter)  {.inline.} =
  ni.currentActivation = ni.currentActivation.parent
  if ni.currentActivation.notNil:
    ni.currentActivationLen = ni.currentActivation.len
  else:
    ni.currentActivationLen = 0

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
  discard root.bindit("+", newNimProc(primAdd, true, 2))
  discard root.bindit("-", newNimProc(primSub, true, 2))
  discard root.bindit("*", newNimProc(primMul, true, 2))
  discard root.bindit("/", newNimProc(primDiv, true, 2))
  discard root.bindit("<", newNimProc(primLt, true, 2))
  discard root.bindit(">", newNimProc(primGt, true, 2))
  
  # Booleans
  discard root.bindit("not", newNimProc(
    proc (ni: Interpreter, a: varargs[Node]): Node =
      newValue(not BoolVal(a[0]).value), false, 1))
  discard root.bindit("and", newNimProc(
    proc (ni: Interpreter, a: varargs[Node]): Node =
      newValue(BoolVal(a[0]).value and BoolVal(a[1]).value), true, 2))  
  discard root.bindit("or", newNimProc(
    proc (ni: Interpreter, a: varargs[Node]): Node =
      newValue(BoolVal(a[0]).value or BoolVal(a[1]).value), true, 2))
  
  # Strings
  discard root.bindit("&", newNimProc(
    proc (ni: Interpreter, a: varargs[Node]): Node =
      newValue(StringVal(a[0]).value & StringVal(a[1]).value), true, 2))  
  
  # Basic blocks
  #discard root.bindit("head", newNimProc(primHead, true, 2)) # Collides with Lisp
  #discard root.bindit("tail", newNimProc(primTail, true, 2)) # Collides with Lisp

  # at: and at:put: in Smalltalk seems to be pick/poke in Rebol
  # change/at is similar in Rebol but operate at current "positition"
  # Ni uses at/put instead of pick/poke and read/write instead of change/at
  
  # Left to think about is peek/poke (Rebol has no peek) and perhaps pick/drop
  # The old C64 Basic had peek/poke for memory at:/at:put: ... :) Otherwise I
  # generally associate peek with lookahead.
  # Idea here: Use xxx? for boolean funcs and xxx! for void funcs
  discard root.bindit("len", newNimProc(primLen, true, 1))  # Called length in Rebol
  discard root.bindit("at", newNimProc(primAt, true, 2))  # Called pick in Rebol
  discard root.bindit("put", newNimProc(primPut, true, 3))  # Called poke in Rebol
  discard root.bindit("read", newNimProc(primRead, true, 1))  # Called at in Rebol
  discard root.bindit("write", newNimProc(primWrite, true, 2))  # Called change in Rebol
  
  # Positioning
  discard root.bindit("reset", newNimProc(primReset, true, 1))  # Called change in Rebol
  discard root.bindit("pos", newNimProc(primPos, true, 1))  # ? in Rebol 
  discard root.bindit("setpos", newNimProc(primSetPos, true, 2))  # ? in Rebol
 
  # Streaming
  discard root.bindit("next", newNimProc(primNext, true, 1))  # ? in Rebol

  # These are like in Rebol/Smalltalk but we use infix like in Smalltalk
  discard root.bindit("first", newNimProc(primFirst, true, 1))
  discard root.bindit("second", newNimProc(primSecond, true, 1))
  discard root.bindit("third", newNimProc(primThird, true, 1))
  discard root.bindit("fourth", newNimProc(primFourth, true, 1))
  discard root.bindit("fifth", newNimProc(primFifth, true, 1))
  discard root.bindit("last", newNimProc(primLast, true, 1))
  
  #discard root.bindit("bind", newNimProc(primBind, false, 1))
  discard root.bindit("func", newNimProc(primFunk, false, 2))
  discard root.bindit("func-infix", newNimProc(primFunkInfix, false, 2))
  discard root.bindit("resolve", newNimProc(primResolve, false, 1))
  discard root.bindit("do", newNimProc(primDo, false, 1))
  discard root.bindit("eval", newNimProc(primEval, false, 1))
  discard root.bindit("parse", newNimProc(primParse, false, 1))

  # IO
  discard root.bindit("echo", newNimProc(primEcho, false, 1))

  # Control structures
  discard root.bindit("if", newNimProc(primIf, false, 2))
  discard root.bindit("ifelse", newNimProc(primIfelse, false, 3))
  discard root.bindit("loop", newNimProc(primLoop, false, 2))

  # Debugging
  discard root.bindit("dump", newNimProc(primDump, false, 0))
  
  # Some scripting prims
  discard root.bindit("quit", newNimProc(
    proc (ni: Interpreter, a: varargs[Node]): Node =
      quit(IntVal(a[0]).value), false, 1)) 
  
  result.pushActivation(newRootActivation(root))
  # Call registered extension procs
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


proc endOfNode*(ni: Interpreter): bool {.inline.} =
  ni.currentActivation.pos == ni.currentActivationLen

proc next*(ni: Interpreter): Node  {.inline.} =
  ## Get next node in the current block Activation.
  if ni.endOfNode:
    raiseRuntimeException("End of current block, too few arguments")
  else:
    result = ni.currentActivation[ni.currentActivation.pos]
    inc(ni.currentActivation.pos)

proc peek*(ni: Interpreter): Node =
  ## Peek next node in the current block Activation.
  ni.currentActivation[ni.currentActivation.pos]

proc isNextInfix(ni: Interpreter): bool =
  not ni.endOfNode and ni.peek.infix 

proc evalNext*(ni: Interpreter): Node =
  ## Evaluate the next node in the current block Activation.
  ## We use a flag to know if we are going ahead to gobble an infix
  ## so we only do it once. Otherwise prefix words will go right to left...
  ni.last = ni.next.eval(ni)
  if ni.nextInfix:
    ni.nextInfix = false
    return ni.last
  if ni.isNextInfix:
    ni.nextInfix = true
    ni.last = ni.next.eval(ni)
  return ni.last


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

method resolveComposite(self: Composite, ni: Interpreter): Node =
  ## Go through nodes (no recurse) and do lookups of words, replacing with the binding.
  for pos,child in mpairs(self.nodes):
    let binding = child.resolve(ni)
    if binding.notNil:
#      echo "BINDING IN COMPOSITE: " & $binding
      self.nodes[pos] = binding
  return nil

proc funk*(ni: Interpreter, spec, body: Blok, infix: bool): Node =
  result = newFunk(spec, body, infix, ni.top)
  var locals = newSeq[string]()
  # The parameter names we do not want to bind
  for n in spec.nodes:
    locals.add(Word(n).word)
  # Resolve one level deep
  for pos,child in mpairs(body.nodes):
    let binding = child.resolve(ni)
    if binding.notNil:
      # Only if not a param
      if not locals.contains(BindingNode(binding).binding.key): 
#        echo "BOUND IN NEWFUNK:" & $(BindingNode(binding).binding)
        body.nodes[pos] = binding
#      else:
#        echo "NOT BOUND IN NEWFUNK, IS LOCAL: " & BindingNode(binding).binding.key

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

method eval(self: NimProc, ni: Interpreter): Node =
  ## This code uses an array to avoid allocating a seq every time
  var args: array[1..20, Node]
  if self.infix:
    # If infix we use the last one
    args[1] = ni.last  
    # Pull remaining args to reach arity
    for i in 2 .. self.arity:
      args[i] = ni.evalNext()
  else:
    # Pull remaining args to reach arity
    for i in 1 .. self.arity:
      args[i] = ni.evalNext()
  result = self.prok(ni, args)

method eval(self: Funk, ni: Interpreter): Node =
  var args = newSeq[Node]() #array[1..20, Node]
  ## This code uses an array to avoid allocating a seq every time
  if self.arity > 0:
    if self.infix:
      # If infix we use the last one
      args.add(ni.last) # args[1] = ni.last  
      # Pull remaining args to reach arity
      for i in 2 .. self.arity:
        args.add(ni.evalNext()) #args[i] = ni.evalNext()
    else:
      # Pull remaining args to reach arity
      for i in 1 .. self.arity:
        args.add(ni.evalNext()) #args[i] = ni.evalNext()
  
  # Time to actually run the Funk
  ni.pushActivation(newActivation(self, args))
  while not ni.endOfNode:
    discard ni.evalNext()
  ni.popActivation()
  return ni.last

method eval(self: Paren, ni: Interpreter): Node =
  ni.pushActivation(newActivation(self))
  while not ni.endOfNode:
    discard ni.evalNext()
  ni.popActivation()
  return ni.last

method evalDo(self: Node, ni: Interpreter): Node =
  ni.pushActivation(newActivation(Blok(self)))
  while not ni.endOfNode:
    discard ni.evalNext()
  ni.popActivation()
  return ni.last
  
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
  ni.primDo(newParser().parse(code))

when isMainModule:
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  discard newInterpreter().eval(code)
