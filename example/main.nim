import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       httpclient, 
       httpcore, 
       nativesockets, 
       net, 
       asyncdispatch, 
       strutils, 
       uri

from ../bamboo_websocket/connection_status import ConnectionStatus
from ../bamboo_websocket/opcode import Opcode
from ../bamboo_websocket/websocket import WebSocket, WebSockets
from ../bamboo_websocket/receive_result import ReceiveResult
from ../bamboo_websocket/bamboo_websocket import loadServerSetting, openWebSocket, receiveMessage, sendMessage

var setting = loadServerSetting()

proc callBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()
  var r: ReceiveResult
  if request.url.path == "/":
    try:
      ws = await openWebSocket(request, setting)
      WebSockets.add(ws)
    except:
      discard

    while ws.status == ConnectionStatus.OPEN:
      try:
        r = await ws.receiveMessage()
      except:
        let msg = getCurrentExceptionMsg()
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()
        WebSockets.delete(WebSockets.find(ws))
        continue

      if r.OPCODE == Opcode.TEXT:
        for websocket in WebSockets:
          if ws.id != websocket.id:
            await websocket.sendMessage(r.MESSAGE, 0x1)

    # 抜けてきたら問答無用で削除
    WebSockets.delete(WebSockets.find(ws))

  else:
    await request.respond(Http200, "This is WebSocket Server.")

if isMainModule:
  var server = newAsyncHttpServer()
  echo("Server Start!!!")
  waitFor server.serve(Port(9001), callBack, "localhost")