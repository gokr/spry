#!./ni
# Run with: ./ni factorial.ni

# A recursive factorial
factorial = func [ifelse (:n > 0) [n * factorial (n - 1)] [1]]

# Do it over and over :)
100000 timesRepeat: [factorial 12]
echo (factorial 12)
