import unittest, spryvm, spryunittest

# The VM module to test
import sprycore, sprysophia

suite "spry sophia":
  setup:
    let vm = newInterpreter()
    vm.addCore()
    vm.addSophia()

  test "open":
    check run("""
      env = newEnvironment
      env setString: \"sophia.path\" to: \"_test\"
      env getString: \"sophia.path\"
      """) == "\"_test\""

#        env setString: \"db\" to: \"test\"
#      db = (env getObject: \"db\")
      
       