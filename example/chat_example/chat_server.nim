import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       base64,
       httpcore, 
       json,
       nativesockets, 
       net, 
       strutils, 
       tables,
       uri

from bamboo_websocket/websocket import WebSocket, ConnectionStatus, OpCode
from bamboo_websocket/bamboo_websocket import loadServerSetting, openWebSocket, receiveMessage, sendMessage

var setting = loadServerSetting()
var WebSockets: seq[WebSocket] = newSeq[WebSocket]()

proc callBack(request: Request) {.async, gcsafe.} =

  proc subProtocolProcess(ws: WebSocket, request: Request): bool {.gcsafe.} =
    try:
      var table: Table[string, string]
      var sub_protocol = request.headers["sec-websocket-protocol", 0]

      # Client側は「https://developer.mozilla.org/ja/docs/Web/API/btoa」でベー6エンコード実施。
      var protocols = json.parseJson(base64.decode(sub_protocol)) # JsonNode

      # sub protocolをTable[string, string]に変換
      for key in protocols.keys():
        var tmp = $(protocols[key])
        table[key] = tmp.strip(chars={'"', ' '})

      ws.optional_data["name"] = $(table["tag"])
  
    except IndexDefect:
      return false
    return true

  var ws = WebSocket()

  if request.url.path == "/":
    let headers = {"Content-type": "text/html; charset=utf-8"}
    let content = readFile("./chat_client.html")
    await request.respond(Http200, content, headers.newHttpHeaders())

  if request.url.path == "/chat":
    try:
      ws = await openWebSocket(request, setting, subProtocolProcess=subProtocolProcess)
      WebSockets.add(ws)
      echo("ID: ", ws.id, ", Tag: ", ws.optional_data["name"], " has Opened.")
    except:
      var e = getCurrentException()
      var msg = getCurrentExceptionMsg()
      echo msg

      ws.status = ConnectionStatus.INITIAl

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()
        if receive[0] == OpCode.TEXT:
          var message: string = $(%* [{"name": ws.optional_data["name"], "message": receive[1]}])
          for websocket in WebSockets:
            if websocket.id != ws.id:
              echo("$# => $#" % [$(ws.id), $(websocket.id)])
              await websocket.sendMessage(message, 0x1)

        if receive[0] == OpCode.CLOSE:
          echo("ID: ", ws.id, " has Closed.")
          break

      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()
    
    if WebSockets.find(ws) != -1:
      WebSockets.delete(WebSockets.find(ws))
    
    if ws.status == ConnectionStatus.OPEN:
      ws.socket.close()

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)