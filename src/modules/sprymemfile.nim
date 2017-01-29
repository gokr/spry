import spryvm

import memfiles

type MemfileNode* = ref object of Value
  memfile*: Memfile

method eval*(self: MemfileNode, spry: Interpreter): Node =
  self

# Spry Memfile module
proc addMemfile*(spry: Interpreter) =
  # IO
  nimFunc("openMemfile"):
    let path = StringVal(evalArg(spry)).value
    result = MemfileNode(memfile: memfiles.open(path))
  nimMeth("closeMemfile"):
    let node = MemfileNode(evalArgInfix(spry))
    memfiles.close(node.memfile)
  nimFunc("readLines"):
    let path = StringVal(evalArg(spry)).value
    var memfile = memfiles.open(path)
    result = newBlok()
    for line in lines(memfile):
      Blok(result).add(StringVal(value: string(line)))
    memfiles.close(memfile)
  nimMeth("linesDo:"):
    result = MemfileNode(evalArgInfix(spry))
    let memfile = MemfileNode(result).memfile
    let blk = Blok(evalArg(spry))
    # Ugly hack for now, we trick the activation into holding each in pos 0
    let current = spry.currentActivation
    let orig = current.body.nodes[0]
    let oldpos = current.pos
    current.pos = 0
    let activation = newActivation(blk)
    for line in lines(memfile):
      current.body.nodes[0] = StringVal(value: string(line))
      discard activation.eval(spry)
      activation.reset()
      current.pos = 0
      # Or else non local returns don't work :)
      if current.returned:
        # Reset our trick
        current.body.nodes[0] = orig
        current.pos = oldpos
        return current.last
    # Reset our trick
    current.body.nodes[0] = orig
    current.pos = oldpos
