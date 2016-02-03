# Ni Language REPL
#
# Copyright (c) 2015 Göran Krampe

# I am not fond of REPLs, since I think they are silly dumb approximations
# of the real thing - a fully live environment like Smalltalk.
#
# But ok, its nice as a starter and for going through a tutorial :)
# And this one is minimalistic intentionally, and... we should add enough
# to Ni itself so that it can be written fully in Ni.

# Stuff the REPL needs
import os, strutils

# Basic Ni
import nivm, niparser

# Ni extra modules
import niextend, nimath, nios, niio, nithread, nipython, nidebug

proc main() =
  # Let's create a Ni interpreter. It also holds all state.
  let ni = newInterpreter()
  ni.addExtend()
  ni.addMath()
  ni.addOS()
  ni.addIO()
  ni.addThread()
  ni.addPython()
  ni.addDebug()

  var
    lines, stashed, fileLines = newSeq[string]()
    suspended: bool = true
 
  # Check if a file was given as input, if so collect lines
  # and set suspended = false which means we start out following the given
  # script instead of interactively.
  if commandLineParams().len > 0:
    let fn = commandLineParams()[0]
    if fn.len() > 0:
      suspended = false
      for line in lines(fn):
        fileLines.add(line)

  echo "We are the knights who say... Ni! Enter shrubbary... eh, code and"
  echo "an empty line will evaluate previous lines, so hit enter twice."
  # We collect lines until an empty line is entered, easy way to enter
  # multiline code.

  while true:
    var line: string
    if suspended:
      stdout.write(">>> ")
      line = stdin.readLine()
    else:
      if fileLines.len == 0:
        quit 0
      # Read a line, eh, would be nice with removeFirst or popFirst...
      line = fileLines[0]
      fileLines.delete(0)
      # Logic for pausing
      if line.strip() == "# pause":
        stdout.write("         <Hit enter to eval or s = suspend>\n")
        var enter = stdin.readLine()
        if enter.strip() == "s":
          stdout.write("         <Suspended, c = continue>\n")
          stashed = lines
          lines = newSeq[string]()
          suspended = true
        continue
      else:
        stdout.write(line & "\n")

    # Logic to start the script again    
    if suspended and line.strip() == "c":
      lines = stashed
      suspended = false
      continue
    
    # Finally time to eval
    if line.strip().len() == 0:
      let code = lines.join("\n")
      lines = newSeq[string]()
      try:
        # Let the interpreter eval the code
        var output = $ni.evalRoot(code)
        # Print any result
        if output.isNil:
          output = if suspended: "nil" else: ""
        stdout.write(output & "\n")
      except:
        echo "Oops, sorry about that: " & getCurrentExceptionMsg() & "\n"
        echo getStackTrace()
    else:
      lines.add(line)

main()
