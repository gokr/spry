# Package
version       = "0.7.0"
author        = "Göran Krampe"
description   = "Homoiconic dynamic language in Nim"
license       = "MIT"
bin           = @["spry","ispry"]
srcDir        = "src"
binDir        = "bin"
skipExt       = @["nim"]

# Deps
requires "spryvm"

task test, "Run the tests":
  withDir "tests":
    exec "nim c -r all"
