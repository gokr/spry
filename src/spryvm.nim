# Spry Language Interpreter
#
# Copyright (c) 2015 Göran Krampe

import strutils, sequtils, tables, hashes

type
  ParseException* = object of Exception

  # The iterative parser builds a Node tree using a stack for nested blocks
  Parser* = ref object
    token: string                       # Collects characters into a token
    ws: string                          # Collects whitespace and comments
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
    comment*: string
    tags*: Blok
  Word* = ref object of Node
    word*: string
  GetW* = ref object of Word
  EvalW* = ref object of Word

  # These are all concrete word types
  LitWord* = ref object of Word

  EvalWord* = ref object of EvalW
  EvalModuleWord* = ref object of EvalWord
    module*: Word
  EvalSelfWord* = ref object of EvalW
  EvalOuterWord* = ref object of EvalW
  EvalArgWord* = ref object of EvalW

  GetWord* = ref object of GetW
  GetModuleWord* = ref object of GetWord
    module*: Word
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
  TrueVal* = ref object of BoolVal
  FalseVal* = ref object of BoolVal

  UndefVal* = ref object of Value
  NilVal* = ref object of Value

  PointerVal* = ref object of Value
    value*: pointer

  # Abstract
  Composite* = ref object of Node
    commentEnd*: string
  SeqComposite* = ref object of Composite
    nodes*: seq[Node]
    pos*: int

  # Concrete
  Paren* = ref object of SeqComposite
  Blok* = ref object of SeqComposite
  Curly* = ref object of SeqComposite
  Map* = ref object of Composite
    bindings*: OrderedTable[Node, Binding]

  # Dictionaries currently holds Bindings instead of the value directly.
  # This way we we can later reify Binding
  # so we can hold it and set/get its value without lookup
  Binding* = ref object of Node
    key*: Node
    val*: Node

  RuntimeException* = object of Exception

proc raiseRuntimeException*(msg: string) =
  raise newException(RuntimeException, msg)


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

# spry representations
method `$`*(self: Node): string {.base.} =
  # Fallback if missing
  when defined(js):
    echo "repr not available in js"
  else:
    repr(self)

method commented*(self: Node): string {.base.} =
  if self.comment.isNil:
    $self
  else:
    self.comment & $self

method `$`*(self: Binding): string =
  $self.key & " = " & $self.val

method `$`*(self: Map): string =
  result = "{"
  var first = true
  for k,v in self.bindings:
    if first:
      result.add($v)
      first = false
    else:
      result.add(" " & $v)
  return result & "}"

method commented*(self: Map): string =
  if self.comment.isNil:
    result = "{"
  else:
    result = self.comment & "{"
  var first = true
  for k,v in self.bindings:
    if first:
      result.add(commented(v))
      first = false
    else:
      result.add(commented(v))
  return result & "}"


method `$`*(self: IntVal): string =
  $self.value

method `$`*(self: FloatVal): string =
  $self.value

method `$`*(self: StringVal): string =
  escape(self.value)

method `$`*(self: TrueVal): string =
  "true"

method `$`*(self: FalseVal): string =
  "false"

method `$`*(self: NilVal): string =
  "nil"

method `$`*(self: UndefVal): string =
  "undef"

proc `$`*(self: seq[Node]): string =
  self.map(proc(n: Node): string = $n).join(" ")

proc commented*(self: seq[Node]): string =
  self.map(proc(n: Node): string = commented(n)).join()

method `$`*(self: Word): string =
  self.word

method `$`*(self: EvalWord): string =
  self.word

method `$`*(self: EvalModuleWord): string =
  $self.module & "::" & self.word

method `$`*(self: EvalSelfWord): string =
  "." & self.word

method `$`*(self: EvalOuterWord): string =
  ".." & self.word

method `$`*(self: GetWord): string =
  "^" & self.word

method `$`*(self: GetModuleWord): string =
  "^" & $self.module & "::" & self.word

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

method commented*(self: Blok): string =
  if self.comment.isNil:
    result = "["
  else:
    result = self.comment & "["
  result = result & commented(self.nodes)
  if self.commentEnd.isNil:
    result = result & "]"
  else:
    result = result & self.commentEnd & "]"

method `$`*(self: Paren): string =
  "(" & $self.nodes & ")"

method commented*(self: Paren): string =
  if self.comment.isNil:
    result = "("
  else:
    result = self.comment & "("
  result = result & commented(self.nodes)
  if self.commentEnd.isNil:
    result = result & ")"
  else:
    result = result & self.commentEnd & ")"

method `$`*(self: Curly): string =
  "{" & $self.nodes & "}"

method commented*(self: Curly): string =
  if self.comment.isNil:
    result = "{"
  else:
    result = self.comment & "{"
  result = result & commented(self.nodes)
  if self.commentEnd.isNil:
    result = result & "}"
  else:
    result = result & self.commentEnd & "}"

method `$`*(self: KeyWord): string =
  result = ""
  for i in 0 .. self.keys.len - 1:
    result = result & self.keys[i] & " " & $self.args[i]

method commented*(self: KeyWord): string =
  result = ""
  for i in 0 .. self.keys.len - 1:
    result = result & self.keys[i] & commented(self.args[i])

# Hash and == implementations
method hash*(self: Node): Hash {.base.} =
  raiseRuntimeException("Nodes need to implement hash")

method `==`*(self: Node, other: Node): bool {.base.} =
  raiseRuntimeException("Nodes need to implement ==")

