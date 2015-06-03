# Trivial example of embedded Ni factorial
import ni

discard newInterpreter().eval """
  f: 1 n: 20
  factorial: [ifelse (n > 1) [f: (f * n) n: (n - 1) do factorial] [f]]
  loop 100000 [
    f: 1 n: 20
    do factorial]
  echo f
  """
