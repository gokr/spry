#!./ni
# Run with: ./ni factorial.ni

# These need to be here actually, not sure why yet, its not enough to call reset...
n: 20
f: 1

# A recursive factorial block but n and f are in root context
factorial: func [ifelse n > 1 [f: f * n n: n - 1 factorial] [f]]

# Do it over and over :)
loop 100000 [n: 20 f: 1 factorial]

# Just show the last answer
echo f