method hash*(self: Word): Hash =
  self.word.hash

method `==`*(self: Word, other: Node): bool =
  other of Word and (self.word == Word(other).word)

method hash*(self: IntVal): Hash =
  self.value.hash

method `==`*(self: IntVal, other: Node): bool =
  other of IntVal and (self.value == IntVal(other).value)

method hash*(self: FloatVal): Hash =
  self.value.hash

method `==`*(self: FloatVal, other: Node): bool =
  other of FloatVal and (self.value == FloatVal(other).value)

method hash*(self: StringVal): Hash =
  self.value.hash

method `==`*(self: StringVal, other: Node): bool =
  other of StringVal and (self.value == StringVal(other).value)

method hash*(self: TrueVal): Hash =
  hash(1)

method hash*(self: FalseVal): Hash =
  hash(0)

method value*(self: BoolVal): bool {.base.} =
  true

method value*(self: FalseVal): bool =
  false

method `==`*(self, other: TrueVal): bool =
  true

method `==`*(self, other: FalseVal): bool =
  true

method `==`*(self: TrueVal, other: FalseVal): bool =
  false

method `==`*(self: FalseVal, other: TrueVal): bool =
  false

#method `==`*(self: BoolVal, other: Node): bool =
#  other of BoolVal and (self == BoolVal(other))

#method `==`*(other: Node, self: BoolVal): bool =
#  other of BoolVal and (self == BoolVal(other))

#method `==`*(other, self: BoolVal): bool =
#  self == other

method hash*(self: NilVal): Hash =
  hash(1)

method `==`*(self: Nilval, other: Node): bool =
  other of NilVal

method hash*(self: UndefVal): Hash =
  hash(2)

method `==`*(self: Undefval, other: Node): bool =
  other of UndefVal


# Human string representations
method form*(self: Node): string {.base.} =
  # Default is to use $
  $self

method form*(self: StringVal): string =
  # No surrounding ""
  $self.value

# Map lookups
proc lookup*(self: Map, key: Node): Binding =
  self.bindings.getOrDefault(key)

proc makeBinding*(self: Map, key: Node, val: Node): Binding =
  result = Binding(key: key, val: val)
  self.bindings[key] = result

# Constructor procs
proc raiseParseException(msg: string) =
  raise newException(ParseException, msg)

proc newMap*(): Map =
  Map(bindings: initOrderedTable[Node, Binding]())

proc newMap*(bindings: OrderedTable[Node, Binding]): Map =
  Map(bindings: bindings)

proc newEvalWord*(s: string): EvalWord =
  EvalWord(word: s)

proc newLitWord*(s: string): LitWord =
  LitWord(word: s)

proc newEvalModuleWord*(s: string): EvalWord =
  let both = s.split("::")
  EvalModuleWord(word: both[1], module: newEvalWord(both[0]))

proc newEvalSelfWord*(s: string): EvalSelfWord =
  EvalSelfWord(word: s)

proc newEvalOuterWord*(s: string): EvalOuterWord =
  EvalOuterWord(word: s)

proc newGetWord*(s: string): GetWord =
  GetWord(word: s)

proc newGetModuleWord*(s: string): GetWord =
  let both = s.split("::")
  GetModuleWord(word: both[1], module: newEvalWord(both[0]))

proc newGetSelfWord*(s: string): GetSelfWord =
  GetSelfWord(word: s)

proc newGetOuterWord*(s: string): GetOuterWord =
  GetOuterWord(word: s)

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

proc newValue*(v: pointer): PointerVal =
  PointerVal(value: v)

proc newValue*(v: bool): BoolVal =
  if v:
    TrueVal()
  else:
    FalseVal()

proc newNilVal*(): NilVal =
  NilVal()

proc newUndefVal*(): UndefVal =
  UndefVal()

# AST manipulation
proc add*(self: SeqComposite, n: Node) =
  self.nodes.add(n)

proc add*(self: SeqComposite, n: openarray[Node]) =
  self.nodes.add(n)

proc contains*(self: SeqComposite, n: Node): bool =
  self.nodes.contains(n)

proc contains*(self: Map, n: Node): bool =
  self.bindings.contains(n)

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

method clone*(self: Node): Node {.base.} =
  raiseRuntimeException("Should not happen..." & $self)

method clone*(self: Map): Node =
  newMap(self.bindings)

method clone*(self: Blok): Node =
  newBlok(self.nodes)

method clone*(self: Paren): Node =
  newParen(self.nodes)

method clone*(self: Curly): Node =
  newCurly(self.nodes)

# Methods for the base value parsers
method parseValue*(self: ValueParser, s: string): Node {.procvar,base.} =
  nil

method parseValue*(self: IntValueParser, s: string): Node {.procvar.} =
  if (s.len > 0) and (s[0].isDigit or s[0]=='+' or s[0]=='-'):
    try:
      return newValue(parseInt(s))
    except ValueError:
      return nil

method parseValue*(self: FloatValueParser, s: string): Node {.procvar.} =
  if (s.len > 0) and (s[0].isDigit or s[0]=='+' or s[0]=='-'):
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
  ## Create a new Spry parser with the basic value parsers included
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
proc pop(self: Parser): Node =
  if self.currentKeyword().notNil:
    self.closeKeyword()
  self.stack.pop()

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

  # All arg words (unique for Spry) are preceded with ":"
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
      if token.contains("::"):
        return newGetModuleWord(token[1..^1])
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
    if token.contains("::"):
      return newEvalModuleWord(token)
    else:
      return newEvalWord(token)

