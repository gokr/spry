import nivm, niparser

# Textual dump for debugging
method dump(self: Activation) {.base.} =
  echo "ACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]

method dump(self: ParenActivation) =
  echo "PARENACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]

method dump(self: CurlyActivation) =
  echo "CURLYACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]

method dump(self: FunkActivation) =
  echo "FUNKACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]
  echo($self.locals)

method dump(self: BlokActivation) =
  echo "BLOKACTIVATION"
  echo($self.body)
  if self.pos < self.len:
    echo "POS(" & $self.pos & "): " & $self.body[self.pos]
  echo($self.locals)
  
proc dump(ni: Interpreter) =
  echo "STACK:"
  for a in ni.stack:
    dump(a)
    echo "-----------------------------"
  echo "========================================"


# Ni debug module
proc addDebug*(ni: Interpreter) =
  nimPrim("dump", false, 0):    dump(ni)
  when not defined(js): # There is no repr support in js backend
    nimPrim("repr", false, 1):  newValue(repr(evalArg(ni)))
