import spryvm
import sophia

# Spry Sophia module
proc addSophia*(spry: Interpreter) =
  nimFunc("env"):
    # proc env*(): pointer {.cdecl, importc: "sp_env", dynlib: libname.}
    newValue(env())

#proc document*(a2: pointer): pointer {.cdecl, importc: "sp_document", dynlib: libname.}
#proc setstring*(a2: pointer; a3: cstring; a4: pointer; a5: cint): cint {.cdecl,
#    importc: "sp_setstring", dynlib: libname.}
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
