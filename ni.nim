# Ni Language
#
# Copyright (c) 2015 Göran Krampe


## TODO: Make infix work properly without parens by swapping?
## TODO: Make parens more lightweight, now they carry a Context etc etc
## TODO: Optimize away lots of book keeping to get a bit more speed

import strutils, sequtils, tables, nimprof

type
  # Ni interpreter
  Interpreter* = ref object
    last*: Node              # Remember for infix
    nextInfix*: bool         # Remember we are gobbling
    stack*: seq[Activation]  # Execution stack
    currentActivation*: Activation
    currentActivationLen*: int
    root*: Context           # Root bindings
    trueVal: Node
    falseVal: Node
    nilVal: Node

  RuntimeException* = object of Exception
  ParseException* = object of Exception

  # The parser builds a Node tree using a stack for nested blocks
  Parser* = ref object
    token: string                       # Collects the current token
    stack: seq[Node]                    # Lexical stack of Nodes
    valueParsers*: seq[ValueParser]     # Registered valueParsers

  # Base class for pluggable value parsers
  ValueParser* = ref object of RootObj
    token: string
  
  # Basic value parsers included by default
  IntValueParser = ref object of ValueParser
  StringValueParser = ref object of ValueParser
  FloatValueParser = ref object of ValueParser

  # We use an object variant for the parse Node in classic Araq style
  NodeKind* = enum niWord, niSetWord, niGetWord, niSymbolWord, niValue,
    niBlock, niParen, niCurly, niBinding, niSetBinding

  # Nodes form an AST which we later eval directly using Interpreter
  Node* = ref object of RootObj
    case kind*: NodeKind
    # The four word "formats" correspond to Rebol
    of niWord, niSetWord, niGetWord, niSymbolWord:
      word*:  string
    # A value node is some kind of "thing" :)
    of niValue:
      value*: Value
    # All these have child nodes
    # TODO: Curly is not yet explored
    of niBlock, niParen, niCurly:
      nodes*: seq[Node]
      closure*: Closure   # Optionally a local context
     # A flag so we resolve "only first time" when using bind
    of niBinding, niSetBinding:
      binding*: Binding # When resolving a niBinding replaces a niWord
      

  # The activation record used by Interpreter for evaluating blocks
  Activation = ref object
    node: Node             # The block we are evaluating
    pos: int               # Which node we are at


  # Contexts holds Bindings. This way we, when forming a closure we can lookup
  # a word to get the Binding and from then on simply set/get the val on the
  # Binding instead.
  Binding = ref object
    key: string
    val: Node

  # An "object" basically in Rebol terminology, named slots of Nodes.
  # Idea is to represent them in code using {name: "Göran" age: 46}
  # They are also used as our internal namespaces and so on.
  Context = ref object
    bindings: ref Table[string, Binding]

  # Values are also represented with an object variant, like Node
  ValueKind* = enum niInt, niFloat, niString, niBool, niNil,
    niContext, niProc, niClosure
  Value* = ref object
    case kind*: ValueKind
    of niInt:     intVal*: int64 # Seems reasonable for Ni
    of niFloat:   floatVal*: float64 # Same
    of niString:  stringVal*: string
    of niBool:    boolVal*: bool
    of niNil:     nil # No need for a value :)
    of niContext: contextVal*: Context
    of niProc:    procVal*: NimProc
    of niClosure: nodeVal*: Node
    
  # Base for behaviors, either primitives in Nim or Ni Closures
  Function = ref object of RootObj
    infix*: bool
    arity*: int
  
  # Signature for Nim primitives
  ProcType = proc(ni: Interpreter, a: varargs[Node]): Node
  # A wrapped Nim proc
  NimProc* = ref object of Function
    prok*: ProcType

  # Added to a block node when doing bind, so we can execute it as a function
  Closure* = ref object of Function
    context*: Context
    resolved*: bool

# Utilities I would like to have in stdlib
template isEmpty*[T](a: openArray[T]): bool =
  a.len == 0
template notEmpty*[T](a: openArray[T]): bool =
  a.len > 0
