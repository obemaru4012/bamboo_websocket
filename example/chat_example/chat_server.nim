import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       httpcore, 
       json,
       nativesockets, 
       net, 
       strutils, 
       uri

from bamboo_websocket/connection_status import ConnectionStatus
from bamboo_websocket/opcode import Opcode
from bamboo_websocket/websocket import WebSocket, WebSockets, WebSocketC
from bamboo_websocket/receive_result import ReceiveResult
from bamboo_websocket/bamboo_websocket import handshake, loadServerSetting, openWebSocket, receiveMessage, sendMessage

proc subProtcolsProc(ws: WebSocket, sub_protocol: seq[string]): bool {.gcsafe.} = 
  ##[

  ]##
  # 送信されてきたタグをWebSokcetの識別子に変更
  ws.name = sub_protocol[1]
  return true

var setting = loadServerSetting()

proc callBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()

  if request.url.path == "/chat":
    var ws: WebSocket
    try:
      ws = await openWebSocket(request, setting, subProtcolsProc=subProtcolsProc)
      WebSockets.add(ws)
      echo("ID: ", ws.id, ", Tag: ", ws.name, " has Opened.")
    except:
      discard

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()
        if receive.OPCODE == OpCode.TEXT:
          var message: string = $(%* [{"name": ws.name, "message": receive.MESSAGE}])
          echo(message)
          for websocket in WebSockets:
            if websocket.id != ws.id:
              echo("$# => $#" % [$(ws.id), $(websocket.id)])
              await websocket.sendMessage(message, 0x1)

        if receive.OPCODE == OpCode.CLOSE:
          echo("ID: ", ws.id, ", Tag: ", ws.name, " has Closed.")
          break

      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()

    WebSockets.delete(WebSockets.find(ws))
    ws.socket.close()

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)