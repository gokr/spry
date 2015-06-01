factorial: [ifelse gt n 1 [f: mul f n n: sub n 1 do factorial] [f]]
loop 1000000 [
  f: 1 n: 15
  do factorial]
echo f

