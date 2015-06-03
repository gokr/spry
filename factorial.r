Gurka
Rebol []

factorial: func [n][
  either n > 1 [n * factorial n - 1] [1]
]

loop 100000 [factorial 20]
print factorial 20
