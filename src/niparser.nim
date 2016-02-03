# Ni Language, Parser
#
# Copyright (c) 2015 Göran Krampe

import strutils, sequtils, tables, hashes

type
  ParseException* = object of Exception

  # The iterative parser builds a Node tree using a stack for nested blocks
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
  FloatValueParser = ref object of ValueParser
  StringValueParser = ref object of ValueParser

  # Nodes form an AST which we later eval directly using Interpreter
  Node* = ref object of RootObj
    tags*: seq[string]
  Word* = ref object of Node
    word*: string  
  GetW* = ref object of Word
  EvalW* = ref object of Word
  
  # These are all concrete word types
  LitWord* = ref object of Word  

  EvalWord* = ref object of EvalW
  EvalSelfWord* = ref object of EvalW
  EvalOuterWord* = ref object of EvalW
  EvalArgWord* = ref object of EvalW

  GetWord* = ref object of GetW
  GetSelfWord* = ref object of GetW
  GetOuterWord* = ref object of GetW
  GetArgWord* = ref object of GetW
  
  # And support for keyword syntactic sugar, only used during parsing
  KeyWord* = ref object of Node
    keys*: seq[string]
    args*: seq[Node]
  
  Value* = ref object of Node
  IntVal* = ref object of Value
    value*: int
  FloatVal* = ref object of Value
    value*: float
  StringVal* = ref object of Value
    value*: string
  BoolVal* = ref object of Value
    value*: bool
  UndefVal* = ref object of Value
  NilVal* = ref object of Value

  # Abstract
  Composite* = ref object of Node
  SeqComposite* = ref object of Node
    nodes*: seq[Node]
    pos*: int
 
  # Concrete
  Paren* = ref object of SeqComposite
  Blok* = ref object of SeqComposite
  Curly* = ref object of SeqComposite  
  Dictionary* = ref object of Composite
    bindings*: ref OrderedTable[Node, Binding]  

  # Dictionaries currently holds Bindings instead of the value directly.
  # This way we we can later reify Binding
  # so we can hold it and set/get its value without lookup
  Binding* = ref object of Node
    key*: Node
    val*: Node

  RuntimeException* = object of Exception

proc raiseRuntimeException*(msg: string) =
  raise newException(RuntimeException, msg)

method hash(self: Node): Hash {.base.} = 
  raiseRuntimeException("Nodes need to implement hash") 

method `==`(self, other: Node): bool {.base.} = 
  raiseRuntimeException("Nodes need to implement ==") 

method hash(self: Word): Hash =
  self.word.hash

method `==`(self: Word, other: Node): bool = 
  other of Word and (self.word == Word(other).word)

method hash(self: IntVal): Hash =
  self.value.hash

method `==`(self: IntVal, other: Node): bool =
  other of IntVal and (self.value == IntVal(other).value)

method hash(self: FloatVal): Hash =
  self.value.hash

method `==`(self: FloatVal, other: Node): bool =
  other of FloatVal and (self.value == FloatVal(other).value)

method hash(self: StringVal): Hash =
  self.value.hash

method `==`(self: StringVal, other: Node): bool =
  other of StringVal and (self.value == StringVal(other).value)

method hash(self: BoolVal): Hash =
  self.value.hash

method `==`(self: BoolVal, other: Node): bool =
  other of BoolVal and (self.value == BoolVal(other).value)
  
method hash(self: NilVal): Hash =
  hash(1)

method `==`(self: Nilval, other: Node): bool =
  other of NilVal

method hash(self: UndefVal): Hash =
  hash(2)

method `==`(self: Undefval, other: Node): bool =
  other of UndefVal


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

# Ni representations
method `$`*(self: Node): string {.base.} =
  # Fallback if missing
  when defined(js):
    echo "repr not available in js"
  else:
    repr(self)

method `$`*(self: Binding): string =
  $self.key & " = " & $self.val

method `$`*(self: Dictionary): string =
  result = "{"
  var first = true
  for k,v in self.bindings:
    if first:
      result.add($v)
      first = false
    else:
      result.add(" " & $v)
  return result & "}"

method `$`*(self: IntVal): string =
  $self.value

method `$`*(self: FloatVal): string =
  $self.value

method `$`*(self: StringVal): string =
  escape(self.value)

method `$`*(self: BoolVal): string =
  $self.value

method `$`*(self: NilVal): string =
  "nil"

method `$`*(self: UndefVal): string =
  "undef"

proc `$`*(self: seq[Node]): string =
  self.map(proc(n: Node): string = $n).join(" ")

method `$`*(self: Word): string =
  self.word

