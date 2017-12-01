# Package
version       = "0.6.1"
author        = "Göran Krampe"
description   = "Homoiconic dynamic language in Nim"
license       = "MIT"
bin           = @["spry","ispry"]
srcDir        = "src"
binDir        = "bin"

# Deps
requires "nim >= 0.17.0"
requires "python"
requires "ui"
requires "nimsnappy"

when defined(nimdistros):
  import distros
  if detectOs(Ubuntu):
    foreignDep "libsnappy-dev"
  elif detectOs(MacOSX):
    foreignDep "snappy"
  elif detectOs(Windows):
    foreignDep "snappy"

task test, "Run the tests":
  withDir "tests":
    exec "nim c -r all"
