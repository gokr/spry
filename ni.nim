# Ni Language
#
# Copyright (c) 2015 Göran Krampe
#
## This is a parser & interpreter for the Ni language, inspired by Rebol.
## Ni is meant to mix with Nim and not as a Rebol compatible language.
## However, most of the language follows Rebol ideas.
##
## The Parser parses strings into a tree of Nodes (AST).
## The Interpreter is stack based and executes the Nodes directly.
## Datatypes are pluggable instances of ValueParser so its very easy to add
## more literal types.

import strutils, sequtils, types, tables

type
  # Ni interpreter
  Interpreter* = ref object
    stack: seq[Node] # Stack of execution
    env: Env # Bindings of strings to Nodes

  RuntimeException* = object of Exception
  ParseException* = object of Exception

  # To keep track of bindings, outer is not yet used
  Env* = ref object
    bindings*: ref Table[string, Node]
    #outer*: Env

  # So we can plug (what Rebol calls "datatype") parser procs dynamically
  #ValueParserProc* = proc(s:string): Node

  # The parser builds a Node tree using a stack for nested blocks
  Parser* = ref object
    token: string                       # Collects the current token
    stack: seq[Node]                    # Lexical stack of Nodes
    valueParsers*: seq[ValueParser]     # Registered valueParsers

  # Base class for pluggable value parsers
  ValueParser = ref object
    token: string
  
  # Basic value parsers
  IntValueParser = ref object of ValueParser
  StringValueParser = ref object of ValueParser
  BoolValueParser = ref object of ValueParser

  # We use an object variant for the parse Node, see comments below
  NodeKind* = enum niWord, niSetWord, niGetWord, niSymbolWord, niValue,
    niBlock, niParen, niCurly, niFun, niActivation

  # Nodes form an AST which we execute directly using Interpreter
  Node* = ref object of RootObj
    case kind*: NodeKind
    #of Nil, True, False: nil
    # The four word "formats" correspond to Rebol
    of niWord, niSetWord, niGetWord, niSymbolWord:  word*:  string
    # A value node is a "datatype" or in other terminology - a literal
    of niValue:                                     value*: Value
    # A Fun is an primitive executable function and a niFun Node wraps it
    of niFun:                                       fun*:   Fun
    # All these have child nodes
    of niBlock, niParen, niCurly:                   nodes*: seq[Node]
    of niActivation:                                activation*: Activation

  # The activation record used by Interpreter for executing blocks
  Activation = ref object
    node: Node    # The block node we are executing
    pos: int      # Which node we are at executing this block
    env: Env      # Local variables and parameters in block TODO

  # Values are also represented with an object variant
  ValueKind* = enum niInt, niString, niBool
  Value* = ref object
    case kind*: ValueKind
    of niInt:    intVal*: int64
    of niString: stringVal*: string
    of niBool:   boolVal*: bool
    
  # A Nim proc wrapped with arity and env, so we can bind it to words
  FunType = proc(ni: Interpreter, a: varargs[Node]): Node
  Fun* = ref object
    fn*:       FunType
    arity*:    int
    env*:      Env

# Utilities I would like to have in stdlib
template isEmpty[T](a: openArray[T]): bool =
  a.len == 0
template notNil[T](a:T): bool =
  not a.isNil

# Forward declarations
proc doBlock*(ni: Interpreter, node: Node): Node
proc parse*(self: Parser, str: string): Node
proc eval*(self: Node, ni: Interpreter): Node
proc `$`*(self: Node): string

# String representations
proc `$`*(self: Value): string =
  case self.kind
  of niInt:
    $self.intVal
  of niString:
    "\"" & self.stringVal & "\""
  of niBool:
    $self.boolVal

proc `$`*(self: seq[Node]): string =
  self.map(proc(n: Node): string = $n).join(" ")

proc `$`*(self: Node): string =
  case self.kind
  of niWord:
    result = self.word
  of niSetWord:
    result = self.word & ":"
  of niGetWord:
    result = ":" & self.word
  of niSymbolWord:
    result = "'" & self.word
  of niValue:
    result = $self.value
  of niBlock:
    result = "[" & $self.nodes & "]"
  of niParen:
    result = "(" & $self.nodes & ")"
  of niCurly:
    result = "{" & $self.nodes & "}"
  of niFun:
    result = "FUNARITY(" & $self.fun.arity & ")"
  of niActivation:
    result = "ACTIVATION(" & $self.activation.node & ")"

# Constructor procs
proc raiseRuntimeException(msg: string) =
  raise newException(RuntimeException, msg)

proc raiseParseException(msg: string) =
  raise newException(ParseException, msg)

proc newFun(fn: FunType, arity: int): Fun =
  Fun(fn: fn, arity: arity)

proc newFunNode(f: Fun): Node =
  Node(kind: niFun, fun: f)

proc newWord(s: string): Node =
  Node(kind: niWord, word: s)

proc newSetWord(s: string): Node =
  Node(kind: niSetWord, word: s)

proc newGetWord(s: string): Node =
  Node(kind: niGetWord, word: s)

proc newSymbolWord(s: string): Node =
  Node(kind: niSymbolWord, word: s)