method `$`*(self: EvalWord): string =
  self.word

method `$`*(self: EvalSelfWord): string =
  "." & self.word

method `$`*(self: EvalOuterWord): string =
  ".." & self.word

method `$`*(self: GetWord): string =
  "^" & self.word

method `$`*(self: GetSelfWord): string =
  "^." & self.word

method `$`*(self: GetOuterWord): string =
  "^.." & self.word

method `$`*(self: LitWord): string =
  "'" & self.word

method `$`*(self: EvalArgWord): string =
  ":" & self.word

method `$`*(self: GetArgWord): string =
  ":^" & self.word

method `$`*(self: Blok): string =
  "[" & $self.nodes & "]"

method `$`*(self: Paren): string =
  "(" & $self.nodes & ")"

method `$`*(self: Curly): string =
  "{" & $self.nodes & "}"

method `$`*(self: KeyWord): string =
  result = ""
  for i in 0 .. self.keys.len - 1:
    result = result & self.keys[i] & " " & $self.args[i]

# Human string representations
method form*(self: Node): string {.base.} =
  # Default is to use $
  $self

method form*(self: StringVal): string =
  # No surrounding ""
  $self.value

# Dictionary lookups
proc lookup*(self: Dictionary, key: Node): Binding =
  self.bindings.getOrDefault(key)

proc makeBinding*(self: Dictionary, key: Node, val: Node): Binding =
  result = Binding(key: key, val: val)
  self.bindings[key] = result

# Constructor procs
proc raiseParseException(msg: string) =
  raise newException(ParseException, msg)

proc newDictionary*(): Dictionary =
  Dictionary(bindings: newOrderedTable[Node, Binding]())

proc newEvalWord*(s: string): EvalWord =
  EvalWord(word: s)

proc newEvalSelfWord*(s: string): EvalSelfWord =
  EvalSelfWord(word: s)

proc newEvalOuterWord*(s: string): EvalOuterWord =
  EvalOuterWord(word: s)

proc newGetWord*(s: string): GetWord =
  GetWord(word: s)

proc newGetSelfWord*(s: string): GetSelfWord =
  GetSelfWord(word: s)

proc newGetOuterWord*(s: string): GetOuterWord =
  GetOuterWord(word: s)

proc newLitWord*(s: string): LitWord =
  LitWord(word: s)

proc newEvalArgWord*(s: string): EvalArgWord =
  EvalArgWord(word: s)

proc newGetArgWord*(s: string): GetArgWord =
  GetArgWord(word: s)

proc newKeyWord*(): KeyWord =
  KeyWord(keys: newSeq[string](), args: newSeq[Node]())

proc newBlok*(nodes: seq[Node]): Blok =
  Blok(nodes: nodes)
  
proc newBlok*(): Blok =
  Blok(nodes: newSeq[Node]())

proc newParen*(nodes: seq[Node]): Paren =
  Paren(nodes: nodes)

proc newParen*(): Paren =
  Paren(nodes: newSeq[Node]())

proc newCurly*(nodes: seq[Node]): Curly =
  Curly(nodes: nodes)

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

proc newUndefVal*(): UndefVal =
  UndefVal()

# AST manipulation
proc add*(self: SeqComposite, n: Node) =
  self.nodes.add(n)

proc add*(self: SeqComposite, n: openarray[Node]) =
  self.nodes.add(n)

method concat*(self: SeqComposite, nodes: seq[Node]): SeqComposite {.base.} =
  raiseRuntimeException("Should not happen..." & $self & " " & $nodes)

method concat*(self: Blok, nodes: seq[Node]): SeqComposite =
  newBlok(self.nodes.concat(nodes))

method concat*(self: Paren, nodes: seq[Node]): SeqComposite =
  newParen(self.nodes.concat(nodes))

method concat*(self: Curly, nodes: seq[Node]): SeqComposite =
  newCurly(self.nodes.concat(nodes))
  
proc removeLast*(self: SeqComposite) =
  system.delete(self.nodes,self.nodes.high)

# Methods for the base value parsers
method parseValue*(self: ValueParser, s: string): Node {.procvar,base.} =
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
  # If it ends and starts with '"' then ok
  if s.len > 1 and s[0] == '"' and s[^1] == '"':
    result = newValue(unescape(s))

method prefixLength(self: ValueParser): int {.base.} = 0

method tokenReady(self: ValueParser, token: string, ch: char): string {.base.} =
  ## Return true if self wants to take over parsing a literal
  ## and deciding when its complete. This is used for delimited literals
  ## that can contain whitespace. Otherwise parseValue is needed.
  nil

