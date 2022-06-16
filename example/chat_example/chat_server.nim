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

from bamboo_websocket/connection_status import ConnectionStatus
from bamboo_websocket/opcode import Opcode
from bamboo_websocket/websocket import WebSocket
from bamboo_websocket/bamboo_websocket import handshake, loadServerSetting, openWebSocket, receiveMessage, sendMessage

var setting = loadServerSetting()
var WebSockets: seq[WebSocket] = newSeq[WebSocket]()

proc subProtcolsProc(ws: WebSocket, sub_protocol: seq[string]): bool {.gcsafe.} = 
  ##[

  ]##
  # 送信されてきたタグをWebSokcetの識別子に変更
  ws.optional_data["name"] = $(sub_protocol[1])
  return true

proc callBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()

  if request.url.path == "/chat":
    var ws: WebSocket
    try:
      ws = await openWebSocket(request, setting, subProtcolsProc=subProtcolsProc)
      WebSockets.add(ws)
      echo("ID: ", ws.id, ", Tag: ", ws.optional_data["name"], " has Opened.")
    except:
      discard

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

    WebSockets.delete(WebSockets.find(ws))
    ws.socket.close()

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)