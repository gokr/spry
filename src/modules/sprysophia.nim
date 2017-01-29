import spryvm
import sophia

type
    SophiaNode = ref object of PointerVal
    SophiaEnvironmentNode = ref object of SophiaNode
    SophiaObjectNode = ref object of SophiaNode
    SophiaDocumentNode = ref object of SophiaNode

method `$`*(self: SophiaNode): string =
  "SophiaNode"
method `$`*(self: SophiaEnvironmentNode): string =
  "SophiaEnvironmentNode"
method `$`*(self: SophiaObjectNode): string =
  "SophiaObjectNode"
method `$`*(self: SophiaDocumentNode): string =
  "SophiaDocumentNode"

method eval*(self: SophiaNode, spry: Interpreter): Node =
  self

proc free(obj: pointer) {.importc: "free", header: "<stdio.h>"}

proc toString(p: pointer): string =
  result = $(cast[ptr cstring](p)[])
  free(p)

# Spry Sophia module
proc addSophia*(spry: Interpreter) =
  nimFunc("newEnvironment"):
    # proc env*(): pointer {.cdecl, importc: "sp_env", dynlib: libname.}
    SophiaEnvironmentNode(value: env())
  nimFunc("openEnvironment"):
    let env = SophiaEnvironmentNode(evalArgInfix(spry)).value
    newValue(open(env).int)
  nimMeth("getObject:"):
    let env = SophiaEnvironmentNode(evalArgInfix(spry)).value
    let key = StringVal(evalArg(spry)).value
    SophiaObjectNode(value: env.getobject(key.cstring))
  nimMeth("newDocument"):
    let db = SophiaObjectNode(evalArgInfix(spry)).value
    SophiaDocumentNode(value: document(db))
  nimMeth("setString:to:"):
    let docOrEnv = PointerVal(evalArgInfix(spry)).value
    let key = StringVal(evalArg(spry)).value
    let val = print(evalArg(spry))
    newValue(docOrEnv.setstring(key.cstring, val.cstring, 0).int)
  nimMeth("setInt:to:"):
    let docOrEnv = PointerVal(evalArgInfix(spry)).value
    let key = StringVal(evalArg(spry)).value
    let val = IntVal(evalArg(spry)).value
    newValue(docOrEnv.setint(key.cstring, val.int64).int)
  nimMeth("getString:"):
    let docOrEnv = PointerVal(evalArgInfix(spry)).value
    let key = StringVal(evalArg(spry)).value
    var size: cint # we don't use it, just pass it along
    var p = docOrEnv.getstring(key.cstring, addr size)
    echo "size:" & $size
    let res = toString(p)
    newValue(res)
  nimMeth("getInt:"):
    let docOrEnv = PointerVal(evalArgInfix(spry)).value
    let key = StringVal(evalArg(spry)).value
    let res = docOrEnv.getint(key.cstring).int
    newValue(res)
  nimMeth("destroy"):
    let target = PointerVal(evalArgInfix(spry)).value
    let res = target.destroy().int
    newValue(res)
  nimMeth("set:"):
    let db = SophiaObjectNode(evalArgInfix(spry)).value
    let doc = SophiaDocumentNode(evalArg(spry)).value
    let res = db.set(doc)
    newValue(res)
  nimMeth("get:"):
    let db = SophiaObjectNode(evalArgInfix(spry)).value
    let doc = SophiaDocumentNode(evalArg(spry)).value
    let res = db.get(doc)
    newValue(res)

#proc destroy*(a2: pointer): cint {.cdecl, importc: "sp_destroy", dynlib: libname.}

#proc setint*(a2: pointer; a3: cstring; a4: int64): cint {.cdecl, importc: "sp_setint",
#    dynlib: libname.}
#proc getobject*(a2: pointer; a3: cstring): pointer {.cdecl, importc: "sp_getobject",
#    dynlib: libname.}
#proc getstring*(a2: pointer; a3: cstring; a4: ptr cint): pointer {.cdecl,
#    importc: "sp_getstring", dynlib: libname.}
#proc getint*(a2: pointer; a3: cstring): int64 {.cdecl, importc: "sp_getint",
#    dynlib: libname.}
#proc open*(a2: pointer): cint {.cdecl, importc: "sp_open", dynlib: libname.}
#proc destroy*(a2: pointer): cint {.cdecl, importc: "sp_destroy", dynlib: libname.}
#proc error*(a2: pointer): cint {.cdecl, importc: "sp_error", dynlib: libname.}
#proc service*(a2: pointer): cint {.cdecl, importc: "sp_service", dynlib: libname.}
#proc poll*(a2: pointer): pointer {.cdecl, importc: "sp_poll", dynlib: libname.}
#proc drop*(a2: pointer): cint {.cdecl, importc: "sp_drop", dynlib: libname.}
#proc set*(a2: pointer; a3: pointer): cint {.cdecl, importc: "sp_set", dynlib: libname.}
#proc upsert*(a2: pointer; a3: pointer): cint {.cdecl, importc: "sp_upsert",
#    dynlib: libname.}
#proc delete*(a2: pointer; a3: pointer): cint {.cdecl, importc: "sp_delete",
#    dynlib: libname.}
#proc get*(a2: pointer; a3: pointer): pointer {.cdecl, importc: "sp_get", dynlib: libname.}
#proc cursor*(a2: pointer): pointer {.cdecl, importc: "sp_cursor", dynlib: libname.}
#proc begin*(a2: pointer): pointer {.cdecl, importc: "sp_begin", dynlib: libname.}
#proc prepare*(a2: pointer): cint {.cdecl, importc: "sp_prepare", dynlib: libname.}
#proc commit*(a2: pointer): cint {.cdecl, importc: "sp_commit", dynlib: libname.}
