# Test all test files to see if they work for nodejs
for f in spry*test.nim
do
  nim js -d:nodejs -r $f
done

