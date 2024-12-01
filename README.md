#### 🐼Bamboo-WebSocket🌿

![FLgp3pCakAAG1JU](https://user-images.githubusercontent.com/88951380/158893548-13a50cea-92ff-4506-acb8-202e5e5e317e.png)

- This is a lightweight WebSocket server implemented entirely in Nim.
- Our goal is to create a clean and elegant implementation, inspired by the simplicity of splitting bamboo.
- This project aims to simplify the creation of chat and gaming servers.
- [TODO] Detailed documentation about Bamboo and its usage will be provided in the wiki.
- The latest release is **0.3.3**.
- [README in Japanese.](https://github.com/obemaru4012/bamboo_websocket/blob/master/README_ja.md)

#### 🖥Dependency

`requires "nim >= 1.4.8"`

#### 👩‍💻Setup

```bash
nimble install bamboowebsocket@0.3.2
```

#### 🤔Description

- It is intended to be used with [asynchttpserver](https://nim-lang.org/docs/asynchttpserver.html), which is provided in the Nim standard.

#### 🤙Usage

##### 🐥Echo Server

- The following is a server that echoes messages received from clients.
- The following code can be found in the bamboowebsocket/example/echo_example directory.

```nim
# echo_server.nim

import asyncdispatch,
       asynchttpserver,
       asyncnet,
       httpcore,
       nativesockets,
       net,
       strutils,
       uri

from bamboo_websocket/websocket import WebSocket, ConnectionStatus, OpCode
from bamboo_websocket/bamboo_websocket import loadServerSetting, openWebSocket, receiveMessage, sendMessage

proc callBack(request: Request) {.async, gcsafe.} =
  var ws: WebSocket
  var setting = loadServerSetting()

  if request.url.path == "/":
    let headers = {"Content-type": "text/html; charset=utf-8"}
    let content = readFile("./echo_client.html")
    await request.respond(Http200, content, headers.newHttpHeaders())

  if request.url.path == "/chat":
    try:
      ws = await openWebSocket(request, setting)
    except:
      let message = getCurrentException()

    while ws.status == ConnectionStatus.OPEN:
      try:
        let receive = await ws.receiveMessage()

        if receive[0] == OpCode.TEXT:
          echo("ID: ", ws.id, " echo back.")
          await ws.sendMessage(receive[1], 0x1, 3000, true)

        if receive[0] == OpCode.CLOSE:
          echo("ID: ", ws.id, " has Closed.")
          break

      except:
        ws.status = ConnectionStatus.CLOSED
        ws.socket.close()

    ws.socket.close()

if isMainModule:
  var server = newAsyncHttpServer()
  waitFor server.serve(Port(9001), callBack)

```

- A json file describing the configuration file for the server must be placed in the same location as the server file (e.g. ehco_server.nim)。

```json
{
  "websocket_version": "13",
  "upgrade": "websocket",
  "connection": "upgrade",
  "websocket_key": "dGhlIHNhbXBsZSBub25jZQ==",
  "magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
  "mask_key_seeder": "514902776"
}
```

- Run echo_server.nim after compilation.

```bash
nim c -r echo_server.nim
```

![002](https://user-images.githubusercontent.com/88951380/165452764-32cb29a6-a2e3-42f9-a5a5-5926d57a462a.gif)

#### 😏Advanced Usage

##### 🐄Chat Server

- The following code is a server that enables chatting between each client.
- The following code can be found in the bamboowebsocket/example/chat_example directory.

```nim
# chat_server.nim

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

```

- A json file（setting.json） describing the configuration file for the server must be placed in the same location as the server file (e.g. chat_server.nim)。

```json
{
  "websocket_version": "13",
  "upgrade": "websocket",
  "connection": "upgrade",
  "websocket_key": "dGhlIHNhbXBsZSBub25jZQ==",
  "magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
  "mask_key_seeder": "514902776"
}
```

- Run chat_server.nim after compilation.

```bash
nim c -r chat_server.nim
```

![004](https://user-images.githubusercontent.com/88951380/173271545-15a22b29-7825-4b16-944e-ba1bc92b92ee.gif)

##### 🐭Game Server

[TODO]

#### 📝Author

- [obemaru4012](https://github.com/obemaru4012)

#### 📖References

- [RFC 6455 - The WebSocket Protocol （日本語訳）](https://triple-underscore.github.io/RFC6455-ja.html)
- [WebSocket サーバーの記述 - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/WebSockets_API/Writing_WebSocket_servers)
- [WebSocket クライアントアプリケーションの記述 - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications)
- [Nim Package Directory](https://nimble.directory/pkg/bamboowebsocket)