template notNil*[T](a:T): bool =
  not a.isNil
template debug*(x: untyped) =
  when false: echo(x)

# Extending Ni from other modules
type ParserExt = proc(p: Parser)
var parserExts = newSeq[ParserExt]()

proc addParserExtension*(prok: ParserExt) =
  parserExts.add(prok)

type InterpreterExt = proc(ni: Interpreter)
var interpreterExts = newSeq[InterpreterExt]()

proc addInterpreterExtension*(prok: InterpreterExt) =
  interpreterExts.add(prok)

# Forward declarations
proc bindBlock*(ni: Interpreter, node: Node): Node
proc funcBlock*(ni: Interpreter, node: Node): Node
proc evalBlock*(node: Node, ni: Interpreter): Node
proc resolve(self: Node, ni: Interpreter)
proc parse*(self: Parser, str: string): Node
proc eval*(self: Node, ni: Interpreter): Node
proc `$`*(self: Node): string

# String representations
proc `$`*(self: Binding): string =
  self.key & ":" & $self.val

proc `$`*(self: Context): string =
  result = "{"
  for k,v in self.bindings:
    result.add($v & " ")
  return result & "}"

proc `$`*(self: Value): string =
  case self.kind
  of niInt:
    $self.intVal
  of niFloat:
    $self.floatVal
  of niString:
    "\"" & self.stringVal & "\""
  of niBool:
    $self.boolVal
  of niNil:
    "nil"
  of niContext:
    $self.contextVal
  of niProc:
    "proc(" & $self.procVal.arity & ")"
  of niClosure:
    "closure(" & $self.nodeVal & ")"

proc `$`*(self: seq[Node]): string =
  self.map(proc(n: Node): string = $n).join(" ")


proc `$`*(self: Node): string =
  case self.kind
  of niWord:
    self.word
  of niSetWord:
    self.word & ":"
  of niGetWord:
    ":" & self.word
  of niSymbolWord:
    "'" & self.word
  of niValue:
    $self.value
  of niBlock:
    "[" & $self.nodes & "]"
  of niParen:
    "(" & $self.nodes & ")"
  of niCurly:
    "{" & $self.nodes & "}"
  of niBinding:
    "%" & $self.binding & "%"
  of niSetBinding:
    ":%" & $self.binding & "%"

# Nifties
template add(self: Node, n: Node) =
  self.nodes.add(n)

# Constructor procs
proc raiseRuntimeException*(msg: string) =
  raise newException(RuntimeException, msg)

proc raiseParseException*(msg: string) =
  raise newException(ParseException, msg)

proc newContext*(): Context =
  Context(bindings: newTable[string, Binding]())
  
proc newNimProc*(prok: ProcType, infix: bool, arity: int): NimProc =
  NimProc(prok: prok, infix: infix, arity: arity)

proc newClosure*(infix: bool, arity: int): Closure =
  Closure(infix: infix, arity: arity, context: newContext())

proc newWord*(s: string): Node =
  Node(kind: niWord, word: s)

proc newSetWord*(s: string): Node =
  Node(kind: niSetWord, word: s)

proc newGetWord*(s: string): Node =
  Node(kind: niGetWord, word: s)

proc newSymbolWord*(s: string): Node =
  Node(kind: niSymbolWord, word: s)

proc newBlock*(nodes: seq[Node]): Node =
  Node(kind: niBlock, nodes: nodes)
  
proc newBlock*(): Node =
  newBlock(newSeq[Node]())

proc newParen*(): Node =
  Node(kind: niParen, nodes: newSeq[Node]())

proc newCurly*(): Node =
  Node(kind: niCurly, nodes: newSeq[Node]())

proc newBinding*(b: Binding): Node =
  Node(kind: niBinding, binding: b)

proc newSetBinding*(b: Binding): Node =
  Node(kind: niSetBinding, binding: b)

proc newActivation*(node: Node): Activation =
  Activation(node: node)

proc newValue*(v: int64): Node =
  Node(kind: niValue, value: Value(kind: niInt, intVal: v))