method tokenStart(self: ValueParser, token: string, ch: char): bool {.base.} =
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

proc len(self: SeqComposite): int =
  self.nodes.len

proc addKey(self: KeyWord, key: string) =
  self.keys.add(key)

proc addArg(self: KeyWord, arg: Node) =
  self.args.add(arg)

proc inBalance(self: KeyWord): bool =
  return self.args.len == self.keys.len

proc produceNodes(self: KeyWord): seq[Node] =
  result = newSeq[Node]()
  result.add(newEvalWord(self.keys.join()))
  result.add(self.args)

template top(self: Parser): Node =
  self.stack[self.stack.high]

proc currentKeyword(self: Parser): KeyWord =
  # If there is a KeyWord on the stack return it, otherwise nil
  if self.top of KeyWord:
    return KeyWord(self.top)
  else:
    return nil

proc closeKeyword(self: Parser)
proc pop(self: Parser) =
  if self.currentKeyword().notNil:
    self.closeKeyword()
  discard self.stack.pop()

proc addNode(self: Parser)
proc closeKeyword(self: Parser) =
  let keyword = self.currentKeyword()
  discard self.stack.pop()
  let nodes = keyword.produceNodes()
  SeqComposite(self.top).removeLast()
  SeqComposite(self.top).add(nodes)
  
proc doAddNode(self: Parser, node: Node) =
  # If we are collecting a keyword, we get nil until its ready
  let keyword = self.currentKeyword()
  if keyword.isNil:
    # Then we are not parsing a keyword
    SeqComposite(self.top).add(node)
  else:
    if keyword.inBalance():
      self.closeKeyword()
      self.doAddNode(node)
    else:
      keyword.args.add(node)

proc push(self: Parser, n: Node) =
  if not self.stack.isEmpty:
    self.doAddNode(n)
  self.stack.add(n)


proc newWord(self: Parser, token: string): Node =
  let len = token.len
  let first = token[0]
 
  # All arg words (unique for Ni) are preceded with ":"
  if first == ':' and len > 1:
    if token[1] == '^':
      if token.len < 3:
        raiseParseException("Malformed get argword, missing at least 1 character")
      # Then its a get arg word
      return newGetArgWord(token[2..^1])
    else:
      return newEvalArgWord(token[1..^1])
 
  # All lookup words are preceded with "^"
  if first == '^' and len > 1:
    if token[1] == '.':
      # Local or parent
      if len > 2:
        if token[2] == '.':
          if len > 3:
            return newGetOuterWord(token[3..^1])
          else:
            raiseParseException("Malformed parent lookup word, missing at least 1 character")
        else:
          return newGetSelfWord(token[2..^1])
      else:
        raiseParseException("Malformed local lookup word, missing at least 1 character")
    else:
      return newGetWord(token[1..^1])
  
  # All literal words are preceded with "'"
  if first == '\'':
    if len < 2:
      raiseParseException("Malformed literal word, missing at least 1 character")
    else:
      return newLitWord(token[1..^1])
  
  # All keywords end with ":"
  if len > 1 and token[^1] == ':':
    if self.isNil:
      # We have no parser, this is a call from the interpreter
      return newEvalWord(token)
    else:
      if self.currentKeyword().isNil:
        # Then its the first key we parse, push a KeyWord
        self.push(newKeyWord())
      if self.currentKeyword().inBalance():
        # keys and args balance so far, so we can add a new key
        self.currentKeyword().addKey(token)
      else:
        raiseParseException("Malformed keyword syntax, expecting an argument")
      return nil
  
  # A regular eval word then, possibly prefixed with . or ..
  if first == '.':
    # Local or parent
    if len > 1:
      if token[1] == '.':
        if len > 2:
          return newEvalOuterWord(token[2..^1])
        else:
          raiseParseException("Malformed parent eval word, missing at least 1 character")
      else:
        return newEvalSelfWord(token[1..^1])
    else:
      raiseParseException("Malformed local eval word, missing at least 1 character")
  else:
    return newEvalWord(token)

template newWord*(token: string): Node =
  newWord(nil, token)

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
  return newWord(self, token)

proc addNode(self: Parser) =
  # If there is a token we figure out what to make of it
  if self.token.len > 0:
    let node = self.newWordOrValue()
    if node.notNil:
      self.doAddNode(node)

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
            while (pos < str.len) and (str[pos] != '\l'):
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
          # Just collect for current value parser
          self.token.add(ch)
  self.addNode()
  if self.currentKeyword().notNil:
    self.closeKeyword()
  self.top

when isMainModule and not defined(js):
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  echo repr(newParser().parse(code))
