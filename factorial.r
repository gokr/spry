Gurka
Rebol []

factorial: func [n][
  either n > 0 [n * factorial n - 1] [1]
]

loop 100000 [factorial 12]