template newWord*(token: string): Node =
  newWord(nil, token)

proc newWordOrValue(self: Parser): Node =
  ## Decide what to make, a word or value
  let token = self.token
  let ws = self.ws
  self.token = ""
  self.ws = ""

  # Try all valueParsers...
  for p in self.valueParsers:
    let valueOrNil = p.parseValue(token)
    if valueOrNil.notNil:
      valueOrNil.comment = ws
      return valueOrNil

  # Then it must be a word
  result = newWord(self, token)
  if result.notNil:
    result.comment = ws

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
  self.ws = ""
  # Wrap code in a block and later return last element as result.
  var blok = newBlok()
  self.push(blok)
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
        # Collect for formatting
        self.ws.add(ch)
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
          # Comments are collected and added to next node
          of '#':
            self.addNode()
            self.ws.add('#')
            while (pos < str.len) and (str[pos] != '\l'):
              self.ws.add(str[pos])
              inc pos
            #if (pos < str.len):
            #  self.ws.add('\l')
          # Paren
          of '(':
            let n = newParen()
            n.comment = self.ws
            self.ws = ""
            self.addNode()
            self.push(n)
          # Block
          of '[':
            let n = newBlok()
            n.comment = self.ws
            self.ws = ""
            self.addNode()
            self.push(n)
         # Curly
          of '{':
            let n = newCurly()
            n.comment = self.ws
            self.ws = ""
            self.addNode()
            self.push(n)
          of ')':
            self.addNode()
            let n = self.pop
            Composite(n).commentEnd = self.ws
            self.ws = ""
          # Block
          of ']':
            self.addNode()
            let n = self.pop
            Composite(n).commentEnd = self.ws
            self.ws = ""
          # Curly
          of '}':
            self.addNode()
            let n = self.pop
            Composite(n).commentEnd = self.ws
            self.ws = ""
          # Ok, otherwise we just collect the char
          else:
            self.token.add(ch)
        else:
          # Just collect for current value parser
          self.token.add(ch)
  self.addNode()
  if self.currentKeyword().notNil:
    self.closeKeyword()
  blok.nodes[^1]


type
  # Spry interpreter
  Interpreter* = ref object
    currentActivation*: Activation  # Execution spaghetti stack
    rootActivation*: RootActivation # The first one
    root*: Map               # Root bindings
    modules*: Blok           # Modules for unqualified lookup
    trueVal*: Node
    falseVal*: Node
    undefVal*: Node
    nilVal*: Node
    objectish*: Node         # Tag for Objects and Modules

  # Node type to hold Nim primitive procs
  ProcType* = proc(spry: Interpreter): Node
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
    locals*: Map  # This is where we put named args and locals
  FunkActivation* = ref object of BlokActivation
  ParenActivation* = ref object of Activation
  CurlyActivation* = ref object of BlokActivation
  RootActivation* = ref object of BlokActivation


# Forward declarations to make Nim happy
proc funk*(spry: Interpreter, body: Blok, infix: bool): Node
proc evalRoot*(spry: Interpreter, code: string): Node
method eval*(self: Node, spry: Interpreter): Node {.base.}
method evalDo*(self: Node, spry: Interpreter): Node {.base.}

# String representations
method `$`*(self: NimProc): string =
  if self.infix:
    result = "nimi"
  else:
    result = "nim"
  return result & "(" & $self.arity & ")"

method `$`*(self: Funk): string =
  when true:
    if self.infix:
      result = "funci "
    else:
      result = "func "
    return result & "[" & $self.nodes & "]"
  else:
    return "[" & $self.nodes & "]"

method `$`*(self: Activation): string =
  return "activation [" & $self.body & " " & $self.pos & "]"

# Base stuff for accessing

# Indexing Composites
proc `[]`*(self: Map, key: Node): Node =
  if self.bindings.hasKey(key):
    return self.bindings[key].val

proc `[]`*(self: SeqComposite, key: Node): Node =
  self.nodes[IntVal(key).value]

proc `[]`*(self: SeqComposite, key: IntVal): Node =
  self.nodes[key.value]

proc `[]`*(self: SeqComposite, key: int): Node =
  self.nodes[key]

proc `[]=`*(self: Map, key, val: Node) =
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

proc newRootActivation(root: Map): RootActivation =
  RootActivation(body: newBlok(), locals: root)

proc newActivation*(funk: Funk): FunkActivation =
  FunkActivation(body: funk)

proc newActivation*(body: Blok): Activation =
  BlokActivation(body: body)

proc newActivation*(body: Paren): ParenActivation =
  ParenActivation(body: body)

proc newActivation*(body: Curly): CurlyActivation =
  result = CurlyActivation(body: body)
  result.locals = newMap()

# Stack iterator walking parent refs
iterator stack*(spry: Interpreter): Activation =
  var activation = spry.currentActivation
  while activation.notNil:
    yield activation
    activation = activation.parent

proc getLocals(self: BlokActivation): Map =
  if self.locals.isNil:
    self.locals = newMap()
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

# Walk maps for lookups and binds. Skips parens since they do not have
# locals and uses outer() that will let Funks go to their "lexical parent"
iterator mapWalk(first: Activation): Activation =
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

method `eq`(a: Node, b: Node): Node {.base.} =
  raiseRuntimeException("Can not evaluate " & $a & " == " & $b)
method `eq`(a: IntVal, b: IntVal): Node {.inline.} =
  newValue(a.value == b.value)
