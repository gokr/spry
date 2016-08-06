import spryvm

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

proc dump(spry: Interpreter) =
  echo "STACK:"
  for a in spry.stack:
    dump(a)
    echo "-----------------------------"
  echo "========================================"


# Spry debug module
proc addDebug*(spry: Interpreter) =
  nimPrim("dump", false):    dump(spry)
  when not defined(js): # There is no repr support in js backend
    nimPrim("repr", false):  newValue(repr(evalArg(spry)))
