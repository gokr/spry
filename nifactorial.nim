# nifactorial
import ni

# Cool if this could be a const :) but that actually fails
var prog = newParser().parse("""
  factorial: [ifelse gt n 1 [f: mul f n n: sub n 1 do factorial] [f]]
  loop 1000000 [
    f: 1 n: 15
    do factorial]
  echo f
  """)

discard newInterpreter().doBlock(prog)
