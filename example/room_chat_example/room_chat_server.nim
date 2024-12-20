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

var WebSockets: Table[string, seq[WebSocket]] = initTable[string, seq[WebSocket]]()


proc callBack(request: Request) {.async, gcsafe.} =

  var ws = WebSocket()
  var setting = loadServerSetting()

  if request.url.path == "/":
    let headers = {"Content-type": "text/html; charset=utf-8"}
    let content = readFile("./room_chat_client.html")
    await request.respond(Http200, content, headers.newHttpHeaders())

  if request.url.path == "/chat":
    try:
      ws = await openWebSocket(request, setting)

      # SubProtocol Proc（名前と部屋を取得、さらにURI decode処理を追加）
      var room = decodeUrl(request.headers["sec-websocket-protocol", 0])
      var name = decodeUrl(request.headers["sec-websocket-protocol", 1])

      ws.optional_data["room"] = $(room)
      ws.optional_data["name"] = $(name)

      if WebSockets.hasKey(ws.optional_data["room"]):
        WebSockets[ws.optional_data["room"]].add(ws)
      else:
        WebSockets[ws.optional_data["room"]] = @[ws]

      # 接続したむねを部屋の他の人に通知
      for websocket in WebSockets[ws.optional_data["room"]]:
        echo(websocket.id)
        if websocket.id != ws.id:
          await websocket.sendMessage($(%* [{"name": ws.optional_data["name"], "enter": "true"}]), 0x1)

      echo("ID: ", ws.id, ", Room: ", ws.optional_data["room"], ", Name: ", ws.optional_data["name"], " has Opened.")
    
    except:
      let message = getCurrentException()

      ws.status = ConnectionStatus.INITIAl

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()
        if receive[0] == OpCode.TEXT:
          var message: string = $(%* [{"name": ws.optional_data["name"], "message": receive[1]}])
          for websocket in WebSockets[ws.optional_data["room"]]:
            if websocket.id != ws.id:
              echo("$# => $#" % [$(ws.id), $(websocket.id)])
              await websocket.sendMessage(message, 0x1)

        if receive[0] == OpCode.CLOSE:
          # 接続を閉じたむねを部屋の他の人に通知
          for websocket in WebSockets[ws.optional_data["room"]]:
            if websocket.id != ws.id:
              await websocket.sendMessage($(%* [{"name": ws.optional_data["name"], "closing": "true"}]), 0x1)

          echo("ID: ", ws.id, " has Closed.")
          break

      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()
    
    # 接続をCloseするClientの所属する部屋
    var room: string = ws.optional_data["room"]
    try:
      if WebSockets[room].find(ws) != -1:
        WebSockets[room].delete(WebSockets[room].find(ws))

      if ws.status == ConnectionStatus.OPEN:
        ws.socket.close()
    except:
      # 変な部屋番号を持っているClientは無視する。
      discard

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)