proc newBlock(): Node =
  Node(kind: niBlock, nodes: newSeq[Node]())

proc newParen(): Node =
  Node(kind: niParen, nodes: newSeq[Node]())

proc newCurly(): Node =
  Node(kind: niCurly, nodes: newSeq[Node]())

proc newEnv(): Env =
  result = Env(bindings: newTable[string, Node]())

proc newActivation(node: Node): Node =
  Node(kind: niActivation, activation: Activation(node: node))

proc newValue(v: int64): Node =
  Node(kind: niValue, value: Value(kind: niInt, intVal: v))

proc newValue(v: string): Node =
  Node(kind: niValue, value: Value(kind: niString, stringVal: v))

proc newValue(v: bool): Node =
  Node(kind: niValue, value: Value(kind: niBool, boolVal: v))
  
# Env lookups
proc lookup(self: Env, key: string): Node =
  self.bindings[key]

proc bindit(self: Env, key: string, val: Node): Node =
  self.bindings[key] = val
  result = val

# Methods for the base value parsers
method parseValue(self: ValueParser, s: string): Node {.procvar.} =
  nil

method parseValue(self: IntValueParser, s: string): Node {.procvar.} =
  try:
    return newValue(parseInt(s)) 
  except ValueError:
    return nil

method parseValue(self: StringValueParser, s: string): Node {.procvar.} =
  # If it ends and starts with '"' then ok, no escapes yet
  if s[0] == '"' and s[^1] == '"':
    result = newValue(s[1..^2])

method parseValue(self: BoolValueParser, s: string): Node {.procvar.} =
  # true or false
  if s == "true":
    result = newValue(true) # TODO: Use singleton values
  elif s == "false":
    result = newValue(false)

method startValue(self: ValueParser, ch: char): bool =
  ## Return true if self wants to take over parsing a literal
  ## and deciding when its complete. This is used for delimited literals
  ## that can contain whitespace. Otherwise its not needed.
  false

method startValue(self: StringValueParser, ch: char): bool =
  ch == '"'

method endValue(self: ValueParser, ch: char): bool =
  false

method endValue(self: StringValueParser, ch: char): bool =
  ch == '"'


method includeLast(self: ValueParser): bool =
  ## Should the literal include the last character?
  false

method includeLast(self: StringValueParser): bool =
  true

proc newParser*(): Parser =
  ## Create a new Ni parser with the basic value parsers included
  result = Parser(stack: newSeq[Node](), valueParsers: newSeq[ValueParser]())
  result.valueParsers.add(StringValueParser())
  result.valueParsers.add(IntValueParser())
  result.valueParsers.add(BoolValueParser())

# Primitives written in Nim
proc primAdd(ni: Interpreter, a: varargs[Node]): Node =
  newValue(a[0].value.intVal + a[1].value.intVal)
proc primSub(ni: Interpreter, a: varargs[Node]): Node =
  newValue(a[0].value.intVal - a[1].value.intVal)
proc primMul(ni: Interpreter, a: varargs[Node]): Node =
  newValue(a[0].value.intVal * a[1].value.intVal)
#proc primDiv(ni: Interpreter, a: varargs[Node]): Node =
#  newValue(a[0].value.intVal / a[1].value.intVal)
proc primLt(ni: Interpreter, a: varargs[Node]): Node =
  newValue(a[0].value.intVal < a[1].value.intVal)
proc primGt(ni: Interpreter, a: varargs[Node]): Node =
  newValue(a[0].value.intVal > a[1].value.intVal)
proc primDo(ni: Interpreter, a: varargs[Node]): Node =
  ni.doBlock(a[0])
proc primParse(ni: Interpreter, a: varargs[Node]): Node =
  result = newParser().parse(a[0].value.stringVal)
proc primEcho(ni: Interpreter, a: varargs[Node]): Node =
  echo($a[0])
proc primIf(ni: Interpreter, a: varargs[Node]): Node =
  if a[0].value.boolVal: ni.doBlock(a[1]) else: a[0] # Eh... nil
proc primIfelse(ni: Interpreter, a: varargs[Node]): Node =
  if a[0].value.boolVal: ni.doBlock(a[1]) else: ni.doBlock(a[2])
proc primLoop(ni: Interpreter, a: varargs[Node]): Node =
  for i in 0 .. a[0].value.intVal:
    result = ni.doBlock(a[1])

proc newRootEnv(): Env =
  result = newEnv()
  # Here we bind words to primitives in Nim
  discard result.bindit("add", newFunNode(newFun(primAdd, 2)))
  discard result.bindit("sub", newFunNode(newFun(primSub, 2)))
  discard result.bindit("mul", newFunNode(newFun(primMul, 2)))
#  discard result.bindit("div", newFunNode(newFun(primDiv, 2)))
  discard result.bindit("lt", newFunNode(newFun(primLt, 2)))
  discard result.bindit("gt", newFunNode(newFun(primGt, 2)))
  discard result.bindit("do", newFunNode(newFun(primDo, 1)))
  discard result.bindit("parse", newFunNode(newFun(primParse, 1)))
  discard result.bindit("echo", newFunNode(newFun(primEcho, 1)))
  discard result.bindit("if", newFunNode(newFun(primIf, 2)))
  discard result.bindit("ifelse", newFunNode(newFun(primIfelse, 3)))
  discard result.bindit("loop", newFunNode(newFun(primLoop, 2)))

