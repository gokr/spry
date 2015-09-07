# Python program to find the factorial of a number using recursion

def factorial(n):
  if n > 0:
    return n * factorial(n-1)
  else:
    return 1

for x in range(0, 100000):
  factorial(12)
