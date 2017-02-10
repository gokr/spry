import spryvm
import httpclient

# Spry Net module
proc addNet*(spry: Interpreter) =
  nimFunc("downloadUrl:fileName:"):
    let url = StringVal(evalArg(spry)).value
    let fn = StringVal(evalArg(spry)).value
    downloadFile(url, fn)
    newValue(fn)
  nimFunc("getUrl"):
    let url = StringVal(evalArg(spry)).value
    let client = newHttpClient()
    newValue(client.getContent(url))