proc newValue*(v: float64): Node =
  Node(kind: niValue, value: Value(kind: niFloat, floatVal: v))

proc newValue*(v: string): Node =
  Node(kind: niValue, value: Value(kind: niString, stringVal: v))

proc newValue*(v: bool): Node =
  Node(kind: niValue, value: Value(kind: niBool, boolVal: v))

proc newNilValue*(): Node =
  Node(kind: niValue, value: Value(kind: niNil))

proc newValue*(v: NimProc): Node =
  Node(kind: niValue, value: Value(kind: niProc, procVal: v))

proc newValue*(v: Node): Node =
  Node(kind: niValue, value: Value(kind: niClosure, nodeVal: v))

proc newValue*(v: Context): Node =
  Node(kind: niValue, value: Value(kind: niContext, contextVal: v))

proc newValue*(v: Value): Node =
  Node(kind: niValue, value: v)


proc newPrim*(prok: ProcType, infix: bool, arity: int): Node =
  newValue(NimProc(prok: prok, infix: infix, arity: arity))

# Context lookups
proc lookup*(self: Context, key: string): Binding =
  self.bindings[key]

proc bindit*(self: Context, key: string, val: Node): Binding =
  result = Binding(key: key, val: val)
  self.bindings[key] = result

# Methods for the base value parsers
method parseValue(self: ValueParser, s: string): Node {.procvar.} =
  nil

method parseValue(self: IntValueParser, s: string): Node {.procvar.} =
  try:
    return newValue(parseInt(s)) 
  except ValueError:
    return nil

method parseValue(self: FloatValueParser, s: string): Node {.procvar.} =
  try:
    return newValue(parseFloat(s)) 
  except ValueError:
    return nil

method parseValue(self: StringValueParser, s: string): Node {.procvar.} =
  # If it ends and starts with '"' then ok, no escapes yet
  if s.len > 1 and s[0] == '"' and s[^1] == '"':
    result = newValue(s[1..^2])

method prefixLength(self: ValueParser): int = 0

method tokenReady(self: ValueParser, token: string, ch: char): string =
  ## Return true if self wants to take over parsing a literal
  ## and deciding when its complete. This is used for delimited literals
  ## that can contain whitespace. Otherwise parseValue is needed.
  nil

method tokenStart(self: ValueParser, token: string, ch: char): bool =
  false

method prefixLength(self: StringValueParser): int = 1

method tokenStart(self: StringValueParser, token: string, ch: char): bool =
  ch == '"'

method tokenReady(self: StringValueParser, token: string, ch: char): string =
  # Minimally two '"' and the previous char was not '\'
  if ch == '"' and token[^1] != '\\':
    return token & ch
  else:
    return nil

proc newParser*(): Parser =
  ## Create a new Ni parser with the basic value parsers included
  result = Parser(stack: newSeq[Node](), valueParsers: newSeq[ValueParser]())
  result.valueParsers.add(StringValueParser())
  result.valueParsers.add(IntValueParser())
  result.valueParsers.add(FloatValueParser())
  # Call registered extension procs
  for ex in parserExts:
    ex(result)

# Converters
converter toNode(x: int64): Node =
  newValue(x)
converter toNode(x: float64): Node =
  newValue(x)
converter toNode(x: bool): Node =
  newValue(x)
converter toNode(x: string): Node =
  newValue(x)

converter toValue(x: float64): Value =
  result.kind = niFloat
  result.floatVal = x
converter toValue(x: string): Value =
  result.kind = niString
  result.stringVal = x

converter toString(x: Value): string =
  x.stringVal
converter toInt(x: Value): int64 =
  x.intVal
converter toFloat(x: Value): float64 =
  x.floatVal
converter toFloat(x: int64): float64 =
  x.float64

proc resolveBlock(ni: Interpreter, self: Node): Node =
  debug "RESOLVING" & $self
  self.resolve(ni)
  self.closure.resolved = true
  debug "RESOLVED: " & $self
  self

# Debugging
proc dump(c: Context): string =
  $c

