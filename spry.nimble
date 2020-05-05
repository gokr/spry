# Package
version       = "0.9.0"
author        = "Göran Krampe"
description   = "Homoiconic dynamic language in Nim"
license       = "MIT"
bin           = @["spry","ispry"]
srcDir        = "src"
binDir        = "bin"
skipExt       = @["nim"]

# Deps
requires "spryvm"