method `eq`(a: IntVal, b: FloatVal): Node {.inline.} =
  newValue(a.value.float == b.value)
method `eq`(a: FloatVal, b: IntVal): Node {.inline.} =
  newValue(a.value == b.value.float)
method `eq`(a, b: FloatVal): Node {.inline.} =
  newValue(a.value == b.value)
method `eq`(a, b: StringVal): Node {.inline.} =
  newValue(a.value == b.value)
method `eq`(a, b: BoolVal): Node {.inline.} =
  newValue(a.value == b.value)

method `&`(a: Node, b: Node): Node {.inline,base.} =
  raiseRuntimeException("Can not evaluate " & $a & " & " & $b)
method `&`(a, b: StringVal): Node {.inline.} =
  newValue(a.value & b.value)
method `&`(a, b: SeqComposite): Node {.inline.} =
  a.add(b.nodes)
  return a

# Support procs for eval()
template pushActivation*(spry: Interpreter, activation: Activation) =
  activation.parent = spry.currentActivation
  spry.currentActivation = activation

template popActivation*(spry: Interpreter) =
  spry.currentActivation = spry.currentActivation.parent

proc atEnd*(self: Activation): bool {.inline.} =
  self.pos == self.len

proc next*(self: Activation): Node {.inline.} =
  if self.atEnd:
    raiseRuntimeException("End of current block, too few arguments?")
  else:
    result = self[self.pos]
    inc(self.pos)

method doReturn*(self: Activation, spry: Interpreter) {.base.} =
  spry.currentActivation = self.parent
  if spry.currentActivation.notNil:
    spry.currentActivation.returned = true

method doReturn*(self: FunkActivation, spry: Interpreter) =
  spry.currentActivation = Funk(self.body).parent

method isObjectish(self: Activation, spry: Interpreter): bool {.base.} =
  false

method isObjectish(self: BlokActivation, spry: Interpreter): bool =
  self.locals.notNil and self.locals.tags.notNil and self.locals.tags.contains(spry.objectish)


method lookup(self: Activation, key: Node): Binding {.base.} =
  # Base implementation needed for dynamic dispatch to work
  nil

method lookup(self: BlokActivation, key: Node): Binding =
  if self.locals.notNil:
    return self.locals.lookup(key)

proc lookup(spry: Interpreter, key: Node): Binding =
  ## Not sure why, but three methods didn't want to fly
  if (key of EvalModuleWord):
    let binding = spry.lookup(EvalModuleWord(key).module)
    if binding.notNil:
      let module = binding.val
      if module.notNil:
        result = Map(module).lookup(key)
  elif (key of GetModuleWord):
    let binding = spry.lookup(GetModuleWord(key).module)
    if binding.notNil:
      let module = binding.val
      if module.notNil:
        result = Map(module).lookup(key)
  else:
    # Try looking upwards ending in the rootActivation
    for activation in mapWalk(spry.currentActivation):
      let hit = activation.lookup(key)
      if hit.notNil:
        return hit
    # Then we try looking in the modules block, in order
    for map in spry.modules.nodes:
      let hit = Map(map).lookup(key)
      if hit.notNil:
        return hit

proc lookupSelf(spry: Interpreter, key: Node): Binding =
  # Find first objectish, ending in the rootActivation
  for activation in mapWalk(spry.currentActivation):
    if activation.isObjectish(spry):
      return activation.lookup(key)

proc lookupLocal(spry: Interpreter, key: Node): Binding =
  return spry.currentActivation.lookup(key)

proc lookupParent(spry: Interpreter, key: Node): Binding =
  # Silly way of skipping to get to parent
  var inParent = false
  for activation in mapWalk(spry.currentActivation):
    if inParent:
      return activation.lookup(key)
    else:
      inParent = true

method makeBinding(self: Activation, key: Node, val: Node): Binding {.base.} =
  nil

method makeBinding(self: BlokActivation, key: Node, val: Node): Binding =
  self.getLocals().makeBinding(key, val)

proc makeBinding(spry: Interpreter, key: Node, val: Node): Binding =
  # Bind in first activation with locals
  for activation in mapWalk(spry.currentActivation):
    return activation.makeBinding(key, val)

proc setBinding*(spry: Interpreter, key: Node, value: Node): Binding =
  result = spry.lookup(key)
  if result.notNil:
    result.val = value
  else:
    result = spry.makeBinding(key, value)

method infix(self: Node): bool {.base.} =
  false

method infix(self: Funk): bool =
  self.infix

method infix(self: NimProc): bool =
  self.infix

method infix(self: Binding): bool =
  return self.val.infix

proc argParent(spry: Interpreter): Activation =
  # Return first activation up the parent chain that was a caller
  for activation in callerWalk(spry.currentActivation):
    return activation

proc parentArgInfix*(spry: Interpreter): Node =
  ## Pull the parent infix arg
  let act = spry.argParent()
  act.last

proc argInfix*(spry: Interpreter): Node =
  ## Pull the infix arg
  spry.currentActivation.last

proc parentArg*(spry: Interpreter): Node =
  ## Pull next argument from parent activation
  let act = spry.argParent()
  act.next()

proc arg*(spry: Interpreter): Node =
  ## Pull next argument from activation
  spry.currentActivation.next()

template evalArgInfix*(spry: Interpreter): Node =
  ## Pull the infix arg and eval
  spry.currentActivation.last.eval(spry)