proc dump(a: Activation): string =
  if a.node.closure.notNil:
    "CONTEXT:\n" & dump(a.node.closure.context)
  else:
    ".."
proc dump(ni: Interpreter): string =
  result = "ROOT:\n" & dump(ni.root) & "STACK:\n"
  for a in ni.stack:
    result.add(dump(a))


# Primitives written in Nim
proc primAdd(ni: Interpreter, a: varargs[Node]): Node =
  a[0].value.intVal + a[1].value.intVal
proc primSub(ni: Interpreter, a: varargs[Node]): Node =
  a[0].value.intVal - a[1].value.intVal
proc primMul(ni: Interpreter, a: varargs[Node]): Node =
  a[0].value.intVal * a[1].value.intVal
proc primDiv(ni: Interpreter, a: varargs[Node]): Node =
  a[0].value.intVal / a[1].value.intVal
proc primLt(ni: Interpreter, a: varargs[Node]): Node =
  a[0].value.intVal < a[1].value.intVal
proc primGt(ni: Interpreter, a: varargs[Node]): Node =
  a[0].value.intVal > a[1].value.intVal
proc primDo(ni: Interpreter, a: varargs[Node]): Node =
  ni.bindBlock(a[0]).evalBlock(ni)
proc primBind(ni: Interpreter, a: varargs[Node]): Node =
  ni.bindBlock(a[0])
proc primFunc(ni: Interpreter, a: varargs[Node]): Node =
  ni.funcBlock(a[0])
proc primResolve(ni: Interpreter, a: varargs[Node]): Node =
  ni.resolveBlock(a[0])
proc primParse(ni: Interpreter, a: varargs[Node]): Node =
  newParser().parse(a[0].value.stringVal)
proc primEcho(ni: Interpreter, a: varargs[Node]): Node =
  echo($a[0])
proc primIf(ni: Interpreter, a: varargs[Node]): Node =
  if a[0].value.boolVal: ni.primDo(a[1]) else: ni.nilVal
proc primIfelse(ni: Interpreter, a: varargs[Node]): Node =
  if a[0].value.boolVal: ni.primDo(a[1]) else: ni.primDo(a[2])
proc primLoop(ni: Interpreter, a: varargs[Node]): Node =
  for i in 1 .. a[0].value.intVal:
    result = ni.primDo(a[1])
proc primDump(ni: Interpreter, a: varargs[Node]): Node =
  ni.dump

proc newInterpreter*(): Interpreter =
  result = Interpreter(stack: newSeq[Activation](), root: newContext())
  # Singletons
  result.trueVal = newValue(true)
  result.falseVal = newValue(false)
  result.nilVal = newNilValue()
  let root = result.root
  discard root.bindit("false", result.falseVal)
  discard root.bindit("true", newValue(true))
  discard root.bindit("nil", newNilValue())  
  # Primitives in Nim
  discard root.bindit("+", newPrim(primAdd, true, 2))
  discard root.bindit("-", newPrim(primSub, true, 2))
  discard root.bindit("*", newPrim(primMul, true, 2))
  discard root.bindit("/", newPrim(primDiv, true, 2))
  discard root.bindit("<", newPrim(primLt, true, 2))
  discard root.bindit(">", newPrim(primGt, true, 2))
  discard root.bindit("bind", newPrim(primBind, false, 1))
  discard root.bindit("func", newPrim(primFunc, false, 1))
  discard root.bindit("resolve", newPrim(primResolve, false, 1))
  discard root.bindit("do", newPrim(primDo, false, 1))
  discard root.bindit("parse", newPrim(primParse, false, 1))
  discard root.bindit("echo", newPrim(primEcho, false, 1))
  discard root.bindit("if", newPrim(primIf, false, 2))
  discard root.bindit("ifelse", newPrim(primIfelse, false, 3))
  discard root.bindit("loop", newPrim(primLoop, false, 2))
  discard root.bindit("dump", newPrim(primDump, false, 1))
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
    if result.notNil: debug("FOUND " & key & " IN ROOT: " & $result) 
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
    debug("BIND IN ROOT: " & $key & ": " & $val)
    ni.root.bindit(key, val)

