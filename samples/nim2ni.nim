
import macros
# Note: Since we combine -d:useNimRtl with this module, we cannot use strutils.
# So we use our own helper procs here:

proc toUpper(c: char): char =
  result = if c in {'a'..'z'}: chr(c.ord - 'a'.ord + 'A'.ord) else: c

proc capitalize(s: string): string {.noSideEffect.} =
  result = toUpper(s[0]) & substr(s, 1)

proc invalidFormatString() {.noinline.} =
  raise newException(ValueError, "invalid format string")

proc addf(s: var string, formatstr: string, a: varargs[string, `$`]) =
  ## The same as ``add(s, formatstr % a)``, but more efficient.
  const PatternChars = {'a'..'z', 'A'..'Z', '0'..'9', '\128'..'\255', '_'}
  var i = 0
  var num = 0
  while i < len(formatstr):
    if formatstr[i] == '$':
      case formatstr[i+1] # again we use the fact that strings
                          # are zero-terminated here
      of '#':
        if num >% a.high: invalidFormatString()
        add s, a[num]
        inc i, 2
        inc num
      of '$':
        add s, '$'
        inc(i, 2)
      of '1'..'9', '-':
        var j = 0
        inc(i) # skip $
        var negative = formatstr[i] == '-'
        if negative: inc i
        while formatstr[i] in {'0'..'9'}:
          j = j * 10 + ord(formatstr[i]) - ord('0')
          inc(i)
        let idx = if not negative: j-1 else: a.len-j
        if idx >% a.high: invalidFormatString()
        add s, a[idx]
      else:
        invalidFormatString()
    else:
      add s, formatstr[i]
      inc(i)

proc `%`(formatstr: string, a: openArray[string]): string =
  result = newStringOfCap(formatstr.len + a.len shl 4)
  addf(result, formatstr, a)

proc `%`(formatstr, a: string): string =
  result = newStringOfCap(formatstr.len + a.len)
  addf(result, formatstr, [a])

proc format(formatstr: string, a: varargs[string, `$`]): string =
  result = newStringOfCap(formatstr.len + a.len)
  addf(result, formatstr, a)


const
  pragmaPos = 4
  paramPos = 3
  intType = when sizeof(int) == 8: "longlong" else: "long"
  uintType = when sizeof(int) == 8: "ulonglong" else: "ulong"

var
  dllName {.compileTime.}: string = "SqueakNimTest"
  stCode {.compileTime.}: string = ""
  gPrefix {.compileTime.}: string = ""

template setModulename*(s, prefix: string) =
  ## Sets the DLL name. This is also used to set the 'category' in the generated
  ## classes. 'prefix' is added to every generated class that wraps a Nim
  ## object.
  static:
    dllName = s
    gPrefix = prefix

template writeExternalLibrary*() =
  static:
    addf(stCode, "ExternalLibrary subclass: #$1\C" &
                 "\tinstanceVariableNames: ''\C" &
                 "\tclassVariableNames: ''\C" &
                 "\tpoolDictionaries: ''\C" &
                 "\tcategory: '$2'!\C" &
                 "!$1 class methodsFor: 'primitives' stamp: 'SqueakNim'!\C",
      gPrefix & capitalize(dllName), capitalize(dllName))

template writeSmalltalkCode*(filename: string) =
  ## You need to invoke this template to write the produced Smalltalk code to
  ## a file.
  static:
    writeFile(filename, stCode)

