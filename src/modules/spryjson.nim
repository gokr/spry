import spryvm
import json, tables

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

proc spryToJsonNode(node: Node, spry: Interpreter): JsonNode =  
  if node of Blok:
    result = newJArray()
    for child in Blok(node).nodes:
      result.add(spryToJsonNode(child, spry))
  elif node of Map:
    result = newJObject()
    for n, b in Map(node).bindings:
      result[StringVal(n).value] = spryToJsonNode(b.val, spry)
  elif node of StringVal:
    result = newJString(StringVal(node).value)
  elif node of IntVal:
    result = newJInt(IntVal(node).value)
  elif node of FloatVal:
    result = newJFloat(FloatVal(node).value)
  elif node of BoolVal:
    result = newJBool(BoolVal(node).value)
  elif node of NilVal:
    result = newJNull()

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
  nimMeth("toJSON"):
    let node = evalArgInfix(spry)
    JsonSpryNode(json: spryToJsonNode(node, spry))

