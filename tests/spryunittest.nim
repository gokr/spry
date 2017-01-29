import spryvm

# Some helpers for testing
template show*(code: string): string =
  $newParser().parse(code)
template identical*(code: string): bool =
  code == $newParser().parse(code)
template run*(code: string): string {.dirty.} =
  $vm.evalRoot("[" & code & "]")
template stringRun*(code: string): string {.dirty.} =
  StringVal(vm.evalRoot("[" & code & "]")).value
