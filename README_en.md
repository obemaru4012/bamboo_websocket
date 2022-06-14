#### 🐼Bamboo-WebSocket🌿
![FLgp3pCakAAG1JU](https://user-images.githubusercontent.com/88951380/158893548-13a50cea-92ff-4506-acb8-202e5e5e317e.png)
  
* This is a simple implementation of a WebSocket server with 100% Nim.
* We aim for a refreshing implementation, like splitting bamboo.
* The goal of this project is to make it easy to create chat and gaming servers.
* A detailed description of Bamboo and how to use it will be included in the wiki.
* The latest version is **0.2.4**.
* [README in Japanese.](https://github.com/obemaru4012/bamboo_websocket/blob/master/README.md)
  
#### 🖥Dependency
`requires "nim >= 1.4.8"`
  
  
#### 👩‍💻Setup
```bash
$ nimble install bamboowebsocket@0.2.4
```
  
  
#### 🤔Description
* It is intended to be used with [asynchttpserver](https://nim-lang.org/docs/asynchttpserver.html), which is provided in the Nim standard.
  
  
#### 🤙Usage
##### 🐥Echo Server
* The following is a server that echoes messages received from clients.

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

from bamboo_websocket/connection_status import ConnectionStatus
from bamboo_websocket/opcode import Opcode
from bamboo_websocket/websocket import WebSocket
from bamboo_websocket/receive_result import ReceiveResult
from bamboo_websocket/bamboo_websocket import 
  loadServerSetting, 
  openWebSocket, 
  receiveMessage, 
  sendMessage

# ./setting.jsonをサーバーと同じ場所に配置
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
          await ws.sendMessage(receive.MESSAGE, 0x1)

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

```
  
* A json file describing the configuration file for the server must be placed in the same location as the server file (e.g. ehco_server.nim)。
```json
{
    "websocket_version" : "13",
    "upgrade": "websocket",
    "connection": "upgrade",
    "websocket_key": "dGhlIHNhbXBsZSBub25jZQ==",
    "magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
    "mask_key_seeder": "514902776",
}
```
  
  
* The directory arrangement is shown in the following image.
![001](https://user-images.githubusercontent.com/88951380/165452751-9cb833f9-2214-4ea6-bde0-1818e1127d57.png)

* Run echo_server.nim after compilation.
```bash
$ nim c -r echo_server.nim
```
  
![002](https://user-images.githubusercontent.com/88951380/165452764-32cb29a6-a2e3-42f9-a5a5-5926d57a462a.gif)
  
  
#### 😏Advanced Usage
##### 🐄Chat Server
* The following code is a server that enables chatting between each client.

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

```
  
* A json file（setting.json） describing the configuration file for the server must be placed in the same location as the server file (e.g. chat_server.nim)。
```json
{
    "websocket_version" : "13",
    "upgrade": "websocket",
    "connection": "upgrade",
    "websocket_key": "dGhlIHNhbXBsZSBub25jZQ==",
    "magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
    "mask_key_seeder": "514902776",
}
```
  
  

* Run chat_server.nim after compilation.
```bash
$ nim c -r chat_server.nim
```
  
![004](https://user-images.githubusercontent.com/88951380/173271545-15a22b29-7825-4b16-944e-ba1bc92b92ee.gif)
  
  
##### 🐭Game Server
[TODO]
  
  
#### 📝Author
* [omachi-satoshi](https://github.com/omachi-satoshi)
* [obemaru4012](https://github.com/obemaru4012)
  
  
#### 📖References
* [RFC 6455 - The WebSocket Protocol （日本語訳）](https://triple-underscore.github.io/RFC6455-ja.html)
* [WebSocket サーバーの記述 - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/WebSockets_API/Writing_WebSocket_servers)
* [WebSocket クライアントアプリケーションの記述 - Web API | MDN](https://developer.mozilla.org/ja/docs/Web/API/WebSockets_API/Writing_WebSocket_client_applications)
* [Nim Package Directory](https://nimble.directory/pkg/bamboowebsocket)