proc evalArg*(spry: Interpreter): Node =
  ## Pull next argument from activation and eval
  spry.currentActivation.next().eval(spry)

proc makeWord*(self: Interpreter, word: string, value: Node) =
  discard self.root.makeBinding(newEvalWord(word), value)

proc boolVal(val: bool, spry: Interpreter): Node =
  if val:
    result = spry.trueVal
  else:
    result = spry.falseVal

proc reify(word: LitWord): Node =
  newWord(word.word)

# A template reducing boilerplate for registering nim primitives
template nimPrim*(name: string, infix: bool, arity: int, body: stmt): stmt {.immediate, dirty.} =
  spry.makeWord(name, newNimProc(
    proc (spry: Interpreter): Node = body, infix, arity))

proc newInterpreter*(): Interpreter =
  let spry = Interpreter(root: newMap())
  result = spry

  # Singletons
  spry.trueVal = newValue(true)
  spry.falseVal = newValue(false)
  spry.nilVal = newNilVal()
  spry.undefVal = newUndefVal()
  spry.objectish = newLitWord("objectish")
  spry.makeWord("false", spry.falseVal)
  spry.makeWord("true", spry.trueVal)
  spry.makeWord("undef", spry.undefVal)
  spry.makeWord("nil", spry.nilVal)
  spry.makeWord("objectish", spry.objectish)

  # Reflection words
  # Access to current Activation
  nimPrim("activation", false, 0):
    spry.currentActivation

  # Access to closest scope
  nimPrim("locals", false, 0):
    for activation in mapWalk(spry.currentActivation):
      return BlokActivation(activation).getLocals()

  # Access to closest object
  nimPrim("self", false, 0):
    spry.undefVal

  # Access to root Map
  nimPrim("root", false, 0):
    spry.root

  # Access to modules Block
  spry.modules = newBlok()
  spry.makeWord("modules", spry.modules)

  # Tags
  nimPrim("tag:", true, 2):
    result = evalArgInfix(spry)
    let tag = evalArg(spry)
    if result.tags.isNil:
      result.tags = newBlok()
    if tag of LitWord:
      result.tags.add(reify(LitWord(tag)))
    else:
      result.tags.add(tag)
  nimPrim("tag?", true, 2):
    let node = evalArgInfix(spry)
    let tag = evalArg(spry)
    if node.tags.isNil:
      return spry.falseVal
    return boolVal(node.tags.contains(tag), spry)
  nimPrim("tags", true, 1):
    let node = evalArgInfix(spry)
    if node.tags.isNil:
      return spry.falseVal
    return node.tags
  nimPrim("tags:", true, 2):
    result = evalArgInfix(spry)
    result.tags = Blok(evalArg(spry))


  # Lookups
  nimPrim("?", true, 1):
    let val = evalArgInfix(spry)
    newValue(not (val of UndefVal))

  # Assignments
  nimPrim("=", true, 2):
    result = evalArg(spry) # Perhaps we could make it eager here? Pulling in more?
    discard spry.setBinding(argInfix(spry), result)

  # Basic math
  nimPrim("+", true, 2):  evalArgInfix(spry) + evalArg(spry)
  nimPrim("-", true, 2):  evalArgInfix(spry) - evalArg(spry)
  nimPrim("*", true, 2):  evalArgInfix(spry) * evalArg(spry)
  nimPrim("/", true, 2):  evalArgInfix(spry) / evalArg(spry)

  # Comparisons
  nimPrim("<", true, 2):  evalArgInfix(spry) < evalArg(spry)
  nimPrim(">", true, 2):  evalArgInfix(spry) > evalArg(spry)
  nimPrim("<=", true, 2):  evalArgInfix(spry) <= evalArg(spry)
  nimPrim(">=", true, 2):  evalArgInfix(spry) >= evalArg(spry)
  nimPrim("==", true, 2):  eq(evalArgInfix(spry), evalArg(spry))
  nimPrim("!=", true, 2):  newValue(not BoolVal(eq(evalArgInfix(spry), evalArg(spry))).value)

  # Booleans
  nimPrim("not", false, 1): newValue(not BoolVal(evalArg(spry)).value)
  nimPrim("and", true, 2):
    let arg1 = BoolVal(evalArgInfix(spry)).value
    let arg2 = arg(spry) # We need to make sure we consume this one, since "and" is shortcutting
    newValue(arg1 and BoolVal(arg2.eval(spry)).value)
  nimPrim("or", true, 2):
    let arg1 = BoolVal(evalArgInfix(spry)).value
    let arg2 = arg(spry) # We need to make sure we consume this one, since "or" is shortcutting
    newValue(arg1 or BoolVal(arg2.eval(spry)).value)

  # Concatenation
  nimPrim(",", true, 2):
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
  nimPrim("form", true, 1):
    newValue(form(evalArgInfix(spry)))
  nimPrim("commented", true, 1):
    newValue(commented(evalArgInfix(spry)))
  nimPrim("asFloat", true, 1):
    let val = evalArgInfix(spry)
    if val of FloatVal:
      return val
    elif val of IntVal:
      return newValue(toFloat(IntVal(val).value))
    else:
      raiseRuntimeException("Can not convert to float")
  nimPrim("asInt", true, 1):
    let val = evalArgInfix(spry)
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
  # Spry uses at/put instead of pick/poke and read/write instead of change/at

  # Left to think about is peek/poke (Rebol has no peek) and perhaps pick/drop
  # The old C64 Basic had peek/poke for memory at:/at:put: ... :) Otherwise I
  # generally associate peek with lookahead.
  # Idea here: Use xxx? for infix funcs, arity 1, returning booleans
  # ..and xxx! for infix funcs arity 0.
  nimPrim("size", true, 1):
    let comp = evalArgInfix(spry)
    if comp of SeqComposite:
      return newValue(SeqComposite(evalArgInfix(spry)).nodes.len)
    elif comp of Map:
      return newValue(Map(evalArgInfix(spry)).bindings.len)
  nimPrim("at:", true, 2):
    ## Ugly, but I can't get [] to work as methods...
    let comp = evalArgInfix(spry)
    if comp of SeqComposite:
      return SeqComposite(comp)[evalArg(spry)]
    elif comp of Map:
      let key = evalArg(spry)
      if key of LitWord:
        return Map(comp)[reify(LitWord(key))]
      else:
        return Map(comp)[key]
  nimPrim("at:put:", true, 3):
    let comp = evalArgInfix(spry)
    let key = evalArg(spry)
    let val = evalArg(spry)
    if comp of SeqComposite:
      SeqComposite(comp)[key] = val
    elif comp of Map:
      if key of LitWord:
        Map(comp)[reify(LitWord(key))] = val
      else:
        Map(comp)[key] = val
    return comp
  nimPrim("contains:", true, 2):
    let comp = evalArgInfix(spry)
    let key = evalArg(spry)
    var k: Node
    if key of LitWord:
      k = reify(LitWord(key))
    else:
      k = key
    if comp of SeqComposite:
      return newValue(SeqComposite(comp).contains(k))
    elif comp of Map:
      return newValue(Map(comp).contains(k))
    return comp
  nimPrim("read", true, 1):
    let comp = SeqComposite(evalArgInfix(spry))
    comp[comp.pos]
  nimPrim("write:", true, 2):
    result = evalArgInfix(spry)
    let comp = SeqComposite(result)
    comp[comp.pos] = evalArg(spry)
  nimPrim("add:", true, 2):
    result = evalArgInfix(spry)
    let comp = SeqComposite(result)
    comp.add(evalArg(spry))
  nimPrim("removeLast", true, 1):
    result = evalArgInfix(spry)
    let comp = SeqComposite(result)
    comp.removeLast()

  # Positioning
  nimPrim("reset", true, 1):  SeqComposite(evalArgInfix(spry)).pos = 0 # Called change in Rebol
  nimPrim("pos", true, 1):    newValue(SeqComposite(evalArgInfix(spry)).pos) # ? in Rebol
  nimPrim("pos:", true, 2):    # ? in Rebol
    result = evalArgInfix(spry)
    let comp = SeqComposite(result)
    comp.pos = IntVal(evalArg(spry)).value

  # Streaming
  nimPrim("next", true, 1):
    let comp = SeqComposite(evalArgInfix(spry))
    if comp.pos == comp.nodes.len:
      return spry.undefVal
    result = comp[comp.pos]
    inc(comp.pos)
  nimPrim("prev", true, 1):
    let comp = SeqComposite(evalArgInfix(spry))
    if comp.pos == 0:
      return spry.undefVal
    dec(comp.pos)
    result = comp[comp.pos]
  nimPrim("end?", true, 1):
    let comp = SeqComposite(evalArgInfix(spry))
    newValue(comp.pos == comp.nodes.len)

  # These are like in Rebol/Smalltalk but we use infix like in Smalltalk
  nimPrim("first", true, 1):  SeqComposite(evalArgInfix(spry))[0]
  nimPrim("second", true, 1): SeqComposite(evalArgInfix(spry))[1]
  nimPrim("third", true, 1):  SeqComposite(evalArgInfix(spry))[2]
  nimPrim("fourth", true, 1): SeqComposite(evalArgInfix(spry))[3]
  nimPrim("fifth", true, 1):  SeqComposite(evalArgInfix(spry))[4]
  nimPrim("last", true, 1):
    let nodes = SeqComposite(evalArgInfix(spry)).nodes
    nodes[nodes.high]

  #discard root.makeBinding("bind", newNimProc(primBind, false, 1))
  nimPrim("func", false, 1):    spry.funk(Blok(evalArg(spry)), false)
  nimPrim("funci", false, 1):   spry.funk(Blok(evalArg(spry)), true)
  nimPrim("do", false, 1):      evalArg(spry).evalDo(spry)
  nimPrim("^", false, 1):       arg(spry)
  nimPrim("eva", false, 1):     evalArg(spry)
  nimPrim("eval", false, 1):    evalArg(spry).eval(spry)
  nimPrim("parse", false, 1):   newParser().parse(StringVal(evalArg(spry)).value)

  # Word conversions
  nimPrim("reify", false, 1):
    reify(LitWord(evalArg(spry)))
  nimPrim("sym", false, 1):
    newLitWord($evalArg(spry))
  nimPrim("litword", false, 1):
    newLitWord(StringVal(evalArg(spry)).value)
  nimPrim("word", false, 1):
    newWord(StringVal(evalArg(spry)).value)

  # Cloning
  nimPrim("clone", true, 1):    evalArgInfix(spry).clone()

  # Serialize & deserialize
  nimPrim("serialize", false, 1):
    newValue($evalArg(spry))
  nimPrim("deserialize", false, 1):
    newParser().parse(StringVal(evalArg(spry)).value)

  # Control structures
  nimPrim("return", false, 1):
    spry.currentActivation.returned = true
    evalArg(spry)
  nimPrim("if", false, 2):
    if BoolVal(evalArg(spry)).value:
      return SeqComposite(evalArg(spry)).evalDo(spry)
    else:
      discard arg(spry) # Consume the block
      return spry.nilVal
  nimPrim("if:", true, 2):
    if BoolVal(evalArgInfix(spry)).value:
      return SeqComposite(evalArg(spry)).evalDo(spry)
    else:
      discard arg(spry) # Consume the block
      return spry.nilVal
  nimPrim("ifNot:", true, 2):
    if BoolVal(evalArgInfix(spry)).value:
      discard arg(spry) # Consume the block
      return spry.nilVal
    else:
      return SeqComposite(evalArg(spry)).evalDo(spry)
  nimPrim("ifelse", false, 3):
    if BoolVal(evalArg(spry)).value:
      let res = SeqComposite(evalArg(spry)).evalDo(spry)
      discard arg(spry) # Consume second block
      return res
    else:
      discard arg(spry) # Consume first block
      return SeqComposite(evalArg(spry)).evalDo(spry)
  nimPrim("if:else:", true, 3):
    if BoolVal(evalArgInfix(spry)).value:
      let res = SeqComposite(evalArg(spry)).evalDo(spry)
      discard arg(spry) # Consume second block
      return res
    else:
      discard arg(spry) # Consume first block
      return SeqComposite(evalArg(spry)).evalDo(spry)
  nimPrim("ifNot:else:", true, 3):
    if BoolVal(evalArgInfix(spry)).value:
      discard arg(spry) # Consume first block
      return SeqComposite(evalArg(spry)).evalDo(spry)
    else:
      let res = SeqComposite(evalArg(spry)).evalDo(spry)
      discard arg(spry) # Consume second block
      return res
  nimPrim("timesRepeat:", true, 2):
    let times = IntVal(evalArgInfix(spry)).value
    let fn = SeqComposite(evalArg(spry))
    for i in 1 .. times:
      result = fn.evalDo(spry)
      # Or else non local returns don't work :)
      if spry.currentActivation.returned:
        return
  nimPrim("whileTrue:", true, 2):
    let blk1 = SeqComposite(evalArgInfix(spry))
    let blk2 = SeqComposite(evalArg(spry))
    while BoolVal(blk1.evalDo(spry)).value:
      result = blk2.evalDo(spry)
      # Or else non local returns don't work :)
      if spry.currentActivation.returned:
        return
  nimPrim("whileFalse:", true, 2):
    let blk1 = SeqComposite(evalArgInfix(spry))
    let blk2 = SeqComposite(evalArg(spry))
    while not BoolVal(blk1.evalDo(spry)).value:
      result = blk2.evalDo(spry)
      # Or else non local returns don't work :)
      if spry.currentActivation.returned:
        return

  # This is hard, because evalDo of fn wants to pull its argument from
  # the parent activation, but there is none here. Hmmm.
  #nimPrim("do:", true, 2):
  #  let comp = SeqComposite(evalArgInfix(spry))
  #  let blk = SeqComposite(evalArg(spry))
  #  for node in comp.nodes:
  #    result = blk.evalDo(node, spry)

  # Parallel
  #nimPrim("parallel", true, 1):
  #  let comp = SeqComposite(evalArgInfix(spry))
  #  parallel:
  #    for node in comp.nodes:
  #      let blk = Blok(node)
  #      discard spawn blk.evalDo(spry)

  # Some scripting prims
  nimPrim("quit", false, 1):    quit(IntVal(evalArg(spry)).value)

  # Create and push root activation
  spry.rootActivation = newRootActivation(spry.root)
  spry.pushActivation(spry.rootActivation)

  # Library code
  discard spry.evalRoot """[
    # Trivial error function
    error = func [echo :msg quit 1]

    # Trivial assert
    assert = func [:x ifNot: [error "Oops, assertion failed"] return x]

    do: = funci [:blk :fun
      blk reset
      [blk end?] whileFalse: [do fun (blk next)]
    ]

    detect: = funci [:blk :pred
      blk reset
      [blk end?] whileFalse: [
        n = (blk next)
        if do pred n [return n]]
      return nil
    ]

    select: = funci [:blk :pred
      result = ([] clone)
      blk reset
      [blk end?] whileFalse: [
        n = (blk next)
        if do pred n [result add: n]]
      return result]
  ]"""

