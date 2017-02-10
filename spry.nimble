[Package]
name          = "spry"
version       = "0.6"
author        = "Göran Krampe"
description   = "Homoiconic dynamic language in Nim"
license       = "MIT"
bin           = "spry,ispry"
srcDir        = "src"
binDir        = "bin"

[Deps]
Requires      = "nim >= 0.16.0, python, ui 0.8, nimsnappy"
