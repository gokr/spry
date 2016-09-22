import spryvm
import json

type JsonSpryNode* = ref object of Value
  json*: JsonNode

method eval*(self: JsonSpryNode, spry: Interpreter): Node =
  self

method `$`*(self: JsonSpryNode): string =
  return $self.json

proc jsonNodeToSpry(jnode: JsonNode, spry: Interpreter): Node =  
  case jnode.kind:
  of JArray:
    var blk = newBlok()
    for child in jnode.elems:
      blk.add(jsonNodeToSpry(child, spry))
    return blk
  of JObject:
    var map = newMap()
    for key, value in pairs(jnode):
      map[newValue(key)] = jsonNodeToSpry(value, spry)
    return map
  of JString:
    result = newValue(jnode.str)
  of JInt:
    result = newValue(int(jnode.num))
  of JFloat:
    result = newValue(jnode.fnum)
  of JBool:
    result = boolVal(jnode.bval, spry)
  of JNull:
    result = spry.nilVal

# Spry JSON module
proc addJSON*(spry: Interpreter) =
  nimFunc("parseJSON"):
    let str = StringVal(evalArg(spry)).value
    JsonSpryNode(json: parseJson(str))
  nimFunc("parseFile"):
    let fn = StringVal(evalArg(spry)).value
    JsonSpryNode(json: parseFile(fn))
  nimMeth("toSpry"):
    let json = JsonSpryNode(evalArgInfix(spry)).json
    jsonNodeToSpry(json, spry)
    

