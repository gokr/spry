import spryvm
import smtp # http://nim-lang.org/docs/smtp.html

proc blok2seq(blk: Blok): seq[string] =
  result = newSeq[string]()
  for each in blk.nodes:
    result.add(StringVal(each).value)

# Spry SMTP module
proc addSMTP*(spry: Interpreter) =
  nimFunc("sendMailSubject:body:to:cc:from:recipients:server:user:password:port:ssl:"):
    # Most trivial full blown single function
    let subject = StringVal(evalArg(spry)).value
    let body = StringVal(evalArg(spry)).value
    let to = blok2seq(Blok(evalArg(spry)))
    let cc = blok2seq(Blok(evalArg(spry)))
    let frm = StringVal(evalArg(spry)).value
    let recipients = blok2seq(Blok(evalArg(spry)))
    
    # Server stuff
    let server = StringVal(evalArg(spry)).value
    let user = StringVal(evalArg(spry)).value
    let password = StringVal(evalArg(spry)).value
    let port = IntVal(evalArg(spry)).value
    let ssl = BoolVal(evalArg(spry)).value

    # Send it
    var msg = createMessage(subject, body, to, cc)
    let smtpConn = newSmtp(useSsl = ssl) 
    smtpConn.connect(server, Port port)
    smtpConn.auth(user, password)
    smtpConn.sendmail(frm, recipients, $msg)