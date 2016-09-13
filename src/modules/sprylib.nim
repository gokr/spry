import spryvm

# Spry core lib module, only depends on core
proc addLib*(spry: Interpreter) =
  discard spry.evalRoot """[
    # Trivial error function
    error = func [echo :msg quit 1]

    # Trivial assert
    assert = func [:x else: [error "Oops, assertion failed"] ^x]

    # Objects
    object = func [:ts :map
      map tags: ts
      map tag: 'object
      ^ map]

    # Modules
    module = func [
      object [] :map
      map tag: 'module
      ^ map]
  ]"""