template `[]`(self: Node, i: int): Node =
  ## We allow indexing of Nodes if they are of the composite kind.
  case self.kind
  of niBlock, niParen, niCurly:
    self.nodes[i]
  else:
    nil

template len(self: Node): int =
  ## Return number of child nodes
  case self.kind
  of niBlock, niParen, niCurly:
    self.nodes.len
  else:
    0

proc infix(self: Node): bool =
  ## True for infix Functions
  case self.kind
  of niValue:
    case self.value.kind
    of niProc:
      return self.value.procVal.infix
    of niClosure:
      return self.value.nodeVal.infix
    else:
      return false
  of niBinding:
    return self.binding.val.infix
  else:
    return false

template len(self: Activation): int =
  self.node.len

template endOfNode*(ni: Interpreter): bool =
  ni.currentActivation.pos == ni.currentActivationLen

proc pushActivation*(ni: Interpreter, activation: Activation) =
  ni.currentActivation = activation
  ni.currentActivationLen = activation.len
  ni.stack.add(activation)

proc popActivation*(ni: Interpreter) =
  discard ni.stack.pop
  if ni.stack.notEmpty:
    ni.currentActivation = ni.top
    ni.currentActivationLen = ni.currentActivation.len
  else:
    ni.currentActivationLen = 0

proc next*(ni: Interpreter): Node =
  ## Get next node in the current block Activation.
  if ni.endOfNode:
    raiseRuntimeException("End of current block, too few arguments")
  else:
    result = ni.currentActivation.node[ni.currentActivation.pos]
    inc(ni.currentActivation.pos)

proc peek*(ni: Interpreter): Node =
  ## Peek next node in the current block Activation.
  ni.currentActivation.node[ni.currentActivation.pos]

template isNextInfix(ni: Interpreter): bool =
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

proc evalNimProc(self: NimProc, ni: Interpreter): Node =
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
  return self.prok(ni, args)

proc resolve(self: Node, ni: Interpreter) =
  ## Go through tree and do lookups of words, replacing with the binding.
  case self.kind
  of niBlock, niParen, niCurly:
    for pos,child in mpairs(self.nodes):
      case child.kind
      of niBlock, niParen, niCurly:
        child.resolve(ni) # Recurse
      of niWord:
        let hit = ni.lookup(child.word)
        if hit.notNil:
          self.nodes[pos] = newBinding(hit)
      of niSetWord:
        let hit = ni.lookup(child.word)
        if hit.notNil:
          self.nodes[pos] = newSetBinding(hit)
      else:
        discard
  else:
    raiseRuntimeException("Can only resolve composite nodes, not: " & $self)

proc bindBlock(ni: Interpreter, node: Node): Node =
  case node.kind
  of niBlock:
    if node.closure.isNil:
      node.closure = newClosure(false, 0)
    if not node.closure.resolved:
      discard ni.resolveBlock(node)
    # TODO infix/arity
    return node
  else:
    raiseRuntimeException("Can only bind blocks, not: " & $node)

proc funcBlock(ni: Interpreter, node: Node): Node =
  case node.kind
  of niBlock:
    return newValue(ni.bindBlock(node))
  else:
    raiseRuntimeException("Can only create functions from blocks, not: " & $node)

proc evalBlock*(node: Node, ni: Interpreter): Node =
  debug("EVALBLOCK")
  ## Let the interpreter eval Block and return the result as a Node.
  ni.pushActivation(newActivation(node))
  while not ni.endOfNode:
    discard ni.evalNext()
  # TODO: Somewhere here we need to handle arity and infix peeking like
  # in evalNimProc
  ni.popActivation()
  result = ni.last
  debug("POPRESULT: " & $result)