proc mapTypeToC(symbolicType: NimNode; isResultType: bool): string {.compileTime.} =
  if symbolicType.kind == nnkEmpty and isResultType: return "void"
  let t = symbolicType.getType
  if symbolicType.kind == nnkSym and t.typeKind == ntyObject:
    return gPrefix & $symbolicType
  case t.typeKind
  of ntyPtr, ntyVar:
    if t.typeKind == ntyVar and isResultType:
      quit "cannot wrap 'var T' as a result type"
    expectKind t, nnkBracketExpr
    let base = t[1]
    if base.getType.typeKind == ntyArray:
      expectKind base, nnkBracketExpr
      result = mapTypeToC(base[2], isResultType) & "*"
    else:
      result = mapTypeToC(base, isResultType) & "*"
  of ntyArray:
    if isResultType:
      quit "cannot wrap array as a result type"
    expectKind t, nnkBracketExpr
    result = mapTypeToC(t[2], isResultType) & "*"
  of ntyCString: result = "char*"
  of ntyPointer: result = "void*"
  of ntyInt: result = intType
  of ntyInt8: result = "sbyte"
  of ntyInt16: result = "short"
  of ntyInt32: result = "long"
  of ntyInt64: result = "longlong"
  of ntyUInt: result = uintType
  of ntyUInt8: result = "ubyte"
  of ntyUInt16: result = "ushort"
  of ntyUInt32: result = "ulong"
  of ntyUInt64: result = "ulonglong"
  of ntyFloat, ntyFloat64: result = "double"
  of ntyFloat32: result = "float"
  of ntyBool, ntyChar, ntyEnum: result = "char"
  else: quit "Error: cannot wrap to Squeak " & treeRepr(t)

macro exportSt*(body: stmt): stmt =
  # generates something like:

  # system: aString
  #"Some kind of comment"
  #
  #   <apicall: long 'system' (char*) module: 'libSystem.dylib'>
  #   ^self externalCallFailed.
  result = body
  result[pragmaPos].add(ident"exportc", ident"dynlib", ident"cdecl")
  let params = result[paramPos]
  let procName = $result[0]
  var st = procName
  #echo treeRepr params
  if params.len > 1:
    expectKind params[1], nnkIdentDefs
    let ident = $params[1][0]
    if ident.len > 1:
      st.add(ident.capitalize & ": " & ident)
    else:
      st.add(": " & ident)
  # return type:
  var apicall = "<cdecl: " & mapTypeToC(params[0], true) & " '" &
               procName & "' ("
  var counter = 0
  # parameter types:
  for i in 1.. <params.len:
    let param = params[i]
    let L = param.len
    for j in 0 .. param.len-3:
      let name = param[j]
      let typ = param[L-2]
      if counter > 0:
        apicall.add(" ")
        st.addf(" $1: $1", name)
      apicall.add(mapTypeToC(typ, false))
      inc counter
  apicall.add(") module: '" & dllName & "'>\C" &
              "\t^self externalCallFailed\C!\C\C")
  stCode.add(st & "\C\t\"Generated by NimSqueak\"\C\t" & apicall)

macro wrapObject*(typ: stmt; wrapFields=false): stmt =
  ## Declares a Smalltalk wrapper class.
  var t = typ.getType()
  if t.typeKind == ntyTypeDesc:
    expectKind t, nnkBracketExpr
    t = t[1]
  expectKind t, nnkSym
  let name = gPrefix & ($t).capitalize
  if t.kind != nnkObjectTy: t = t.getType
  expectKind t, nnkObjectTy
  t = t[1]
  expectKind t, nnkRecList
  var fields = ""
  if $wrapFields == "true":
    for i in 0.. < t.len:
      expectKind t[i], nnkSym
      fields.addf "\t\t($# '$#')\C", $t[i], mapTypeToC(t[i], false)

  let st = ("ExternalStructure subclass: #$1\C" &
    "\tinstanceVariableNames: ''\C" &
    "\tclassVariableNames: ''\C" &
    "\tpoolDictionaries: 'FFIConstants'\C" &
    "\tcategory: '$2'!\C\C" &
    "$1 class\C" &
    "\tinstanceVariableNames: ''!\C\C" &
    "!$1 class methodsFor: 'field definition' stamp: 'SqueakNim'!\C" &
    "\tfields\C" &
    "\t^#(\C" &
    "$3\C" &
    "\t)! !\C" &
    "$1 defineFields.\C!\C\C") % [name, capitalize(dllName), fields]
  stCode.add(st)
  result = newStmtList()
