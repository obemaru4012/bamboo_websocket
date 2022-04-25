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

proc callBack(request: Request) {.async, gcsafe.} =
  var ws: WebSocket

  if request.url.path == "/":
    try:
      ws = await openWebSocket(request, setting)
    except:
      discard

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()

        if receive.OPCODE == OpCode.TEXT:
          echo("ID: ", ws.id, " echo back.")
          await ws.sendMessage(receive.MESSAGE, 0x1, 3000, true)

        if receive.OPCODE == OpCode.CLOSE:
          echo("ID: ", ws.id, " has Closed.")
          break

      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()

    ws.socket.close()

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)