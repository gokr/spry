[Package]
name          = "ni"
version       = "0.1"
author        = "Göran Krampe"
description   = "Rebol-ish dynamic language in Nim"
license       = "MIT"
bin           = "ni,nirepl"

srcDir        = "src"
binDir        = "bin"

[Deps]
Requires      = "nim >= 0.11.2, python"
