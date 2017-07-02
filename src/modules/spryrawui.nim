import spryvm

import ui/rawui

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
  MenuNode = ref object of ControlNode
    onClicked*: Blok
    onShouldQuit*: Blok
  MenuItemNode = ref object of ControlNode
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
proc onClosing*(sender: ptr Window; data: pointer): cint {.cdecl.} =
  var node = cast[WindowNode](data)
  discard node.onClosing.evalDo(node.spry)
  return 0 #?

proc onChanged*(sender: ptr MultilineEntry; data: pointer) {.cdecl.} =
  var node = cast[MultilineEntryNode](data)
  discard node.onChanged.evalDo(node.spry)

proc onClicked*(sender: ptr Button; data: pointer) {.cdecl.} =
  var node = cast[ButtonNode](data)
  discard node.onClicked.evalDo(node.spry)

proc onClicked*(sender: ptr MenuItem; window: ptr Window; data: pointer) {.cdecl.} =
  var node = cast[MenuItemNode](data)
  discard node.onClicked.evalDo(node.spry)

proc onShouldQuit*(data: pointer): cint {.cdecl.} =
  var node = cast[MenuNode](data)
  discard node.onShouldQuit.evalDo(node.spry)

# Spry UI module
proc addRawUI*(spry: Interpreter) =
  # libui
  nimFunc("uiInit"):
    var o: rawui.InitOptions
    var err: cstring
    err = rawui.init(addr(o))
    if err != nil:
      echo "error initializing ui: ", err
      freeInitError(err)
      return
  nimFunc("uiMain"):
    rawui.main()
  nimFunc("uiQuit"):
    rawui.quit()
  nimFunc("uiUninit"):
    rawui.uninit()

  # File dialogs
  nimMeth("openFile"):
    var win = WindowNode(evalArgInfix(spry))
    var path = openFile(toUiWindow(win.control))
    if path.isNil:
      spry.nilVal
    else:
      newValue($path)
  nimMeth("saveFile"):
    var win = WindowNode(evalArgInfix(spry))
    var path = saveFile(toUiWindow(win.control))
    if path.isNil:
      spry.nilVal
    else:
      newValue($path)

  # Menu
  nimFunc("newMenu"):
    let name = StringVal(evalArg(spry)).value
    MenuNode(control: newMenu(name.cstring), spry: spry)
  nimMeth("menuAppendItem:"):
    let node = MenuNode(evalArgInfix(spry))
    let name = StringVal(evalArg(spry)).value
    MenuItemNode(control: menuAppendItem(toUiMenu(node.control), name.cstring), spry: spry)
  nimMeth("menuAppendCheckItem:"):
    let node = MenuNode(evalArgInfix(spry))
    let name = StringVal(evalArg(spry)).value
    MenuItemNode(control: menuAppendCheckItem(toUiMenu(node.control), name.cstring), spry: spry)
  nimMeth("menuAppendQuitItem"):
    let node = MenuNode(evalArgInfix(spry))
    MenuItemNode(control: menuAppendQuitItem(toUiMenu(node.control)), spry: spry)
  nimMeth("menuAppendPreferencesItem"):
    let node = MenuNode(evalArgInfix(spry))
    MenuItemNode(control: menuAppendPreferencesItem(toUiMenu(node.control)), spry: spry)
  nimMeth("menuAppendAboutItem"):
    let node = MenuNode(evalArgInfix(spry))
    MenuItemNode(control: menuAppendAboutItem(toUiMenu(node.control)), spry: spry)
  nimMeth("menuAppendSeparator"):
    let node = MenuNode(evalArgInfix(spry))
    menuAppendSeparator(toUiMenu(node.control))
    return node
  nimMeth("menuItemEnable"):
    let node = MenuItemNode(evalArgInfix(spry))
    menuItemEnable(toUiMenuItem(node.control))
    return node
  nimMeth("menuItemDisable"):
    let node = MenuItemNode(evalArgInfix(spry))
    menuItemDisable(toUiMenuItem(node.control))
    return node
  nimMeth("checked"):
    let node = MenuItemNode(evalArgInfix(spry))
    newValue(menuItemChecked(toUiMenuItem(node.control)).int)
  nimMeth("checked:"):
    let node = MenuItemNode(evalArgInfix(spry))
    let checked = BoolVal(evalArg(spry)).value
    menuItemSetChecked(toUiMenuItem(node.control), if checked: 1 else: 0)
    return node
  nimMeth("onMenuItemClicked:"):
    var node = MenuItemNode(evalArgInfix(spry))
    node.onClicked = Blok(evalArg(spry))
    menuItemOnClicked(toUiMenuItem(node.control), onClicked, cast[ptr MenuItemNode](node))
    return node
  nimMeth("onShouldQuit:"):
    var node = MenuNode(evalArgInfix(spry))
    node.onShouldQuit = Blok(evalArg(spry))
    onShouldQuit(onShouldQuit, cast[ptr MenuNode](node))
    return node

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
    WindowNode(control: newWindow(title.cstring, width.cint, height.cint, bar.cint), spry: spry)
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
    boxDelete(cast[ptr Box](node.control), index.value.cint)
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

