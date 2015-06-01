Gurka
Rebol []

factorial: func [n][
  either n > 1 [n * factorial n - 1] [1]
]

loop 1000000 [factorial 15]
print factorial 15
