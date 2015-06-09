# Ni Language
#
# Copyright (c) 2015 Göran Krampe

## TODO: Improve Funk to take a spec argument for args etc

import strutils, sequtils, tables, nimprof
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
  GetBinding* = ref object of Node
    binding*: Binding
  SetBinding* = ref object of Node
    binding*: Binding
  
  # Base type for functions in Nim or Ni
  Function = ref object of Node
    infix*: bool
    arity*: int  
    
  # Node type to hold Nim primitive procs
  ProcType* = proc(ni: Interpreter, a: varargs[Node]): Node
  NimProc* = ref object of Function
    prok*: ProcType
    
  # An executable Ni function
  Funk* = ref object of Function
    blok*: Blok      # Body of this Func
    spec*: Blok      # The spec of this Func
    context*: Context #? 

  # The activation record used by Interpreter for evaluating Block/Paren.
  # This is a so called Spaghetti Stack with only a parent pointer.
  Activation* = ref object of RootObj
    parent: Activation
    pos: int          # Which node we are at
    comp: Composite

# Extending Ni from other modules
type InterpreterExt = proc(ni: Interpreter)
var interpreterExts = newSeq[InterpreterExt]()

proc addInterpreterExtension*(prok: InterpreterExt) =
  interpreterExts.add(prok)

# Forward declarations
proc compile*(ni: Interpreter, self: Blok): Node
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
    return result & "(" & $self.arity & ")" & "[" & $self.blok.nodes & "]"
  else:
    return "[" & $self.blok.nodes & "]"

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

# Constructor procs
proc raiseRuntimeException*(msg: string) =
  raise newException(RuntimeException, msg)

proc newNimProc*(prok: ProcType, infix: bool, arity: int): NimProc =
  NimProc(prok: prok, infix: infix, arity: arity)

proc newFunk*(blok: Blok, infix: bool, arity: int): Funk =
  Funk(blok: blok, infix: infix, arity: arity, context: newContext())

proc newGetBinding*(b: Binding): GetBinding =
  GetBinding(binding: b)

proc newSetBinding*(b: Binding): SetBinding =
  SetBinding(binding: b)

proc newActivation*(funk: Funk): Activation =
  Activation(comp: funk.blok)

proc newActivation*(comp: Composite): Activation =
  Activation(comp: comp)

method resolveComposite*(ni: Interpreter, self: Composite): Node =
  if not self.resolved:
    discard self.resolveComposite(ni)
    self.resolved = true
  return self

# Stack iterator
iterator stack(ni: Interpreter): Activation =
  var activation = ni.currentActivation
  while activation.notNil:
    yield activation
    activation = activation.parent

# Debugging
proc dump(c: Context): string =
  $c

proc dump(self: Node): string =
  echo($self)

proc dump(self: Activation): string =
  echo "POS: " & $self.pos

proc dump(ni: Interpreter): string =
  result = "ROOT:\n" & dump(ni.root) & "STACK:\n"
  for a in ni.stack:
    result.add(dump(a))


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

proc primDo(ni: Interpreter, a: varargs[Node]): Node =
  ni.resolveComposite(Composite(a[0])).evalDo(ni)

proc primFunk(ni: Interpreter, a: varargs[Node]): Node =
  ni.compile(Blok(a[0]))
  
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
  newValue(ni.dump)

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
  discard root.bindit("+", newNimProc(primAdd, true, 2))
  discard root.bindit("-", newNimProc(primSub, true, 2))
  discard root.bindit("*", newNimProc(primMul, true, 2))
  discard root.bindit("/", newNimProc(primDiv, true, 2))
  discard root.bindit("<", newNimProc(primLt, true, 2))
  discard root.bindit(">", newNimProc(primGt, true, 2))
  #discard root.bindit("bind", newNimProc(primBind, false, 1))
  discard root.bindit("func", newNimProc(primFunk, false, 1))
  discard root.bindit("resolve", newNimProc(primResolve, false, 1))
  discard root.bindit("do", newNimProc(primDo, false, 1))
  discard root.bindit("parse", newNimProc(primParse, false, 1))
  discard root.bindit("echo", newNimProc(primEcho, false, 1))
  discard root.bindit("if", newNimProc(primIf, false, 2))
  discard root.bindit("ifelse", newNimProc(primIfelse, false, 3))
  discard root.bindit("loop", newNimProc(primLoop, false, 2))
  discard root.bindit("dump", newNimProc(primDump, false, 1))
  # Call registered extension procs
  for ex in interpreterExts:
    ex(result)

