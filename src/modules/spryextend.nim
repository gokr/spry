import spryvm
# Example extending Spry with multiline string literals similar to Nim but using
# triple single quotes ''' ... ''' and no skipping whitespace/newline after
# the first delimiter. Its just an example, adding support for """ was harder
# since it intervenes with the existing simple support for normal "strings".
#
# We also add a word "reduce" implemented in Nim. See nitest.nim for some
# trivial tests demonstrating that you can then extend Spry by simply importing
# this module, which then will automatically extend any created Interpreter.


#######################################################################
# Extending the Parser with multiline string literals using ''' ... '''
#######################################################################
type
  MultilineStringValueParser = ref object of ValueParser

method parseValue(self: MultilineStringValueParser, s: string): Node {.procvar.} =
  # If it ends and starts with ''' then ok, no escapes yet
  if s[0..2] == "'''" and s[^3..^1] == "'''":
    result = newValue(s[3..^4])

proc prefixLength(self: MultilineStringValueParser): int = 3

method tokenStart(self: ValueParser, s: string, c: char): bool =
  s == "''" and c == '\''

method tokenReady(self: MultilineStringValueParser, token: string, c: char): string =
  if c == '\'' and token.len > 4 and token[^2..^1] == "''":
    return token & c
  else:
    return nil

# This proc does the work extending the Parser instance
proc extendParser(p: Parser) {.procvar.} =
  p.valueParsers.add(MultilineStringValueParser())

## Register our extension proc above in Spry so it gets called
addParserExtension(extendParser)


#######################################################################
# Extending the Interpreter with a Nim primitive word
#######################################################################

proc evalReduce(self: SeqComposite, spry: Interpreter): Node =
  ## Evaluate all nodes in the block and return a new block with all results
  var collect = newSeq[Node]()
  let current = newActivation(Blok(self))
  spry.pushActivation(current)
  while not current.atEnd:
    let next = current.next()
    # Then we eval the node if it canEval
    if next.canEval(spry):
      current.last = next.eval(spry)
      if current.returned:
        spry.currentActivation.doReturn(spry)
        return current.last
      collect.add(current.last)
    else:
      current.last = next
  spry.popActivation()
  return newBlok(collect)


# This is a primitive we want to add, like do but calling proc above
proc primReduce*(spry: Interpreter): Node =
  SeqComposite(evalArg(spry)).evalReduce(spry)

# This proc does the work extending an Interpreter instance
proc addExtend*(spry: Interpreter) =
  spry.makeWord("reduce", newPrimFunc(primReduce))

