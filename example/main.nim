import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       httpclient, 
       httpcore, 
       nativesockets, 
       net, 
       os,
       strutils, 
       uri

from ../bamboo_websocket/connection_status import ConnectionStatus
from ../bamboo_websocket/opcode import Opcode
from ../bamboo_websocket/websocket import WebSocket, WebSocketC
from ../bamboo_websocket/receive_result import ReceiveResult
from ../bamboo_websocket/bamboo_websocket import handshake, loadServerSetting, openWebSocket, receiveMessage, sendMessage

let setting = loadServerSetting()

proc callBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()
  if request.url.path == "/":
    try:
      ws = await openWebSocket(request, setting)
      await ws.sendMessage("ぶんぶんぶんなぐり！", 0x1, 1000, true)
      ws.socket.close()
      
    except:
      discard

if isMainModule:
  var server = newAsyncHttpServer()
  asyncCheck server.serve(Port(9001), callBack)
  var ws = waitFor handshake("localhost", 80, 9001, setting)
  let receive = waitFor ws.receiveMessage()
  echo("OPCODE: $#, MESSAGE: $#" % [$receive.OPCODE, $receive.MESSAGE])