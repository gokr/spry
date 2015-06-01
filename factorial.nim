proc factorial(n: int64) :int64 =
  if n > 1:
    n * factorial(n-1)
  else:
    1

var x: int64
for i in 1 .. 10000000000:
  x = factorial(15)

echo($x)