proc newInterpreter*(): Interpreter =
  Interpreter(stack: newSeq[Node](), env: newRootEnv())

proc top(ni: Interpreter): Node =
  ## The current block Node being evaluated
  ni.stack[ni.stack.high]

proc `[]`(self: Node, i: int): Node =
  ## We allow indexing of Nodes if they are of the composite kind.
  case self.kind
  of niWord, niSetWord, niGetWord, niSymbolWord, niValue, niFun, niActivation:
    result = nil
  of niBlock, niParen, niCurly:
    result = self.nodes[i]

proc len(self: Node): int =
  ## Return number of child nodes
  case self.kind
  of niWord, niSetWord, niGetWord, niSymbolWord, niValue, niFun, niActivation:
    result = 0
  of niBlock, niParen, niCurly:
    result = self.nodes.len

proc endOfBlock(ni: Interpreter): bool =
  let node = ni.top
  case node.kind
  of niActivation:
    let activation = node.activation
    #echo "POS:" & $activation.pos & " LEN:" & $activation.node.len
    if activation.pos == activation.node.len:
      result = true
  else:
    result = false

proc next(ni: Interpreter): Node =
  ## Move to next node in the current block Activation.
  let node = ni.top
  case node.kind
  of niActivation:
    var activation = node.activation
    if activation.pos == activation.node.len:
      raiseRuntimeException("End of current block, too few arguments")
    else:
      result = activation.node[activation.pos]
      inc activation.pos
  else:
    raiseRuntimeException("Evaluation error, top of stack not a block activation")    
      
proc evalNext(ni: Interpreter): Node =
  ## Evaluate the next node in the current block
  ni.next.eval(ni)

proc eval(fun: Fun, ni: Interpreter): Node =
  # Pull the number of args from interpreter
  var args: seq[Node] = @[]
  for i in 1..fun.arity:
    args.add(ni.evalNext())
  #echo "ARGS: " & $args
  fun.fn(ni, args)

proc eval(self: Node, ni: Interpreter): Node =
  case self.kind
  of niWord:
    #echo "LOOKUP:" & self.word
    result = ni.env.lookup(self.word).eval(ni)
  of niSetWord:
    #echo "SET:" & self.word
    result = ni.env.bindit(self.word, ni.evalNext())
  of niGetWord:
    #echo "GET:" & self.word
    result = ni.env.lookup(self.word)
  of niSymbolWord:
    result = self
  of niValue:
    result = self
  of niBlock:
    result = self
  of niParen:
    result = self
  of niCurly:
    result = self
  of niFun:
    result = self.fun.eval(ni)
  of niActivation:
    result = self #??

proc doBlock*(ni: Interpreter, node: Node): Node =
  ## Let the interpreter do a given Block and return the result as a Node.
  #echo "DOBLOCK:" & $node
  ni.stack.add(newActivation(node))
  while not ni.endOfBlock:
    result = ni.evalNext()
  discard ni.stack.pop
  #echo "RES:" & $result

proc add(self: Node, n: Node) =
  self.nodes.add(n)

proc newWordOrValue(self: Parser): Node =
  ## Decide what to make, a word or value
  let token = self.token
  self.token = ""
  
  # Try values here...
  for p in self.valueParsers:
    let valueOrNil = p.parseValue(token)
    if valueOrNil.notNil:
      return valueOrNil

  # Then words
  if token[0] == ':':
    return newGetWord(token[1..^1])
  if token[^1] == ':':
    return newSetWord(token[0..^2])
  if token[0] == '\'':
    return newSymbolWord(token[1..^1])
  return newWord(token)

proc top(self: Parser): Node =
  self.stack[self.stack.high]

proc pop(self: Parser) =
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
  # Wrap code in a block, well, ok
  self.push(newBlock())
  # Parsing is done in a single pass char by char, recursive descent
  while pos < str.len:
    ch = str[pos]
    inc pos
    # If we are inside a literal value let the valueParser decide when complete
    if currentValueParser.notNil and currentValueParser.endValue(ch):
      if currentValueParser.includeLast:
        self.token.add(ch)
      self.addNode()
      currentValueParser = nil
    else:
      # If we are not parsing a literal with a valueParser whitespace is consumed
      if currentValueParser.isNil and ch in Whitespace:
        # But first we make sure to finish the token if any
        self.addNode()
      else:
        # Check if a valueParser wants to take over
        if currentValueParser.isNil and self.token.len == 0:
          for p in self.valueParsers:
            if p.startValue(ch):
              currentValueParser = p
              break
        # Otherwise we do regular token handling
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
  result = self.top

proc eval*(ni: Interpreter, code: string): Node =
  ## Evaluating is simply parsing string and then call doBlock
  ni.doBlock(newParser().parse(code))


when isMainModule:
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  discard newInterpreter().eval(code)
