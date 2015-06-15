# Ni Language REPL
#
# Copyright (c) 2015 Göran Krampe

# I am not fond of REPLs, since I think they are silly dumb approximations
# of the real thing - a fully live environment like Smalltalk.
#
# But ok, its nice as a starter and for going through a tutorial :)
# And this one is minimalistic intentionally, and... we should add enough
# to Ni itself so that it can be written fully in Ni.

import os, strutils
import ni, niparser, extend

proc main() =
  # Let's create a Ni interpreter. It also holds all state.
  let ni = newInterpreter()
  var
    lines, stashed = newSeq[string]()
    fileLines = newSeq[string]()
    suspended: bool = true
 
  # Check if a file was given as input
  if commandLineParams().len > 0:
    let fn = commandLineParams()[0]
    if fn.len() > 0:
      suspended = false
      for line in lines(fn):
        fileLines.add(line)

  echo "Welcome to Ni! Enter code, an empty line will evaluate previous lines"
  # We collect lines until an empty line is entered, easy way to enter
  # multiline code.

  while true:
    var line: string
    if suspended:
      line = stdin.readLine()
    else:
      if fileLines.len == 0:
        echo "Good bye"
        quit 0
      line = fileLines[0]
      fileLines.delete(0)
      if line.strip() == "# pause":
        stdout.write("         <Hit enter to eval or s = suspend>")
        var enter = stdin.readLine()
        if enter.strip() == "s":
          stdout.write("         <Suspended, c = continue>\n")
          stashed = lines
          lines = newSeq[string]()
          suspended = true
        continue
      else:
        stdout.write(line & "\n")
    
    if suspended and line.strip() == "c":
      lines = stashed
      suspended = false
      continue
      
    if line.strip().len() == 0:
      let code = lines.join("\n")
      lines = newSeq[string]()
      try:
        # Let the interpreter eval the code
        var output = $ni.eval(code)
        # Print any result
        if output.isNil:
          output = if suspended: "nil" else: ""
        stdout.write(output & "\n")
      except:
        echo "Oops, sorry about that: " & getCurrentExceptionMsg() & "\n"
    else:
      lines.add(line)

main()
