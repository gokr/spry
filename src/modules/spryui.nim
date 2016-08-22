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
    controlDestroy(ControlNode(evalArg(spry)).control)
  nimPrim("show", true):
    let control = ControlNode(evalArgInfix(spry)).control
    controlShow(control)
  nimPrim("hide", true):
    let control = ControlNode(evalArgInfix(spry)).control
    controlHide(control)
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
  nimPrim("onClosing:", true):
    var node = WindowNode(evalArgInfix(spry))
    node.onClosing = Blok(evalArg(spry))
    windowOnClosing(toUiWindow(node.control), onClosing, cast[ptr WindowNode](node))
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
  nimPrim("append:", true):
    var node = MultilineEntryNode(evalArgInfix(spry))
    multilineEntryAppend(cast[ptr MultilineEntry](node.control), StringVal(evalArg(spry)).value.cstring)
  nimPrim("onChanged:", true):
    var node = MultilineEntryNode(evalArgInfix(spry))
    node.onChanged = Blok(evalArg(spry))
    multilineEntryOnChanged(cast[ptr MultilineEntry](node.control), onChanged, cast[ptr MultilineEntryNode](node))

  # Boxes
  nimPrim("newVerticalBox", false):
    BoxNode(control: newVerticalBox(), spry: spry)
  nimPrim("newHorizontalBox", false):
    BoxNode(control: newVerticalBox(), spry: spry)
  nimPrim("append:stretch:", true):
    var node = BoxNode(evalArgInfix(spry))
    var control = ControlNode(evalArg(spry))
    var stretchy = IntVal(evalArg(spry))
    boxAppend(cast[ptr Box](node.control), cast[ptr Control](control.control), stretchy.value.cint)
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
    
