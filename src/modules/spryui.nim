import spryvm

import ui

type
  ControlNode = ref object of Value
    control*: ptr Control
    spry*: Interpreter # We send a pointer to the Window along with callbacks
  WindowNode* = ref object of ControlNode
    onClosing*: Blok   # Blok to run onClosing event
  MultilineEntryNode = ref object of ControlNode
    onChanged*: Blok
  BoxNode = ref object of ControlNode
  ButtonNode = ref object of ControlNode
    onClicked*: Blok

# Useful during playing around with this
method type*(self: ControlNode): string =
  "ControlNode"
method `$`*(self: WindowNode): string =
  "WindowNode"
method `$`*(self: MultilineEntryNode): string =
  "MultilineEntryNode"
method `$`*(self: BoxNode): string =
  "BoxNode"
method `$`*(self: ButtonNode): string =
  "ButtonNode"

method eval*(self: ControlNode, spry: Interpreter): Node =
  self

# Handlers
proc onClosing*(w: ptr Window; data: pointer): cint {.cdecl.} =
  var node = cast[WindowNode](data)
  discard node.onClosing.evalDo(node.spry)
  return 0 #?

proc onChanged*(w: ptr MultilineEntry; data: pointer) {.cdecl.} =
  var node = cast[MultilineEntryNode](data)
  discard node.onChanged.evalDo(node.spry)

proc onClicked*(w: ptr Button; data: pointer) {.cdecl.} =
  var node = cast[ButtonNode](data)
  discard node.onClicked.evalDo(node.spry)



# Spry UI module
proc addUI*(spry: Interpreter) =
  # libui
  nimPrim("uiInit", false):
    var o: ui.InitOptions
    var err: cstring
    err = ui.init(addr(o))
    if err != nil:
      echo "error initializing ui: ", err
      freeInitError(err)
      return
  nimPrim("uiMain", false):
    ui.main()
  nimPrim("uiQuit", false):
    ui.quit()
  nimPrim("uiUninit", false):
    ui.uninit()

  # Controls
  nimPrim("controlDestroy", false):
    let node = ControlNode(evalArg(spry))
    controlDestroy(node.control)
    return spry.nilVal
  nimPrim("show", true):
    let node = ControlNode(evalArgInfix(spry))
    controlShow(node.control)
    return node
  nimPrim("hide", true):
    let node = ControlNode(evalArgInfix(spry))
    controlHide(node.control)
    return node
  nimPrim("setChild:", false):
    let win = WindowNode(evalArgInfix(spry))
    let node = ControlNode(evalArg(spry))
    windowSetChild(cast[ptr Window](win.control), node.control)
    return win

  # Window
  nimPrim("newWindow", false):
    let title = StringVal(evalArg(spry)).value
    let width = IntVal(evalArg(spry)).value
    let height = IntVal(evalArg(spry)).value
    let bar = if BoolVal(evalArg(spry)).value: 1 else: 0
    result = WindowNode(control: newWindow(title.cstring, width.cint, height.cint, bar.cint), spry: spry)
  nimPrim("margin:", true):
    var node = WindowNode(evalArgInfix(spry))
    let margin = IntVal(evalArg(spry)).value
    windowSetMargined(toUiWindow(node.control), margin.cint)
    return node
  nimPrim("onClosing:", true):
    var node = WindowNode(evalArgInfix(spry))
    node.onClosing = Blok(evalArg(spry))
    windowOnClosing(toUiWindow(node.control), onClosing, cast[ptr WindowNode](node))
    return node
  nimPrim("message:title:", true):
    var win = WindowNode(evalArgInfix(spry))
    let description = StringVal(evalArg(spry)).value
    let title = StringVal(evalArg(spry)).value
    msgBox(toUiWindow(win.control), title.cstring, description.cstring)
    return win
  nimPrim("error:title:", true):
    var win = WindowNode(evalArgInfix(spry))
    let description = StringVal(evalArg(spry)).value
    let title = StringVal(evalArg(spry)).value
    msgBoxError(toUiWindow(win.control), title.cstring, description.cstring)
    return win


  # MultilineEntry
  nimPrim("newMultilineEntryText", false):
    MultilineEntryNode(control: newMultilineEntry(), spry: spry)
  nimPrim("text", true):
    var node = MultilineEntryNode(evalArgInfix(spry))
    newValue($(multilineEntryText(cast[ptr MultilineEntry](node.control))))
  nimPrim("text:", true):
    var node = MultilineEntryNode(evalArgInfix(spry))
    multilineEntrySetText(cast[ptr MultilineEntry](node.control), StringVal(evalArg(spry)).value.cstring)
    return node
  nimPrim("append:", true):
    var node = MultilineEntryNode(evalArgInfix(spry))
    multilineEntryAppend(cast[ptr MultilineEntry](node.control), StringVal(evalArg(spry)).value.cstring)
    return node
  nimPrim("onChanged:", true):
    var node = MultilineEntryNode(evalArgInfix(spry))
    node.onChanged = Blok(evalArg(spry))
    multilineEntryOnChanged(cast[ptr MultilineEntry](node.control), onChanged, cast[ptr MultilineEntryNode](node))
    return node

  # Boxes
  nimPrim("newVerticalBox", false):
    BoxNode(control: newVerticalBox(), spry: spry)
  nimPrim("newHorizontalBox", false):
    BoxNode(control: newHorizontalBox(), spry: spry)
  nimPrim("append:stretch:", true):
    var node = BoxNode(evalArgInfix(spry))
    var control = ControlNode(evalArg(spry))
    var stretchy = IntVal(evalArg(spry))
    boxAppend(cast[ptr Box](node.control), cast[ptr Control](control.control), stretchy.value.cint)
    return node
  nimPrim("delete:", true):
    var node = BoxNode(evalArgInfix(spry))
    var index = IntVal(evalArg(spry))
    boxDelete(cast[ptr Box](node.control), index.value.cuint)
    return node
  nimPrim("padding", true):
    var node = BoxNode(evalArgInfix(spry))
    return newValue(int(boxPadded(cast[ptr Box](node.control))))
  nimPrim("padding:", true):
    var node = BoxNode(evalArgInfix(spry))
    let padding = IntVal(evalArg(spry)).value
    boxSetPadded(cast[ptr Box](node.control), padding.cint)
    return node

  # Buttons
  nimPrim("newButton", false):
    let label = StringVal(evalArg(spry)).value
    ButtonNode(control: newButton(label.cstring), spry: spry)
  nimPrim("onClicked:", true):
    var node = ButtonNode(evalArgInfix(spry))
    node.onClicked = Blok(evalArg(spry))
    buttonOnClicked(cast[ptr Button](node.control), onClicked, cast[ptr ButtonNode](node))
    return node
    