proc atEnd*(spry: Interpreter): bool {.inline.} =
  return spry.currentActivation.atEnd


proc funk*(spry: Interpreter, body: Blok, infix: bool): Node =
  result = newFunk(body, infix, spry.currentActivation)

method canEval*(self: Node, spry: Interpreter):bool {.base.} =
  false

method canEval*(self: EvalWord, spry: Interpreter):bool =
  let binding = spry.lookup(self)
  if binding.isNil:
    return false
  else:
    return binding.val.canEval(spry)

method canEval*(self: Binding, spry: Interpreter):bool =
  return self.val.canEval(spry)

method canEval*(self: Funk, spry: Interpreter):bool =
  true

method canEval*(self: NimProc, spry: Interpreter):bool =
  true

method canEval*(self: EvalArgWord, spry: Interpreter):bool =
  # Since arg words have a side effect they are "actions"
  true

method canEval*(self: GetArgWord, spry: Interpreter):bool =
  # Since arg words have a side effect they are "actions"
  true

method canEval*(self: Paren, spry: Interpreter):bool =
  true

method canEval*(self: Curly, spry: Interpreter):bool =
  true

# The heart of the interpreter - eval
method eval(self: Node, spry: Interpreter): Node =
  raiseRuntimeException("Should not happen")

method eval(self: Word, spry: Interpreter): Node =
  ## Look up
  let binding = spry.lookup(self)
  if binding.isNil:
    raiseRuntimeException("Word not found: " & $self)
  return binding.val.eval(spry)

