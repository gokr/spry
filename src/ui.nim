

when defined(windows):
  const
    dllName* = "ui.dll"
elif defined(macosx):
  const
    dllName* = "libui.dylib"
else:
  const
    dllName* = "libui.so"

type
  InitOptions* = object
    size*: csize


proc init*(options: ptr InitOptions): cstring {.cdecl, importc: "uiInit",
    dynlib: dllName.}
proc uninit*() {.cdecl, importc: "uiUninit", dynlib: dllName.}
proc freeInitError*(err: cstring) {.cdecl, importc: "uiFreeInitError", dynlib: dllName.}
proc main*() {.cdecl, importc: "uiMain", dynlib: dllName.}
proc mainStep*(wait: cint): cint {.cdecl, importc: "uiMainStep", dynlib: dllName.}
proc quit*() {.cdecl, importc: "uiQuit", dynlib: dllName.}
proc queueMain*(f: proc (data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiQueueMain", dynlib: dllName.}
proc onShouldQuit*(f: proc (data: pointer): cint {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiOnShouldQuit", dynlib: dllName.}
proc freeText*(text: cstring) {.cdecl, importc: "uiFreeText", dynlib: dllName.}
type
  Control* {.inheritable, pure.} = object
    signature*: uint32
    oSSignature*: uint32
    typeSignature*: uint32
    destroy*: proc (a2: ptr Control) {.cdecl.}
    handle*: proc (a2: ptr Control): int {.cdecl.}
    parent*: proc (a2: ptr Control): ptr Control {.cdecl.}
    setParent*: proc (a2: ptr Control; a3: ptr Control) {.cdecl.}
    toplevel*: proc (a2: ptr Control): cint {.cdecl.}
    visible*: proc (a2: ptr Control): cint {.cdecl.}
    show*: proc (a2: ptr Control) {.cdecl.}
    hide*: proc (a2: ptr Control) {.cdecl.}
    enabled*: proc (a2: ptr Control): cint {.cdecl.}
    enable*: proc (a2: ptr Control) {.cdecl.}
    disable*: proc (a2: ptr Control) {.cdecl.}



template toUiControl*(this: expr): expr =
  (cast[ptr Control]((this)))

proc controlDestroy*(a2: ptr Control) {.cdecl, importc: "uiControlDestroy",
                                    dynlib: dllName.}
proc controlHandle*(a2: ptr Control): int {.cdecl, importc: "uiControlHandle",
                                       dynlib: dllName.}
proc controlParent*(a2: ptr Control): ptr Control {.cdecl, importc: "uiControlParent",
    dynlib: dllName.}
proc controlSetParent*(a2: ptr Control; a3: ptr Control) {.cdecl,
    importc: "uiControlSetParent", dynlib: dllName.}
proc controlToplevel*(a2: ptr Control): cint {.cdecl, importc: "uiControlToplevel",
    dynlib: dllName.}
proc controlVisible*(a2: ptr Control): cint {.cdecl, importc: "uiControlVisible",
    dynlib: dllName.}
proc controlShow*(a2: ptr Control) {.cdecl, importc: "uiControlShow", dynlib: dllName.}
proc controlHide*(a2: ptr Control) {.cdecl, importc: "uiControlHide", dynlib: dllName.}
proc controlEnabled*(a2: ptr Control): cint {.cdecl, importc: "uiControlEnabled",
    dynlib: dllName.}
proc controlEnable*(a2: ptr Control) {.cdecl, importc: "uiControlEnable",
                                   dynlib: dllName.}
proc controlDisable*(a2: ptr Control) {.cdecl, importc: "uiControlDisable",
                                    dynlib: dllName.}
proc allocControl*(n: csize; oSsig: uint32; typesig: uint32; typenamestr: cstring): ptr Control {.
    cdecl, importc: "uiAllocControl", dynlib: dllName.}
proc freeControl*(a2: ptr Control) {.cdecl, importc: "uiFreeControl", dynlib: dllName.}

proc controlVerifySetParent*(a2: ptr Control; a3: ptr Control) {.cdecl,
    importc: "uiControlVerifySetParent", dynlib: dllName.}
proc controlEnabledToUser*(a2: ptr Control): cint {.cdecl,
    importc: "uiControlEnabledToUser", dynlib: dllName.}
proc userBugCannotSetParentOnToplevel*(`type`: cstring) {.cdecl,
    importc: "uiUserBugCannotSetParentOnToplevel", dynlib: dllName.}
type
  Window* = object of Control
  

template toUiWindow*(this: expr): expr =
  (cast[ptr Window]((this)))

proc windowTitle*(w: ptr Window): cstring {.cdecl, importc: "uiWindowTitle",
                                       dynlib: dllName.}
proc windowSetTitle*(w: ptr Window; title: cstring) {.cdecl,
    importc: "uiWindowSetTitle", dynlib: dllName.}
proc windowOnClosing*(w: ptr Window;
                     f: proc (w: ptr Window; data: pointer): cint {.cdecl.};
                     data: pointer) {.cdecl, importc: "uiWindowOnClosing",
                                    dynlib: dllName.}
proc windowSetChild*(w: ptr Window; child: ptr Control) {.cdecl,
    importc: "uiWindowSetChild", dynlib: dllName.}
proc windowMargined*(w: ptr Window): cint {.cdecl, importc: "uiWindowMargined",
                                       dynlib: dllName.}
proc windowSetMargined*(w: ptr Window; margined: cint) {.cdecl,
    importc: "uiWindowSetMargined", dynlib: dllName.}
proc newWindow*(title: cstring; width: cint; height: cint; hasMenubar: cint): ptr Window {.
    cdecl, importc: "uiNewWindow", dynlib: dllName.}
type
  Button* = object of Control
  

template toUiButton*(this: expr): expr =
  (cast[ptr Button]((this)))

proc buttonText*(b: ptr Button): cstring {.cdecl, importc: "uiButtonText",
                                      dynlib: dllName.}
proc buttonSetText*(b: ptr Button; text: cstring) {.cdecl, importc: "uiButtonSetText",
    dynlib: dllName.}
proc buttonOnClicked*(b: ptr Button;
                     f: proc (b: ptr Button; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiButtonOnClicked", dynlib: dllName.}
proc newButton*(text: cstring): ptr Button {.cdecl, importc: "uiNewButton",
                                        dynlib: dllName.}
type
  Box* = object of Control
  

template toUiBox*(this: expr): expr =
  (cast[ptr Box]((this)))

proc boxAppend*(b: ptr Box; child: ptr Control; stretchy: cint) {.cdecl,
    importc: "uiBoxAppend", dynlib: dllName.}
proc boxDelete*(b: ptr Box; index: uint64) {.cdecl, importc: "uiBoxDelete",
                                       dynlib: dllName.}
proc boxPadded*(b: ptr Box): cint {.cdecl, importc: "uiBoxPadded", dynlib: dllName.}
proc boxSetPadded*(b: ptr Box; padded: cint) {.cdecl, importc: "uiBoxSetPadded",
    dynlib: dllName.}
proc newHorizontalBox*(): ptr Box {.cdecl, importc: "uiNewHorizontalBox",
                                dynlib: dllName.}
proc newVerticalBox*(): ptr Box {.cdecl, importc: "uiNewVerticalBox", dynlib: dllName.}
type
  Checkbox* = object of Control
  

template toUiCheckbox*(this: expr): expr =
  (cast[ptr Checkbox]((this)))

proc checkboxText*(c: ptr Checkbox): cstring {.cdecl, importc: "uiCheckboxText",
    dynlib: dllName.}
proc checkboxSetText*(c: ptr Checkbox; text: cstring) {.cdecl,
    importc: "uiCheckboxSetText", dynlib: dllName.}
proc checkboxOnToggled*(c: ptr Checkbox;
                       f: proc (c: ptr Checkbox; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiCheckboxOnToggled", dynlib: dllName.}
proc checkboxChecked*(c: ptr Checkbox): cint {.cdecl, importc: "uiCheckboxChecked",
    dynlib: dllName.}
proc checkboxSetChecked*(c: ptr Checkbox; checked: cint) {.cdecl,
    importc: "uiCheckboxSetChecked", dynlib: dllName.}
proc newCheckbox*(text: cstring): ptr Checkbox {.cdecl, importc: "uiNewCheckbox",
    dynlib: dllName.}
type
  Entry* = object of Control
  

template toUiEntry*(this: expr): expr =
  (cast[ptr Entry]((this)))

proc entryText*(e: ptr Entry): cstring {.cdecl, importc: "uiEntryText", dynlib: dllName.}
proc entrySetText*(e: ptr Entry; text: cstring) {.cdecl, importc: "uiEntrySetText",
    dynlib: dllName.}
proc entryOnChanged*(e: ptr Entry; f: proc (e: ptr Entry; data: pointer) {.cdecl.};
                    data: pointer) {.cdecl, importc: "uiEntryOnChanged",
                                   dynlib: dllName.}
proc entryReadOnly*(e: ptr Entry): cint {.cdecl, importc: "uiEntryReadOnly",
                                     dynlib: dllName.}
proc entrySetReadOnly*(e: ptr Entry; readonly: cint) {.cdecl,
    importc: "uiEntrySetReadOnly", dynlib: dllName.}
proc newEntry*(): ptr Entry {.cdecl, importc: "uiNewEntry", dynlib: dllName.}
type
  Label* = object of Control
  

template toUiLabel*(this: expr): expr =
  (cast[ptr Label]((this)))

proc labelText*(l: ptr Label): cstring {.cdecl, importc: "uiLabelText", dynlib: dllName.}
proc labelSetText*(l: ptr Label; text: cstring) {.cdecl, importc: "uiLabelSetText",
    dynlib: dllName.}
proc newLabel*(text: cstring): ptr Label {.cdecl, importc: "uiNewLabel", dynlib: dllName.}
type
  Tab* = object of Control
  

template toUiTab*(this: expr): expr =
  (cast[ptr Tab]((this)))

proc tabAppend*(t: ptr Tab; name: cstring; c: ptr Control) {.cdecl,
    importc: "uiTabAppend", dynlib: dllName.}
proc tabInsertAt*(t: ptr Tab; name: cstring; before: uint64; c: ptr Control) {.cdecl,
    importc: "uiTabInsertAt", dynlib: dllName.}
proc tabDelete*(t: ptr Tab; index: uint64) {.cdecl, importc: "uiTabDelete",
                                       dynlib: dllName.}
proc tabNumPages*(t: ptr Tab): uint64 {.cdecl, importc: "uiTabNumPages", dynlib: dllName.}
proc tabMargined*(t: ptr Tab; page: uint64): cint {.cdecl, importc: "uiTabMargined",
    dynlib: dllName.}
proc tabSetMargined*(t: ptr Tab; page: uint64; margined: cint) {.cdecl,
    importc: "uiTabSetMargined", dynlib: dllName.}
proc newTab*(): ptr Tab {.cdecl, importc: "uiNewTab", dynlib: dllName.}
type
  Group* = object of Control
  

template toUiGroup*(this: expr): expr =
  (cast[ptr Group]((this)))

proc groupTitle*(g: ptr Group): cstring {.cdecl, importc: "uiGroupTitle",
                                     dynlib: dllName.}
proc groupSetTitle*(g: ptr Group; title: cstring) {.cdecl, importc: "uiGroupSetTitle",
    dynlib: dllName.}
proc groupSetChild*(g: ptr Group; c: ptr Control) {.cdecl, importc: "uiGroupSetChild",
    dynlib: dllName.}
proc groupMargined*(g: ptr Group): cint {.cdecl, importc: "uiGroupMargined",
                                     dynlib: dllName.}
proc groupSetMargined*(g: ptr Group; margined: cint) {.cdecl,
    importc: "uiGroupSetMargined", dynlib: dllName.}
proc newGroup*(title: cstring): ptr Group {.cdecl, importc: "uiNewGroup",
                                       dynlib: dllName.}

type
  Spinbox* = object of Control
  

template toUiSpinbox*(this: expr): expr =
  (cast[ptr Spinbox]((this)))

proc spinboxValue*(s: ptr Spinbox): int64 {.cdecl, importc: "uiSpinboxValue",
                                       dynlib: dllName.}
proc spinboxSetValue*(s: ptr Spinbox; value: int64) {.cdecl,
    importc: "uiSpinboxSetValue", dynlib: dllName.}
proc spinboxOnChanged*(s: ptr Spinbox;
                      f: proc (s: ptr Spinbox; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiSpinboxOnChanged", dynlib: dllName.}
proc newSpinbox*(min: int64; max: int64): ptr Spinbox {.cdecl, importc: "uiNewSpinbox",
    dynlib: dllName.}
type
  Slider* = object of Control
  

template toUiSlider*(this: expr): expr =
  (cast[ptr Slider]((this)))

proc sliderValue*(s: ptr Slider): int64 {.cdecl, importc: "uiSliderValue",
                                     dynlib: dllName.}
proc sliderSetValue*(s: ptr Slider; value: int64) {.cdecl, importc: "uiSliderSetValue",
    dynlib: dllName.}
proc sliderOnChanged*(s: ptr Slider;
                     f: proc (s: ptr Slider; data: pointer) {.cdecl.}; data: pointer) {.
    cdecl, importc: "uiSliderOnChanged", dynlib: dllName.}
proc newSlider*(min: int64; max: int64): ptr Slider {.cdecl, importc: "uiNewSlider",
    dynlib: dllName.}
type
  ProgressBar* = object of Control
  

template toUiProgressBar*(this: expr): expr =
  (cast[ptr ProgressBar]((this)))


proc progressBarSetValue*(p: ptr ProgressBar; n: cint) {.cdecl,
    importc: "uiProgressBarSetValue", dynlib: dllName.}
proc newProgressBar*(): ptr ProgressBar {.cdecl, importc: "uiNewProgressBar",
                                      dynlib: dllName.}
type
  Separator* = object of Control
  

template toUiSeparator*(this: expr): expr =
  (cast[ptr Separator]((this)))

proc newHorizontalSeparator*(): ptr Separator {.cdecl,
    importc: "uiNewHorizontalSeparator", dynlib: dllName.}
type
  Combobox* = object of Control
  

template toUiCombobox*(this: expr): expr =
  (cast[ptr Combobox]((this)))

proc comboboxAppend*(c: ptr Combobox; text: cstring) {.cdecl,
    importc: "uiComboboxAppend", dynlib: dllName.}
proc comboboxSelected*(c: ptr Combobox): int64 {.cdecl, importc: "uiComboboxSelected",
    dynlib: dllName.}
proc comboboxSetSelected*(c: ptr Combobox; n: int64) {.cdecl,
    importc: "uiComboboxSetSelected", dynlib: dllName.}
proc comboboxOnSelected*(c: ptr Combobox;
                        f: proc (c: ptr Combobox; data: pointer) {.cdecl.};
                        data: pointer) {.cdecl, importc: "uiComboboxOnSelected",
                                       dynlib: dllName.}
proc newCombobox*(): ptr Combobox {.cdecl, importc: "uiNewCombobox", dynlib: dllName.}
type
  EditableCombobox* = object of Control
  

template toUiEditableCombobox*(this: expr): expr =
  (cast[ptr EditableCombobox]((this)))

proc editableComboboxAppend*(c: ptr EditableCombobox; text: cstring) {.cdecl,
    importc: "uiEditableComboboxAppend", dynlib: dllName.}
proc editableComboboxText*(c: ptr EditableCombobox): cstring {.cdecl,
    importc: "uiEditableComboboxText", dynlib: dllName.}
proc editableComboboxSetText*(c: ptr EditableCombobox; text: cstring) {.cdecl,
    importc: "uiEditableComboboxSetText", dynlib: dllName.}

proc editableComboboxOnChanged*(c: ptr EditableCombobox; f: proc (
    c: ptr EditableCombobox; data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiEditableComboboxOnChanged", dynlib: dllName.}
proc newEditableCombobox*(): ptr EditableCombobox {.cdecl,
    importc: "uiNewEditableCombobox", dynlib: dllName.}
type
  RadioButtons* = object of Control
  

template toUiRadioButtons*(this: expr): expr =
  (cast[ptr RadioButtons]((this)))

proc radioButtonsAppend*(r: ptr RadioButtons; text: cstring) {.cdecl,
    importc: "uiRadioButtonsAppend", dynlib: dllName.}
proc newRadioButtons*(): ptr RadioButtons {.cdecl, importc: "uiNewRadioButtons",
                                        dynlib: dllName.}
type
  DateTimePicker* = object of Control
  

template toUiDateTimePicker*(this: expr): expr =
  (cast[ptr DateTimePicker]((this)))

proc newDateTimePicker*(): ptr DateTimePicker {.cdecl,
    importc: "uiNewDateTimePicker", dynlib: dllName.}
proc newDatePicker*(): ptr DateTimePicker {.cdecl, importc: "uiNewDatePicker",
                                        dynlib: dllName.}
proc newTimePicker*(): ptr DateTimePicker {.cdecl, importc: "uiNewTimePicker",
                                        dynlib: dllName.}

type
  MultilineEntry* = object of Control
  

template toUiMultilineEntry*(this: expr): expr =
  (cast[ptr MultilineEntry]((this)))

proc multilineEntryText*(e: ptr MultilineEntry): cstring {.cdecl,
    importc: "uiMultilineEntryText", dynlib: dllName.}
proc multilineEntrySetText*(e: ptr MultilineEntry; text: cstring) {.cdecl,
    importc: "uiMultilineEntrySetText", dynlib: dllName.}
proc multilineEntryAppend*(e: ptr MultilineEntry; text: cstring) {.cdecl,
    importc: "uiMultilineEntryAppend", dynlib: dllName.}
proc multilineEntryOnChanged*(e: ptr MultilineEntry; f: proc (e: ptr MultilineEntry;
    data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiMultilineEntryOnChanged", dynlib: dllName.}
proc multilineEntryReadOnly*(e: ptr MultilineEntry): cint {.cdecl,
    importc: "uiMultilineEntryReadOnly", dynlib: dllName.}
proc multilineEntrySetReadOnly*(e: ptr MultilineEntry; readonly: cint) {.cdecl,
    importc: "uiMultilineEntrySetReadOnly", dynlib: dllName.}
proc newMultilineEntry*(): ptr MultilineEntry {.cdecl,
    importc: "uiNewMultilineEntry", dynlib: dllName.}
proc newNonWrappingMultilineEntry*(): ptr MultilineEntry {.cdecl,
    importc: "uiNewNonWrappingMultilineEntry", dynlib: dllName.}
type
  MenuItem* = object of Control
  

template toUiMenuItem*(this: expr): expr =
  (cast[ptr MenuItem]((this)))

proc menuItemEnable*(m: ptr MenuItem) {.cdecl, importc: "uiMenuItemEnable",
                                    dynlib: dllName.}
proc menuItemDisable*(m: ptr MenuItem) {.cdecl, importc: "uiMenuItemDisable",
                                     dynlib: dllName.}
proc menuItemOnClicked*(m: ptr MenuItem; f: proc (sender: ptr MenuItem;
    window: ptr Window; data: pointer) {.cdecl.}; data: pointer) {.cdecl,
    importc: "uiMenuItemOnClicked", dynlib: dllName.}
proc menuItemChecked*(m: ptr MenuItem): cint {.cdecl, importc: "uiMenuItemChecked",
    dynlib: dllName.}
proc menuItemSetChecked*(m: ptr MenuItem; checked: cint) {.cdecl,
    importc: "uiMenuItemSetChecked", dynlib: dllName.}
type
  Menu* = object of Control
  

template toUiMenu*(this: expr): expr =
  (cast[ptr Menu]((this)))

proc menuAppendItem*(m: ptr Menu; name: cstring): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendItem", dynlib: dllName.}
proc menuAppendCheckItem*(m: ptr Menu; name: cstring): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendCheckItem", dynlib: dllName.}
proc menuAppendQuitItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendQuitItem", dynlib: dllName.}
proc menuAppendPreferencesItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendPreferencesItem", dynlib: dllName.}
proc menuAppendAboutItem*(m: ptr Menu): ptr MenuItem {.cdecl,
    importc: "uiMenuAppendAboutItem", dynlib: dllName.}
proc menuAppendSeparator*(m: ptr Menu) {.cdecl, importc: "uiMenuAppendSeparator",
                                     dynlib: dllName.}
proc newMenu*(name: cstring): ptr Menu {.cdecl, importc: "uiNewMenu", dynlib: dllName.}
proc openFile*(parent: ptr Window): cstring {.cdecl, importc: "uiOpenFile",
    dynlib: dllName.}
proc saveFile*(parent: ptr Window): cstring {.cdecl, importc: "uiSaveFile",
    dynlib: dllName.}
proc msgBox*(parent: ptr Window; title: cstring; description: cstring) {.cdecl,
    importc: "uiMsgBox", dynlib: dllName.}
proc msgBoxError*(parent: ptr Window; title: cstring; description: cstring) {.cdecl,
    importc: "uiMsgBoxError", dynlib: dllName.}
type
  Area* = object of Control
  
  DrawContext* = object
  
  AreaDrawParams* = object
    context*: ptr DrawContext
    areaWidth*: cdouble
    areaHeight*: cdouble
    clipX*: cdouble
    clipY*: cdouble
    clipWidth*: cdouble
    clipHeight*: cdouble



type
  AreaMouseEvent* = object
    x*: cdouble
    y*: cdouble
    areaWidth*: cdouble
    areaHeight*: cdouble
    down*: uint64
    up*: uint64
    count*: uint64
    modifiers*: Modifiers
    held1To64*: uint64

  Modifiers* {.size: sizeof(cint).} = enum
    ModifierCtrl = 1 shl 0, ModifierAlt = 1 shl 1, ModifierShift = 1 shl 2,
    ModifierSuper = 1 shl 3


type
  ExtKey* {.size: sizeof(cint).} = enum
    ExtKeyEscape = 1, ExtKeyInsert, ExtKeyDelete, ExtKeyHome, ExtKeyEnd, ExtKeyPageUp,
    ExtKeyPageDown, ExtKeyUp, ExtKeyDown, ExtKeyLeft, ExtKeyRight, ExtKeyF1, ExtKeyF2,
    ExtKeyF3, ExtKeyF4, ExtKeyF5, ExtKeyF6, ExtKeyF7, ExtKeyF8, ExtKeyF9, ExtKeyF10,
    ExtKeyF11, ExtKeyF12, ExtKeyN0, ExtKeyN1, ExtKeyN2, ExtKeyN3, ExtKeyN4, ExtKeyN5,
    ExtKeyN6, ExtKeyN7, ExtKeyN8, ExtKeyN9, ExtKeyNDot, ExtKeyNEnter, ExtKeyNAdd,
    ExtKeyNSubtract, ExtKeyNMultiply, ExtKeyNDivide


type
  AreaKeyEvent* = object
    key*: char
    extKey*: ExtKey
    modifier*: Modifiers
    modifiers*: Modifiers
    up*: cint

  AreaHandler* = object
    draw*: proc (a2: ptr AreaHandler; a3: ptr Area; a4: ptr AreaDrawParams) {.cdecl.}
    mouseEvent*: proc (a2: ptr AreaHandler; a3: ptr Area; a4: ptr AreaMouseEvent) {.cdecl.}
    mouseCrossed*: proc (a2: ptr AreaHandler; a3: ptr Area; left: cint) {.cdecl.}
    dragBroken*: proc (a2: ptr AreaHandler; a3: ptr Area) {.cdecl.}
    keyEvent*: proc (a2: ptr AreaHandler; a3: ptr Area; a4: ptr AreaKeyEvent): cint {.cdecl.}


template toUiArea*(this: expr): expr =
  (cast[ptr Area]((this)))


proc areaSetSize*(a: ptr Area; width: int64; height: int64) {.cdecl,
    importc: "uiAreaSetSize", dynlib: dllName.}

proc areaQueueRedrawAll*(a: ptr Area) {.cdecl, importc: "uiAreaQueueRedrawAll",
                                    dynlib: dllName.}
proc areaScrollTo*(a: ptr Area; x: cdouble; y: cdouble; width: cdouble; height: cdouble) {.
    cdecl, importc: "uiAreaScrollTo", dynlib: dllName.}
proc newArea*(ah: ptr AreaHandler): ptr Area {.cdecl, importc: "uiNewArea",
    dynlib: dllName.}
proc newScrollingArea*(ah: ptr AreaHandler; width: int64; height: int64): ptr Area {.
    cdecl, importc: "uiNewScrollingArea", dynlib: dllName.}
type
  DrawPath* = object
  
  DrawBrushType* {.size: sizeof(cint).} = enum
    DrawBrushTypeSolid, DrawBrushTypeLinearGradient, DrawBrushTypeRadialGradient,
    DrawBrushTypeImage


type
  DrawLineCap* {.size: sizeof(cint).} = enum
    DrawLineCapFlat, DrawLineCapRound, DrawLineCapSquare


type
  DrawLineJoin* {.size: sizeof(cint).} = enum
    DrawLineJoinMiter, DrawLineJoinRound, DrawLineJoinBevel



const
  DrawDefaultMiterLimit* = 10.0

type
  DrawFillMode* {.size: sizeof(cint).} = enum
    DrawFillModeWinding, DrawFillModeAlternate


type
  DrawMatrix* = object
    m11*: cdouble
    m12*: cdouble
    m21*: cdouble
    m22*: cdouble
    m31*: cdouble
    m32*: cdouble

  DrawBrush* = object
    `type`*: DrawBrushType
    r*: cdouble
    g*: cdouble
    b*: cdouble
    a*: cdouble
    x0*: cdouble
    y0*: cdouble
    x1*: cdouble
    y1*: cdouble
    outerRadius*: cdouble
    stops*: ptr DrawBrushGradientStop
    numStops*: csize

  DrawBrushGradientStop* = object
    pos*: cdouble
    r*: cdouble
    g*: cdouble
    b*: cdouble
    a*: cdouble

  DrawStrokeParams* = object
    cap*: DrawLineCap
    join*: DrawLineJoin
    thickness*: cdouble
    miterLimit*: cdouble
    dashes*: ptr cdouble
    numDashes*: csize
    dashPhase*: cdouble


proc drawNewPath*(fillMode: DrawFillMode): ptr DrawPath {.cdecl,
    importc: "uiDrawNewPath", dynlib: dllName.}
proc drawFreePath*(p: ptr DrawPath) {.cdecl, importc: "uiDrawFreePath", dynlib: dllName.}
proc drawPathNewFigure*(p: ptr DrawPath; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawPathNewFigure", dynlib: dllName.}
proc drawPathNewFigureWithArc*(p: ptr DrawPath; xCenter: cdouble; yCenter: cdouble;
                              radius: cdouble; startAngle: cdouble; sweep: cdouble;
                              negative: cint) {.cdecl,
    importc: "uiDrawPathNewFigureWithArc", dynlib: dllName.}
proc drawPathLineTo*(p: ptr DrawPath; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawPathLineTo", dynlib: dllName.}

proc drawPathArcTo*(p: ptr DrawPath; xCenter: cdouble; yCenter: cdouble;
                   radius: cdouble; startAngle: cdouble; sweep: cdouble;
                   negative: cint) {.cdecl, importc: "uiDrawPathArcTo",
                                   dynlib: dllName.}
proc drawPathBezierTo*(p: ptr DrawPath; c1x: cdouble; c1y: cdouble; c2x: cdouble;
                      c2y: cdouble; endX: cdouble; endY: cdouble) {.cdecl,
    importc: "uiDrawPathBezierTo", dynlib: dllName.}

proc drawPathCloseFigure*(p: ptr DrawPath) {.cdecl, importc: "uiDrawPathCloseFigure",
    dynlib: dllName.}

proc drawPathAddRectangle*(p: ptr DrawPath; x: cdouble; y: cdouble; width: cdouble;
                          height: cdouble) {.cdecl,
    importc: "uiDrawPathAddRectangle", dynlib: dllName.}
proc drawPathEnd*(p: ptr DrawPath) {.cdecl, importc: "uiDrawPathEnd", dynlib: dllName.}
proc drawStroke*(c: ptr DrawContext; path: ptr DrawPath; b: ptr DrawBrush;
                p: ptr DrawStrokeParams) {.cdecl, importc: "uiDrawStroke",
                                        dynlib: dllName.}
proc drawFill*(c: ptr DrawContext; path: ptr DrawPath; b: ptr DrawBrush) {.cdecl,
    importc: "uiDrawFill", dynlib: dllName.}

proc drawMatrixSetIdentity*(m: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawMatrixSetIdentity", dynlib: dllName.}
proc drawMatrixTranslate*(m: ptr DrawMatrix; x: cdouble; y: cdouble) {.cdecl,
    importc: "uiDrawMatrixTranslate", dynlib: dllName.}
proc drawMatrixScale*(m: ptr DrawMatrix; xCenter: cdouble; yCenter: cdouble; x: cdouble;
                     y: cdouble) {.cdecl, importc: "uiDrawMatrixScale",
                                 dynlib: dllName.}
proc drawMatrixRotate*(m: ptr DrawMatrix; x: cdouble; y: cdouble; amount: cdouble) {.
    cdecl, importc: "uiDrawMatrixRotate", dynlib: dllName.}
proc drawMatrixSkew*(m: ptr DrawMatrix; x: cdouble; y: cdouble; xamount: cdouble;
                    yamount: cdouble) {.cdecl, importc: "uiDrawMatrixSkew",
                                      dynlib: dllName.}
proc drawMatrixMultiply*(dest: ptr DrawMatrix; src: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawMatrixMultiply", dynlib: dllName.}
proc drawMatrixInvertible*(m: ptr DrawMatrix): cint {.cdecl,
    importc: "uiDrawMatrixInvertible", dynlib: dllName.}
proc drawMatrixInvert*(m: ptr DrawMatrix): cint {.cdecl,
    importc: "uiDrawMatrixInvert", dynlib: dllName.}
proc drawMatrixTransformPoint*(m: ptr DrawMatrix; x: ptr cdouble; y: ptr cdouble) {.cdecl,
    importc: "uiDrawMatrixTransformPoint", dynlib: dllName.}
proc drawMatrixTransformSize*(m: ptr DrawMatrix; x: ptr cdouble; y: ptr cdouble) {.cdecl,
    importc: "uiDrawMatrixTransformSize", dynlib: dllName.}
proc drawTransform*(c: ptr DrawContext; m: ptr DrawMatrix) {.cdecl,
    importc: "uiDrawTransform", dynlib: dllName.}

proc drawClip*(c: ptr DrawContext; path: ptr DrawPath) {.cdecl, importc: "uiDrawClip",
    dynlib: dllName.}
proc drawSave*(c: ptr DrawContext) {.cdecl, importc: "uiDrawSave", dynlib: dllName.}
proc drawRestore*(c: ptr DrawContext) {.cdecl, importc: "uiDrawRestore",
                                    dynlib: dllName.}

type
  DrawFontFamilies* = object
  

proc drawListFontFamilies*(): ptr DrawFontFamilies {.cdecl,
    importc: "uiDrawListFontFamilies", dynlib: dllName.}
proc drawFontFamiliesNumFamilies*(ff: ptr DrawFontFamilies): uint64 {.cdecl,
    importc: "uiDrawFontFamiliesNumFamilies", dynlib: dllName.}
proc drawFontFamiliesFamily*(ff: ptr DrawFontFamilies; n: uint64): cstring {.cdecl,
    importc: "uiDrawFontFamiliesFamily", dynlib: dllName.}
proc drawFreeFontFamilies*(ff: ptr DrawFontFamilies) {.cdecl,
    importc: "uiDrawFreeFontFamilies", dynlib: dllName.}

type
  DrawTextLayout* = object
  
  DrawTextFont* = object
  
  DrawTextWeight* {.size: sizeof(cint).} = enum
    DrawTextWeightThin, DrawTextWeightUltraLight, DrawTextWeightLight,
    DrawTextWeightBook, DrawTextWeightNormal, DrawTextWeightMedium,
    DrawTextWeightSemiBold, DrawTextWeightBold, DrawTextWeightUtraBold,
    DrawTextWeightHeavy, DrawTextWeightUltraHeavy


type
  DrawTextItalic* {.size: sizeof(cint).} = enum
    DrawTextItalicNormal, DrawTextItalicOblique, DrawTextItalicItalic


type
  DrawTextStretch* {.size: sizeof(cint).} = enum
    DrawTextStretchUltraCondensed, DrawTextStretchExtraCondensed,
    DrawTextStretchCondensed, DrawTextStretchSemiCondensed, DrawTextStretchNormal,
    DrawTextStretchSemiExpanded, DrawTextStretchExpanded,
    DrawTextStretchExtraExpanded, DrawTextStretchUltraExpanded


type
  DrawTextFontDescriptor* = object
    family*: cstring
    size*: cdouble
    weight*: DrawTextWeight
    italic*: DrawTextItalic
    stretch*: DrawTextStretch

  DrawTextFontMetrics* = object
    ascent*: cdouble
    descent*: cdouble
    leading*: cdouble
    underlinePos*: cdouble
    underlineThickness*: cdouble


proc drawLoadClosestFont*(desc: ptr DrawTextFontDescriptor): ptr DrawTextFont {.cdecl,
    importc: "uiDrawLoadClosestFont", dynlib: dllName.}
proc drawFreeTextFont*(font: ptr DrawTextFont) {.cdecl,
    importc: "uiDrawFreeTextFont", dynlib: dllName.}
proc drawTextFontHandle*(font: ptr DrawTextFont): int {.cdecl,
    importc: "uiDrawTextFontHandle", dynlib: dllName.}
proc drawTextFontDescribe*(font: ptr DrawTextFont; desc: ptr DrawTextFontDescriptor) {.
    cdecl, importc: "uiDrawTextFontDescribe", dynlib: dllName.}

proc drawTextFontGetMetrics*(font: ptr DrawTextFont;
                            metrics: ptr DrawTextFontMetrics) {.cdecl,
    importc: "uiDrawTextFontGetMetrics", dynlib: dllName.}

proc drawNewTextLayout*(text: cstring; defaultFont: ptr DrawTextFont; width: cdouble): ptr DrawTextLayout {.
    cdecl, importc: "uiDrawNewTextLayout", dynlib: dllName.}
proc drawFreeTextLayout*(layout: ptr DrawTextLayout) {.cdecl,
    importc: "uiDrawFreeTextLayout", dynlib: dllName.}

proc drawTextLayoutSetWidth*(layout: ptr DrawTextLayout; width: cdouble) {.cdecl,
    importc: "uiDrawTextLayoutSetWidth", dynlib: dllName.}
proc drawTextLayoutExtents*(layout: ptr DrawTextLayout; width: ptr cdouble;
                           height: ptr cdouble) {.cdecl,
    importc: "uiDrawTextLayoutExtents", dynlib: dllName.}

proc drawTextLayoutSetColor*(layout: ptr DrawTextLayout; startChar: int64;
                            endChar: int64; r: cdouble; g: cdouble; b: cdouble;
                            a: cdouble) {.cdecl,
                                        importc: "uiDrawTextLayoutSetColor",
                                        dynlib: dllName.}
proc drawText*(c: ptr DrawContext; x: cdouble; y: cdouble; layout: ptr DrawTextLayout) {.
    cdecl, importc: "uiDrawText", dynlib: dllName.}
type
  FontButton* = object of Control
  

template toUiFontButton*(this: expr): expr =
  (cast[ptr FontButton]((this)))


proc fontButtonFont*(b: ptr FontButton): ptr DrawTextFont {.cdecl,
    importc: "uiFontButtonFont", dynlib: dllName.}

proc fontButtonOnChanged*(b: ptr FontButton;
                         f: proc (a2: ptr FontButton; a3: pointer) {.cdecl.};
                         data: pointer) {.cdecl, importc: "uiFontButtonOnChanged",
                                        dynlib: dllName.}
proc newFontButton*(): ptr FontButton {.cdecl, importc: "uiNewFontButton",
                                    dynlib: dllName.}
type
  ColorButton* = object of Control
  

template toUiColorButton*(this: expr): expr =
  (cast[ptr ColorButton]((this)))

proc colorButtonColor*(b: ptr ColorButton; r: ptr cdouble; g: ptr cdouble;
                      bl: ptr cdouble; a: ptr cdouble) {.cdecl,
    importc: "uiColorButtonColor", dynlib: dllName.}
proc colorButtonSetColor*(b: ptr ColorButton; r: cdouble; g: cdouble; bl: cdouble;
                         a: cdouble) {.cdecl, importc: "uiColorButtonSetColor",
                                     dynlib: dllName.}
proc colorButtonOnChanged*(b: ptr ColorButton;
                          f: proc (a2: ptr ColorButton; a3: pointer) {.cdecl.};
                          data: pointer) {.cdecl,
    importc: "uiColorButtonOnChanged", dynlib: dllName.}
proc newColorButton*(): ptr ColorButton {.cdecl, importc: "uiNewColorButton",
                                      dynlib: dllName.}