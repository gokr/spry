import ni, niparser
# Example extending Ni with multiline string literals similar to Nim but using
# triple single quotes ''' ... ''' and no skipping whitespace/newline after
# the first delimiter. Its just an example, adding support for """ was harder
# since it intervenes with the existing simple support for normal "strings".
#
# We also add a word "reduce" implemented in Nim. See nitest.nim for some
# trivial tests demonstrating that you can then extend ni by simply importing
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

## Register our extension proc above in Ni so it gets called
addParserExtension(extendParser)


#######################################################################
# Extending the Interpreter with a Nim primitive word
#######################################################################

proc evalReduce(self: SeqComposite, ni: Interpreter): Node =
  ## Evaluate all nodes in the block and return a new block with all results
  var collect = newSeq[Node]()
  let current = newActivation(Blok(self))
  ni.pushActivation(current)
  while not current.atEnd:
    let next = current.next()
    # Then we eval the node if it canEval
    if next.canEval(ni):
      current.last = next.eval(ni)
      if current.returned:
        ni.currentActivation.doReturn(ni)
        return current.last
      collect.add(current.last)
    else:
      current.last = next
  ni.popActivation()
  return newBlok(collect)


# This is a primitive we want to add, like do but calling proc above
proc primReduce*(ni: Interpreter): Node =
  SeqComposite(evalArg(ni)).evalReduce(ni)

# This proc does the work extending an Interpreter instance
proc extendInterpreter(ni: Interpreter) {.procvar.} =
  ni.root.makeWord("reduce", newNimProc(primReduce, false, 1))
  
## Register our extension proc in Ni so it gets called every time a new
## Interpreter is instantiated
addInterpreterExtension(extendInterpreter)