method eval(self: GetWord, spry: Interpreter): Node =
  ## Look up only
  let hit = spry.lookup(self)
  if hit.isNil: spry.undefVal else: hit.val

method eval(self: GetSelfWord, spry: Interpreter): Node =
  ## Look up only
  let hit = spry.lookupSelf(self)
  if hit.isNil: spry.undefVal else: hit.val

method eval(self: GetOuterWord, spry: Interpreter): Node =
  ## Look up only
  let hit = spry.lookupParent(self)
  if hit.isNil: spry.undefVal else: hit.val

method eval(self: EvalWord, spry: Interpreter): Node =
  ## Look up only
  let hit = spry.lookup(self)
  if hit.isNil: spry.undefVal else: hit.val.eval(spry)

method eval(self: EvalSelfWord, spry: Interpreter): Node =
  ## Look up only
  let hit = spry.lookupSelf(self)
  if hit.isNil: spry.undefVal else: hit.val.eval(spry)

method eval(self: EvalOuterWord, spry: Interpreter): Node =
  ## Look up only
  let hit = spry.lookupParent(self)
  if hit.isNil: spry.undefVal else: hit.val.eval(spry)

method eval(self: LitWord, spry: Interpreter): Node =
  ## Evaluating a LitWord means creating a new word by stripping off \'
  #newWord(self.word)
  self

