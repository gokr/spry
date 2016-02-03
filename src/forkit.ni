# This is called a block in Ni. It is like an OrderedCollection.
# At this point the block is just a series of nested words and literals.
# Assignment is actually an infix function!
code = [
  # This is a local function to recursively calculate factorial.
  # ifelse is currently a 3-argument prefix function, but Ni could use
  # Smalltalk syntax for that too.

  factorial = func [
    # Arguments are sucked in as we go, so no need to declare n first
    ifelse (:n > 0)
      [n * factorial (n - 1)]
      [1]
  ]
  # Echo is a prefix function.
  echo factorial 1
]

# Ni has keyword messages that can take the first argument from the left.
# Ni also has closures and non local returns so we can implement Smalltalkish
# control structures and things like select: or reject: easily. Or we can write
# them as Nim primitive functions.
10 timesRepeat: [
  # Ni is homoiconic so we can modify the block as if it is code.
  # We remove the last element of the code block (the number) and add
  # a random number from 1-20.
  code removeLast

  # In Ni the parenthesis is currently needed, evaluation is strict from left to right.
  code add: (20 random)

  # Spawn fires upp a native thread from a threadpool and
  # inside that thread a new fresh interpreter is created.
  # Spawn will deep copy the Ni node being passed and will
  # then run it as code in the new interpreter.
  # Currently the result value is not handled.
  spawn code
]
echo "Spawned off 10 threads"

# Sleeping this thread to wait for the 10 above
sleep 1000
echo "Done sleeping, bye"
