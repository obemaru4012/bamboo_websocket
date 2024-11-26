#### 🐼Bamboo-WebSocket🌿

![FLgp3pCakAAG1JU](https://user-images.githubusercontent.com/88951380/158893548-13a50cea-92ff-4506-acb8-202e5e5e317e.png)

- 100%Nim による WebSocket サーバーのシンプルな実装です。
- 竹を割ったようにさっぱりとした実装を目指しています。
- チャットサーバー、ゲーム用のサーバーを簡単に作成できることを目指しています。
- Bamboo の詳細な説明と利用方法については wiki に記載予定です。
- 最新バージョンは**0.3.3**になります。
- [README in English.](https://github.com/obemaru4012/bamboo_websocket/blob/master/README.md)

#### 🖥Dependency

`requires "nim >= 1.4.8"`

#### 👩‍💻Setup

```bash
nimble install bamboowebsocket@0.3.2
```

#### 🤔Description

- Nim 標準で提供されている[asynchttpserver](https://nim-lang.org/docs/asynchttpserver.html)での利用を想定しています。

#### 🤙Usage

##### 🐥Echo Server

- 以下は、クライアントから受信したメッセージをエコーするサーバーです。
- 以下のコードは bamboowebsocket/example/echo_example ディレクトリ内に置いてあります。

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
from bamboo_websocket/bamboo_websocket import
  handshake,
  loadServerSetting,
  openWebSocket,
  receiveMessage,
  sendMessage

var setting = loadServerSetting()

proc callBack(request: Request) {.async, gcsafe.} =
  var ws: WebSocket

  if request.url.path == "/":
    let headers = {"Content-type": "text/html; charset=utf-8"}
    let content = readFile("./echo_client.html")
    await request.respond(Http200, content, headers.newHttpHeaders())

  if request.url.path == "/chat":
    try:
      ws = await openWebSocket(request, setting)
    except:
      let error = getCurrentException()
      let message = getCurrentException()
      echo(message.msg)

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

- サーバー用の設定ファイルを記述する json ファイルをサーバーファイル（ehco_server.nim 等）と同じ場所に配置する必要があります。

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

- ディレクトリ配置は以下の画像のようになります。
  ![001](https://user-images.githubusercontent.com/88951380/165452751-9cb833f9-2214-4ea6-bde0-1818e1127d57.png)

- echo_server.nim をコンパイル後に実行します。

```bash
nim c -r echo_server.nim
```

![002](https://user-images.githubusercontent.com/88951380/165452764-32cb29a6-a2e3-42f9-a5a5-5926d57a462a.gif)

#### 😏Advanced Usage

##### 🐄Chat Server

- 以下は、各クライアント間でのチャットを実現するサーバーです。
- 以下のコードは bamboowebsocket/example/chat_example ディレクトリ内に置いてあります。

```nim
# chat_server.nim

import asyncdispatch,
       asynchttpserver,
       asyncnet,
       base64,
       httpcore,
       json,
       nativesockets,
       net,
       strutils,
       tables,
       uri

from bamboo_websocket/websocket import WebSocket, ConnectionStatus, OpCode
from bamboo_websocket/bamboo_websocket import loadServerSetting, openWebSocket, receiveMessage, sendMessage

var setting = loadServerSetting()
var WebSockets: seq[WebSocket] = newSeq[WebSocket]()

proc callBack(request: Request) {.async, gcsafe.} =

  proc subProtocolProcess(ws: WebSocket, request: Request): bool {.gcsafe.} =
    try:
      var sub_protocol = request.headers["sec-websocket-protocol", 0]
      ws.optional_data["name"] = $(sub_protocol)

    except IndexDefect:
      return false
    return true

  var ws = WebSocket()

  if request.url.path == "/":
    let headers = {"Content-type": "text/html; charset=utf-8"}
    let content = readFile("./chat_client.html")
    await request.respond(Http200, content, headers.newHttpHeaders())

  if request.url.path == "/chat":
    try:
      ws = await openWebSocket(request, setting, subProtocolProcess=subProtocolProcess)
      WebSockets.add(ws)
      echo("ID: ", ws.id, ", Tag: ", ws.optional_data["name"], " has Opened.")
    except:
      var e = getCurrentException()
      var msg = getCurrentExceptionMsg()
      echo(msg)
      echo msg

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

- サーバー用の設定ファイルを記述する json ファイル（setting.json）をサーバーファイル（chat_server.nim 等）と同じ場所に配置する必要があります。

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

- chat_server.nim をコンパイル後に実行します。

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
