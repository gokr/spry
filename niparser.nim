# Ni Language, Parser
#
# Copyright (c) 2015 Göran Krampe

import strutils, sequtils, tables, nimprof

type
  ParseException* = object of Exception

  # The recursive descent parser builds a Node tree using a stack for nested blocks
  Parser* = ref object
    token: string                       # Collects characters into a token
    stack: seq[Node]                    # Lexical stack of block Nodes
    valueParsers*: seq[ValueParser]     # Registered valueParsers for literals

  # Base class for pluggable value parsers
  ValueParser* = ref object of RootObj
    token: string
  
  # Basic value parsers included by default, true false and nil are instead
  # regular system words referring to singleton values
  IntValueParser = ref object of ValueParser
  StringValueParser = ref object of ValueParser
  FloatValueParser = ref object of ValueParser

  # Nodes form an AST which we later eval directly using Interpreter
  Node* = ref object of RootObj
  Word* = ref object of Node
    word*: string    
  EvalWord* = ref object of Word
  SetWord* = ref object of Word
  GetWord* = ref object of Word
  LitWord* = ref object of Word
  
  Value* = ref object of Node
  IntVal* = ref object of Value
    value*: int
  FloatVal* = ref object of Value
    value*: float
  StringVal* = ref object of Value
    value*: string
  BoolVal* = ref object of Value
    value*: bool
  NilVal* = ref object of Value

  Composite* = ref object of Node
    nodes*: seq[Node]
    resolved*: bool
  Paren* = ref object of Composite
  Blok* = ref object of Composite
  Curly* = ref object of Composite
  
  # An "object" in Rebol terminology, named slots of Nodes.
  # They are also used as our internal namespaces and so on.
  Context* = ref object of Node
    bindings*: ref Table[string, Binding]  

  # Contexts holds Bindings. This way we, when forming a closure we can lookup
  # a word to get the Binding and from then on simply set/get the val on the
  # Binding instead.
  Binding* = ref object
    key*: string
    val*: Node


# Utilities I would like to have in stdlib
template isEmpty*[T](a: openArray[T]): bool =
  a.len == 0
template notEmpty*[T](a: openArray[T]): bool =
  a.len > 0
template notNil*[T](a:T): bool =
  not a.isNil
template debug*(x: untyped) =
  when true: echo(x)

# Extending the Parser from other modules
type ParserExt = proc(p: Parser)
var parserExts = newSeq[ParserExt]()

proc addParserExtension*(prok: ParserExt) =
  parserExts.add(prok)

# String representations
method `$`*(self: Node): string =
  echo repr(self)

method `$`*(self: Binding): string =
  self.key & ":" & $self.val

method `$`*(self: Context): string =
  result = "{"
  for k,v in self.bindings:
    result.add($v & " ")
  return result & "}"

method `$`*(self: IntVal): string =
  $self.value

method `$`*(self: FloatVal): string =
  $self.value

method `$`*(self: StringVal): string =
  "\"" & self.value & "\""

method `$`*(self: BoolVal): string =
  $self.value

method `$`*(self: NilVal): string =
  "nil"

proc `$`*(self: seq[Node]): string =
  self.map(proc(n: Node): string = $n).join(" ")

method `$`*(self: Word): string =
  self.word

method `$`*(self: SetWord): string =
  self.word & ":"

method `$`*(self: GetWord): string =
  ":" & self.word

method `$`*(self: LitWord): string =
  "'" & self.word

method `$`*(self: Blok): string =
  "[" & $self.nodes & "]"

method `$`*(self: Paren): string =
  "(" & $self.nodes & ")"

method `$`*(self: Curly): string =
  "{" & $self.nodes & "}"

# AST manipulation
proc add*(self: Composite, n: Node) =
  self.nodes.add(n)


# Context lookups
proc lookup*(self: Context, key: string): Binding =
  self.bindings[key]

proc bindit*(self: Context, key: string, val: Node): Binding =
  result = Binding(key: key, val: val)
  self.bindings[key] = result

# Constructor procs
proc raiseParseException(msg: string) =
  raise newException(ParseException, msg)

proc newContext*(): Context =
  Context(bindings: newTable[string, Binding]())

proc newWord*(s: string): Word =
  Word(word: s)

proc newSetWord*(s: string): SetWord =
  SetWord(word: s)

proc newGetWord*(s: string): GetWord =
  GetWord(word: s)

proc newLitWord*(s: string): LitWord =
  LitWord(word: s)

proc newBlok*(nodes: seq[Node]): Blok =
  Blok(nodes: nodes)
  
proc newBlok*(): Blok =
  newBlok(newSeq[Node]())

proc newParen*(): Paren =
  Paren(nodes: newSeq[Node]())

proc newCurly*(): Curly =
  Curly(nodes: newSeq[Node]())

proc newValue*(v: int): IntVal =
  IntVal(value: v)

proc newValue*(v: float): FloatVal =
  FloatVal(value: v)

proc newValue*(v: string): StringVal =
  StringVal(value: v)

proc newValue*(v: bool): BoolVal =
  BoolVal(value: v)

proc newNilVal*(): NilVal =
  NilVal()

# Methods for the base value parsers
method parseValue*(self: ValueParser, s: string): Node {.procvar.} =
  nil

method parseValue*(self: IntValueParser, s: string): Node {.procvar.} =
  try:
    return newValue(parseInt(s)) 
  except ValueError:
    return nil

method parseValue*(self: FloatValueParser, s: string): Node {.procvar.} =
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


proc len(self: Node): int =
  0

proc len(self: Composite): int =
  self.nodes.len


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
    return newLitWord(token[1..^1])
  return newWord(token)

template top(self: Parser): Node =
  self.stack[self.stack.high]

template pop(self: Parser) =
  discard self.stack.pop()

proc push(self: Parser, n: Node) =
  if not self.stack.isEmpty:
    Composite(self.top).add(n)
  self.stack.add(n)

proc addNode(self: Parser) =
  if self.token.len > 0:
    Composite(self.top).add(self.newWordOrValue())
    self.token = ""

proc parse*(self: Parser, str: string): Node =
  var ch: char
  var currentValueParser: ValueParser
  var pos = 0
  self.stack = @[]
  self.token = ""
  # Wrap code in a block, well, ok... then we can just call primDo on it.
  self.push(newBlok())
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
            self.push(newBlok())
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


when isMainModule:
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  echo repr(newParser().parse(code))
