#!/usr/bin/nodejs

console.time("populate")
blk = []
for(i = 1; i<=400000;i++) {
  blk.push(i)
}
console.timeEnd("populate")

console.log("Block of size: " + blk.length)

console.time("Sum using loop")
function ff(blk) {
  var sum1 = 0
  for (each of blk) {
    sum1 += each
  }
  return sum1
}
sum1 = ff(blk)
console.timeEnd("Sum using loop")

console.log("Sum:" + sum1)

console.time("Sum using reduce")
var sum2 = blk.reduce((a, b) => a + b, 0)
console.timeEnd("Sum using reduce")

console.log("Sum: " + sum2)