template top*(ni: Interpreter): Activation =
  ni.stack[^1]

proc lookup(ni: Interpreter, key: string): Binding =
#  if ni.stack.notEmpty and ni.top.context.notNil:
#    result = ni.top.context.lookup(key)
  if result.isNil:
    result = ni.root.lookup(key)
    #if result.notNil: debug("FOUND " & key & " IN ROOT: " & $result) 
#  else:
#    debug("FOUND " & key & " IN CONTEXT: " & $result)

proc bindit(ni: Interpreter, key: string, val: Node): Binding =
# TODO: Need a way to distinguish between where to bind... so only root for now
#  if ni.stack.notEmpty:
#    if ni.top.context.isNil:
#      ni.top.context = newContext()
#    debug("BIND IN CONTEXT: " & $key & ": " & $val)
#    ni.top.context.bindit(key, val)
#  else:
    #debug("BIND IN ROOT: " & $key & ": " & $val)
    ni.root.bindit(key, val)

method infix(self: Node): bool =
  false

method infix(self: Function): bool =
  self.infix

method infix(self: GetBinding): bool =
  self.binding.val.infix


proc `[]`(self: Composite, i: int): Node =
  self.nodes[i]

proc `[]`(self: Activation, i: int): Node =
  self.comp.nodes[i]

proc len(self: Activation): int =
  self.comp.nodes.len

proc endOfNode*(ni: Interpreter): bool {.inline.} =
  ni.currentActivation.pos == ni.currentActivationLen

proc pushActivation*(ni: Interpreter, activation: Activation)  {.inline.} =
  activation.parent = ni.currentActivation
  ni.currentActivation = activation
  ni.currentActivationLen = activation.len

proc popActivation*(ni: Interpreter)  {.inline.} =
  ni.currentActivation = ni.currentActivation.parent
  if ni.currentActivation.notNil:
    ni.currentActivationLen = ni.currentActivation.len
  else:
    ni.currentActivationLen = 0

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
  ## Base case, we only resolve Word and SetWord
  nil

method resolve(self: Word, ni: Interpreter): Node =
  let hit = ni.lookup(self.word)
  if hit.notNil:
    return newGetBinding(hit)

method resolve(self: SetWord, ni: Interpreter): Node =
  let hit = ni.lookup(self.word)
  if hit.notNil:
    return newSetBinding(hit)

method resolveComposite(self: Composite, ni: Interpreter): Node =
  ## Go through tree and do lookups of words, replacing with the binding.
  for pos,child in mpairs(self.nodes):
    let binding = child.resolve(ni) # Recurse
    if binding.notNil:
      self.nodes[pos] = binding
  return nil

proc compile*(ni: Interpreter, self: Blok): Node =
  result = newFunk(self, false, 0)   # TODO infix/arity
  discard ni.resolveComposite(self)

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
  ## Just self
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
  ni.pushActivation(newActivation(self))
  while not ni.endOfNode:
    discard ni.evalNext()
  # TODO: Somewhere here we need to handle arity and infix peeking like
  # in evalNimProc
  ni.popActivation()
  return ni.last

method eval(self: Paren, ni: Interpreter): Node =
  ni.pushActivation(newActivation(self))
  while not ni.endOfNode:
    discard ni.evalNext()
  ni.popActivation()
  return ni.last

method evalDo(self: Node, ni: Interpreter): Node =
  ni.pushActivation(newActivation(Composite(self)))
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
