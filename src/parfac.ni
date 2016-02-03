# Parallell factorial benchmark. Need to fix so that
# we can await on spawned jobs, right now we don't know
# when they are done.
foo = func [
  factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]
  100000 timesRepeat: [factorial 12]
  echo "thread done"
]
5 timesRepeat: [spawn ^foo]
echo "Started all"
sleep 5000


