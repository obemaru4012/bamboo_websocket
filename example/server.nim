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
from ../bamboo_websocket/websocket import WebSocket, WebSocketC
from ../bamboo_websocket/receive_result import ReceiveResult
from ../bamboo_websocket/bamboo_websocket import handshake, loadServerSetting, openWebSocket, receiveMessage, sendMessage

var setting = loadServerSetting()

proc callBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()
  var counter: int = 1

  if request.url.path == "/":
    var ws: WebSocket
    try:
      ws = await openWebSocket(request, setting)
    except:
      discard

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()
        echo(counter, ": ", receive.OPCODE, "=" ,receive.MESSAGE)
        counter += 1
      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)