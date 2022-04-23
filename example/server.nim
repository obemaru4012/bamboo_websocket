import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       httpcore, 
       nativesockets, 
       net, 
       strutils, 
       uri

from ../bamboo_websocket/connection_status import ConnectionStatus
from ../bamboo_websocket/opcode import Opcode
from ../bamboo_websocket/websocket import WebSocket, WebSockets, WebSocketC
from ../bamboo_websocket/receive_result import ReceiveResult
from ../bamboo_websocket/bamboo_websocket import handshake, loadServerSetting, openWebSocket, receiveMessage, sendMessage

var setting = loadServerSetting()
var websockets = WebSockets

proc callBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()
  var counter: int = 1

  if request.url.path == "/":
    var ws: WebSocket
    try:
      ws = await openWebSocket(request, setting)
      websockets.add(ws)
    except:
      discard

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()
        if receive.OPCODE == OpCode.TEXT:
          echo(counter, ": ", receive.OPCODE, "=" , receive.MESSAGE)
          counter += 1

        if receive.OPCODE == OpCode.CLOSE:
          echo("ID: ", ws.id, " has Closed.")

        for websocket in websockets:
          if websocket.id != ws.id and receive.OPCODE == OpCode.TEXT:
            await websocket.sendMessage(receive.MESSAGE, 0x1, 3000, true)

      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()
 
    websockets.delete(websockets.find(ws))

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)