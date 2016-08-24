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
  GroupNode = ref object of ControlNode
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
method `$`*(self: GroupNode): string =
  "GroupNode"
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
  nimFunc("uiInit"):
    var o: ui.InitOptions
    var err: cstring
    err = ui.init(addr(o))
    if err != nil:
      echo "error initializing ui: ", err
      freeInitError(err)
      return
  nimFunc("uiMain"):
    ui.main()
  nimFunc("uiQuit"):
    ui.quit()
  nimFunc("uiUninit"):
    ui.uninit()

  # Controls
  nimFunc("controlDestroy"):
    let node = ControlNode(evalArg(spry))
    controlDestroy(node.control)
    return spry.nilVal
  nimMeth("show"):
    let node = ControlNode(evalArgInfix(spry))
    controlShow(node.control)
    return node
  nimMeth("hide"):
    let node = ControlNode(evalArgInfix(spry))
    controlHide(node.control)
    return node

  # Window
  nimFunc("newWindow"):
    let title = StringVal(evalArg(spry)).value
    let width = IntVal(evalArg(spry)).value
    let height = IntVal(evalArg(spry)).value
    let bar = if BoolVal(evalArg(spry)).value: 1 else: 0
    result = WindowNode(control: newWindow(title.cstring, width.cint, height.cint, bar.cint), spry: spry)
  nimMeth("windowMargin:"):
    var node = WindowNode(evalArgInfix(spry))
    let margin = IntVal(evalArg(spry)).value
    windowSetMargined(toUiWindow(node.control), margin.cint)
    return node
  nimMeth("onClosing:"):
    var node = WindowNode(evalArgInfix(spry))
    node.onClosing = Blok(evalArg(spry))
    windowOnClosing(toUiWindow(node.control), onClosing, cast[ptr WindowNode](node))
    return node
  nimMeth("message:title:"):
    var win = WindowNode(evalArgInfix(spry))
    let description = StringVal(evalArg(spry)).value
    let title = StringVal(evalArg(spry)).value
    msgBox(toUiWindow(win.control), title.cstring, description.cstring)
    return win
  nimMeth("error:title:"):
    var win = WindowNode(evalArgInfix(spry))
    let description = StringVal(evalArg(spry)).value
    let title = StringVal(evalArg(spry)).value
    msgBoxError(toUiWindow(win.control), title.cstring, description.cstring)
    return win
  nimFunc("windowSetChild:"):
    let win = WindowNode(evalArgInfix(spry))
    let node = ControlNode(evalArg(spry))
    windowSetChild(cast[ptr Window](win.control), node.control)
    return win

   # Groups
  nimFunc("newGroup"):
    let title = StringVal(evalArg(spry)).value
    GroupNode(control: newGroup(title.cstring), spry: spry)
  nimFunc("groupSetChild:"):
    let group = GroupNode(evalArgInfix(spry))
    let node = ControlNode(evalArg(spry))
    groupSetChild(toUiGroup(group.control), node.control)
    return group
  nimMeth("groupMargin:"):
    var node = GroupNode(evalArgInfix(spry))
    var margin = IntVal(evalArg(spry))
    groupSetMargined(toUiGroup(node.control), margin.value.cint)
    return node
  nimMeth("title"):
    var node = GroupNode(evalArgInfix(spry))
    return newValue($(groupTitle(toUiGroup(node.control))))
  nimMeth("title:"):
    var node = GroupNode(evalArgInfix(spry))
    let title = StringVal(evalArg(spry)).value
    groupSetTitle(toUiGroup(node.control), title.cstring)
    return node

  # MultilineEntry
  nimFunc("newMultilineEntryText"):
    MultilineEntryNode(control: newMultilineEntry(), spry: spry)
  nimMeth("text"):
    var node = MultilineEntryNode(evalArgInfix(spry))
    newValue($(multilineEntryText(cast[ptr MultilineEntry](node.control))))
  nimMeth("text:"):
    var node = MultilineEntryNode(evalArgInfix(spry))
    multilineEntrySetText(cast[ptr MultilineEntry](node.control), StringVal(evalArg(spry)).value.cstring)
    return node
  nimMeth("append:"):
    var node = MultilineEntryNode(evalArgInfix(spry))
    multilineEntryAppend(cast[ptr MultilineEntry](node.control), StringVal(evalArg(spry)).value.cstring)
    return node
  nimMeth("onChanged:"):
    var node = MultilineEntryNode(evalArgInfix(spry))
    node.onChanged = Blok(evalArg(spry))
    multilineEntryOnChanged(cast[ptr MultilineEntry](node.control), onChanged, cast[ptr MultilineEntryNode](node))
    return node

  # Boxes
  nimFunc("newVerticalBox"):
    BoxNode(control: newVerticalBox(), spry: spry)
  nimFunc("newHorizontalBox"):
    BoxNode(control: newHorizontalBox(), spry: spry)
  nimMeth("append:stretch:"):
    var node = BoxNode(evalArgInfix(spry))
    var control = ControlNode(evalArg(spry))
    var stretchy = IntVal(evalArg(spry))
    boxAppend(cast[ptr Box](node.control), cast[ptr Control](control.control), stretchy.value.cint)
    return node
  nimMeth("delete:"):
    var node = BoxNode(evalArgInfix(spry))
    var index = IntVal(evalArg(spry))
    boxDelete(cast[ptr Box](node.control), index.value.cuint)
    return node
  nimMeth("padding"):
    var node = BoxNode(evalArgInfix(spry))
    return newValue(int(boxPadded(cast[ptr Box](node.control))))
  nimMeth("padding:"):
    var node = BoxNode(evalArgInfix(spry))
    let padding = IntVal(evalArg(spry)).value
    boxSetPadded(cast[ptr Box](node.control), padding.cint)
    return node

  # Buttons
  nimFunc("newButton"):
    let label = StringVal(evalArg(spry)).value
    ButtonNode(control: newButton(label.cstring), spry: spry)
  nimMeth("onClicked:"):
    var node = ButtonNode(evalArgInfix(spry))
    node.onClicked = Blok(evalArg(spry))
    buttonOnClicked(cast[ptr Button](node.control), onClicked, cast[ptr ButtonNode](node))
    return node
    