method eval(self: EvalArgWord, spry: Interpreter): Node =
  var arg: Node
  let previousActivation = spry.argParent()
  if spry.currentActivation.body.infix and spry.currentActivation.infixArg.isNil:
    arg = previousActivation.last # arg = parentArgInfix(spry)
    spry.currentActivation.infixArg = arg
  else:
    arg = previousActivation.next() # parentArg(spry)
  # This evaluation needs to be done in parent activation!
  let here = spry.currentActivation
  spry.currentActivation = previousActivation
  let ev = arg.eval(spry)
  spry.currentActivation = here
  discard spry.setBinding(self, ev)
  return ev

method eval(self: GetArgWord, spry: Interpreter): Node =
  var arg: Node
  let previousActivation = spry.argParent()
  if spry.currentActivation.body.infix and spry.currentActivation.infixArg.isNil:
    arg = previousActivation.last # arg = parentArgInfix(spry)
    spry.currentActivation.infixArg = arg
  else:
    arg = previousActivation.next() # parentArg(spry)
  discard spry.setBinding(self, arg)
  return arg

method eval(self: NimProc, spry: Interpreter): Node =
  return self.prok(spry)

proc eval(current: Activation, spry: Interpreter): Node =
  ## This is the inner chamber of the heart :)
  spry.pushActivation(current)
  while not current.atEnd:
    let next = current.next()
    # Then we eval the node if it canEval
    if next.canEval(spry):
      current.last = next.eval(spry)
      if current.returned:
        spry.currentActivation.doReturn(spry)
        return current.last
    else:
      current.last = next
  if current.last of Binding:
    current.last = Binding(current.last).val
  spry.popActivation()
  return current.last

method eval(self: Funk, spry: Interpreter): Node =
  newActivation(self).eval(spry)

method eval(self: Paren, spry: Interpreter): Node =
  newActivation(self).eval(spry)

method eval(self: Curly, spry: Interpreter): Node =
  let activation = newActivation(self)
  discard activation.eval(spry)
  return activation.locals

method evalDo(self: Node, spry: Interpreter): Node =
  raiseRuntimeException("Do only works for sequences")

method evalDo(self: Blok, spry: Interpreter): Node =
  newActivation(self).eval(spry)

method evalDo(self: Paren, spry: Interpreter): Node =
  newActivation(self).eval(spry)

method evalDo(self: Curly, spry: Interpreter): Node =
  # Calling do on a curly doesn't do the locals trick
  newActivation(self).eval(spry)

proc evalRootDo*(self: Blok, spry: Interpreter): Node =
  # Evaluate a node in the root activation
  # Ugly... First pop the root activation
  spry.popActivation()
  # This will push it back and... pop it too
  spry.rootActivation.body = self
  spry.rootActivation.pos = 0
  result = spry.rootActivation.eval(spry)
  # ...so we need to put it back
  spry.pushActivation(spry.rootActivation)

method eval(self: Blok, spry: Interpreter): Node =
  self

method eval(self: Value, spry: Interpreter): Node =
  self

method eval(self: Map, spry: Interpreter): Node =
  self

method eval(self: Binding, spry: Interpreter): Node =
  self.val

proc eval*(spry: Interpreter, code: string): Node =
  ## Evaluate code in a new activation
  SeqComposite(newParser().parse(code)).evalDo(spry)

proc evalRoot*(spry: Interpreter, code: string): Node =
  ## Evaluate code in the root activation, presume it is a block
  Blok(newParser().parse(code)).evalRootDo(spry)



when isMainModule and not defined(js):
  # Just run a given file as argument, the hash-bang trick works also
  import os
  let fn = commandLineParams()[0]
  let code = readFile(fn)
  discard newInterpreter().eval("[" & code & "]")




