#!/usr/bin/env python
import time

t0 = time.time()

blk = []
for i in range(1,400001):
  blk.append(i)

t1 = time.time()
total = t1-t0
print "Total populating: " + str(total)
print "Block of size: " + str(len(blk))

t0 = time.time()
sum1 = sum(blk)
t1 = time.time()
total = t1-t0

print "Total sum function: " + str(total)
print "Sum: " + str(sum1)

t0 = time.time()
sum2 = 0
for x in blk:
  sum2 = sum2 + x
t1 = time.time()
total = t1-t0

print "Total for loop: " + str(total)
print "Sum: " + str(sum2)

t0 = time.time()
sum2 = 0
sum2 = reduce(lambda x, y: x + y, blk)
t1 = time.time()
total = t1-t0


print "Total lambda loop: " + str(total)
print "Sum: " + str(sum2)

