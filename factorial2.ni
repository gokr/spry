#!./ni
# Run with: ./ni factorial.ni

# A recursive factorial
factorial: func [n] [ifelse n > 0 [n * factorial (n - 1)] [1]]

# Do it over and over :)
loop 100000 [factorial 12]
