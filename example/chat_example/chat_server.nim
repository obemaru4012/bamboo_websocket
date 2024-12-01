import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       httpcore, 
       json,
       nativesockets, 
       net, 
       strutils, 
       tables,
       uri

from bamboo_websocket/websocket import WebSocket, ConnectionStatus, OpCode
from bamboo_websocket/bamboo_websocket import loadServerSetting, openWebSocket, receiveMessage, sendMessage

var WebSockets: seq[WebSocket] = newSeq[WebSocket]()

proc callBack(request: Request) {.async, gcsafe.} =

  var ws = WebSocket()
  var setting = loadServerSetting()

  if request.url.path == "/":
    let headers = {"Content-type": "text/html; charset=utf-8"}
    let content = readFile("./chat_client.html")
    await request.respond(Http200, content, headers.newHttpHeaders())

  if request.url.path == "/chat":
    try:
      ws = await openWebSocket(request, setting)

      # SubProtocol Proc（名前を取得、さらにURI decode処理を追加）
      var sub_protocol = decodeUrl(request.headers["sec-websocket-protocol", 0])
      ws.optional_data["name"] = $(sub_protocol)

      WebSockets.add(ws)
      echo("ID: ", ws.id, ", Tag: ", ws.optional_data["name"], " has Opened.")
    except:
      let message = getCurrentException()
      echo(message.msg)

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