import spryvm

# Spry core lib module
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

    # Collections
    sprydo: = method [:fun
      self reset
      [self end?] whileFalse: [do fun (self next)]
    ]

    detect: = method [:pred
      self reset
      [self end?] whileFalse: [
        n = (self next)
        do pred n then: [^n]]
      ^nil
    ]

    spryselect: = method [:pred
      result = ([] clone)
      self reset
      [self end?] whileFalse: [
        n = (self next)
        do pred n then: [result add: n]]
      ^result]
  ]"""
