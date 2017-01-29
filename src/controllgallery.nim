# 2 september 2015

import
  ui

# TODOs
# - rename variables in main()
# - make both columns the same size?

var mainwin*: ptr Window

proc onClosing*(w: ptr Window; data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  ui.quit()
  return 0

proc shouldQuit*(data: pointer): cint {.cdecl.} =
  controlDestroy(mainwin)
  return 1

proc openClicked*(item: ptr MenuItem; w: ptr Window; data: pointer) {.cdecl.} =
  var filename = ui.openFile(mainwin)
  if filename == nil:
    msgBoxError(mainwin, "No file selected", "Don\'t be alarmed!")
    return
  msgBox(mainwin, "File selected", filename)
  freeText(filename)

proc saveClicked*(item: ptr MenuItem; w: ptr Window; data: pointer) {.cdecl.} =
  var filename = ui.saveFile(mainwin)
  if filename == nil:
    msgBoxError(mainwin, "No file selected", "Don\'t be alarmed!")
    return
  msgBox(mainwin, "File selected (don\'t worry, it\'s still there)", filename)
  freeText(filename)

var spinbox*: ptr Spinbox

var slider*: ptr Slider

var progressbar*: ptr ProgressBar

proc update*(value: int64) =
  spinboxSetValue(spinbox, value)
  sliderSetValue(slider, value)
  progressBarSetValue(progressbar, value.cint)

proc onSpinboxChanged*(s: ptr Spinbox; data: pointer) {.cdecl.} =
  update(spinboxValue(spinbox))

proc onSliderChanged*(s: ptr Slider; data: pointer) {.cdecl.} =
  update(sliderValue(slider))

proc main*() =
  var o: ui.InitOptions
  var err: cstring
  var menu: ptr Menu
  var item: ptr MenuItem
  var box: ptr Box
  var hbox: ptr Box
  var group: ptr Group
  var inner: ptr Box
  var inner2: ptr Box
  var entry: ptr Entry
  var cbox: ptr Combobox
  var ecbox: ptr EditableCombobox
  var rb: ptr RadioButtons
  var tab: ptr Tab
  err = ui.init(addr(o))
  if err != nil:
    echo "error initializing ui: ", err
    freeInitError(err)
    return
  menu = newMenu("File")
  item = menuAppendItem(menu, "Open")
  menuItemOnClicked(item, openClicked, nil)
  item = menuAppendItem(menu, "Save")
  menuItemOnClicked(item, saveClicked, nil)
  item = menuAppendQuitItem(menu)
  onShouldQuit(shouldQuit, nil)
  menu = newMenu("Edit")
  item = menuAppendCheckItem(menu, "Checkable Item")
  menuAppendSeparator(menu)
  item = menuAppendItem(menu, "Disabled Item")
  menuItemDisable(item)
  item = menuAppendPreferencesItem(menu)
  menu = newMenu("Help")
  item = menuAppendItem(menu, "Help")
  item = menuAppendAboutItem(menu)
  mainwin = newWindow("libui Control Gallery", 640, 480, 1)
  windowSetMargined(mainwin, 1)
  windowOnClosing(mainwin, onClosing, nil)
  box = newVerticalBox()
  boxSetPadded(box, 1)
  windowSetChild(mainwin, box)
  hbox = newHorizontalBox()
  boxSetPadded(hbox, 1)
  boxAppend(box, hbox, 1)
  group = newGroup("Basic Controls")
  groupSetMargined(group, 1)
  boxAppend(hbox, group, 0)
  inner = newVerticalBox()
  boxSetPadded(inner, 1)
  groupSetChild(group, inner)
  boxAppend(inner, newButton("Button"), 0)
  boxAppend(inner, newCheckbox("Checkbox"), 0)
  entry = newEntry()
  entrySetText(entry, "Entry")
  boxAppend(inner, entry, 0)
  boxAppend(inner, newLabel("Label"), 0)
  boxAppend(inner, newHorizontalSeparator(), 0)
  boxAppend(inner, newDatePicker(), 0)
  boxAppend(inner, newTimePicker(), 0)
  boxAppend(inner, newDateTimePicker(), 0)
  boxAppend(inner, newFontButton(), 0)
  boxAppend(inner, newColorButton(), 0)
  inner2 = newVerticalBox()
  boxSetPadded(inner2, 1)
  boxAppend(hbox, inner2, 1)
  group = newGroup("Numbers")
  groupSetMargined(group, 1)
  boxAppend(inner2, group, 0)
  inner = newVerticalBox()
  boxSetPadded(inner, 1)
  groupSetChild(group, inner)
  spinbox = newSpinbox(0, 100)
  spinboxOnChanged(spinbox, onSpinboxChanged, nil)
  boxAppend(inner, spinbox, 0)
  slider = newSlider(0, 100)
  sliderOnChanged(slider, onSliderChanged, nil)
  boxAppend(inner, slider, 0)
  progressbar = newProgressBar()
  boxAppend(inner, progressbar, 0)
  group = newGroup("Lists")
  groupSetMargined(group, 1)
  boxAppend(inner2, group, 0)
  inner = newVerticalBox()
  boxSetPadded(inner, 1)
  groupSetChild(group, inner)
  cbox = newCombobox()
  comboboxAppend(cbox, "Combobox Item 1")
  comboboxAppend(cbox, "Combobox Item 2")
  comboboxAppend(cbox, "Combobox Item 3")
  boxAppend(inner, cbox, 0)
  ecbox = newEditableCombobox()
  editableComboboxAppend(ecbox, "Editable Item 1")
  editableComboboxAppend(ecbox, "Editable Item 2")
  editableComboboxAppend(ecbox, "Editable Item 3")
  boxAppend(inner, ecbox, 0)
  rb = newRadioButtons()
  radioButtonsAppend(rb, "Radio Button 1")
  radioButtonsAppend(rb, "Radio Button 2")
  radioButtonsAppend(rb, "Radio Button 3")
  boxAppend(inner, rb, 1)
  tab = newTab()
  tabAppend(tab, "Page 1", newHorizontalBox())
  tabAppend(tab, "Page 2", newHorizontalBox())
  tabAppend(tab, "Page 3", newHorizontalBox())
  boxAppend(inner2, tab, 1)
  controlShow(mainwin)
  ui.main()
  ui.uninit()

main()