proc eval(self: Node, ni: Interpreter): Node =
  ## This is the heart dispatcher of the Interpreter
  case self.kind
  of niWord:
    let binding = ni.lookup(self.word)
    if binding.isNil:
      raiseRuntimeException("Word not found: " & self.word)
    return binding.val.eval(ni)
  of niSetWord:
    debug("SETW:" & self.word)
    return ni.bindit(self.word, ni.evalNext()).val
  of niGetWord:
    return ni.lookup(self.word).val
  of niSymbolWord:
    return self
  of niValue:
    return case self.value.kind
    of niProc:
      # NimProcs evaluate themselves
      self.value.procVal.evalNimProc(ni)
    of niClosure:
      # As do Closures
      self.value.nodeVal.evalBlock(ni)
    else:
      # But other values do not
      self
  of niBlock:
    # Blocks don't evaluate on their own, must use primDo
    return self
  of niParen:
    # Parens evaluate though
    return self.evalBlock(ni)
  of niCurly:
    return self # TODO: Produce a Context I think...
  of niBinding:
    # Eval of a niBinding is like a static fast niWord
    return self.binding.val.eval(ni)
  of niSetBinding:
    # Eval of a niSetBinding is like a static fast niSetWord
    result = ni.evalNext()
    self.binding.val = result

proc newWordOrValue(self: Parser): Node =
  ## Decide what to make, a word or value
  let token = self.token
  self.token = ""
  
  # Try all valueParsers...
  for p in self.valueParsers:
    let valueOrNil = p.parseValue(token)
    if valueOrNil.notNil:
      return valueOrNil

  # Then it must be a word
  if token[0] == ':':
    return newGetWord(token[1..^1])
  if token[^1] == ':':
    return newSetWord(token[0..^2])
  if token[0] == '\'':
    return newSymbolWord(token[1..^1])
  return newWord(token)

template top(self: Parser): Node =
  self.stack[self.stack.high]

template pop(self: Parser) =
  discard self.stack.pop()

proc push(self: Parser, n: Node) =
  if not self.stack.isEmpty:
    self.top.add(n)
  self.stack.add(n)

proc addNode(self: Parser) =
  if self.token.len > 0:
    self.top.add(self.newWordOrValue())
    self.token = ""

proc parse*(self: Parser, str: string): Node =
  var ch: char
  var currentValueParser: ValueParser
  var pos = 0
  self.stack = @[]
  self.token = ""
  # Wrap code in a block, well, ok... then we can just call primDo on it.
  self.push(newBlock())
  # Parsing is done in a single pass char by char, recursive descent
  while pos < str.len:
    ch = str[pos]
    inc pos
    # If we are inside a literal value let the valueParser decide when complete
    if currentValueParser.notNil:
      let found = currentValueParser.tokenReady(self.token, ch)
      if found.notNil:
        self.token = found
        self.addNode()
        currentValueParser = nil
      else:
        self.token.add(ch)
    else:
      # If we are not parsing a literal with a valueParser whitespace is consumed
      if currentValueParser.isNil and ch in Whitespace:
        # But first we make sure to finish the token if any
        self.addNode()
      else:
        # Check if a valueParser wants to take over, only 5 first chars are checked
        let tokenLen = self.token.len + 1
        if currentValueParser.isNil and tokenLen < 5:
          for p in self.valueParsers:
            if p.prefixLength == tokenLen and p.tokenStart(self.token, ch):
              currentValueParser = p
              break
        # If still no valueParser active we do regular token handling
        if currentValueParser.isNil:
          case ch
          # Comments are not included in the AST
          of '#':
            self.addNode()
            while not (str[pos] == '\l'):
              inc pos
          # Paren
          of '(':
            self.addNode()
            self.push(newParen())
          # Block
          of '[':
            self.addNode()
            self.push(newBlock())
          # Curly
          of '{':
            self.addNode()
            self.push(newCurly())
          of ')':
            self.addNode()
            self.pop
          # Block
          of ']':
            self.addNode()
            self.pop
          # Curly
          of '}':
            self.addNode()
            self.pop
          # Ok, otherwise we just collect the char
          else:
            self.token.add(ch)
        else:
          self.token.add(ch)
  self.addNode()
  self.top

proc eval*(ni: Interpreter, code: string): Node =
  ni.primDo(newParser().parse(code))


when isMainModule:
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  discard newInterpreter().eval(code)
