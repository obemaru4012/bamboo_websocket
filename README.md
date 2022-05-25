#### 🐼Bamboo-WebSocket🌿
![FLgp3pCakAAG1JU](https://user-images.githubusercontent.com/88951380/158893548-13a50cea-92ff-4506-acb8-202e5e5e317e.png)
  
* 100%NimによるWebSocketサーバーのシンプルな実装です。
* 竹を割ったようにさっぱりとした実装を目指しています。
* チャットサーバー、ゲーム用のサーバーを簡単に作成できることを目指しています。
* Bambooの詳細な説明と利用方法についてはwikiに記載予定です。
* 最新バージョンは**0.2.1**になります。
* [README in English.](https://github.com/obemaru4012/bamboo_websocket/blob/master/README_en.md)
  
  
#### 🖥Dependency
`requires "nim >= 1.4.8"`
  
  
#### 👩‍💻Setup
```bash
$ nimble install bamboowebsocket@0.2.1
```
  
  
#### 🤔Description
* Nim標準で提供されている[asynchttpserver](https://nim-lang.org/docs/asynchttpserver.html)での利用を想定しています。
  
  
#### 🤙Usage
##### 🐥Echo Server
* 以下は、クライアントから受信したメッセージをエコーするサーバーです。

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
  
* サーバー用の設定ファイルを記述するjsonファイルをサーバーファイル（ehco_server.nim等）と同じ場所に配置する必要があります。
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
  
  
* ディレクトリ配置は以下の画像のようになります。
![001](https://user-images.githubusercontent.com/88951380/165452751-9cb833f9-2214-4ea6-bde0-1818e1127d57.png)

* echo_server.nimをコンパイル後に実行します。
```bash
$ nim c -r echo_server.nim
```
  
![002](https://user-images.githubusercontent.com/88951380/165452764-32cb29a6-a2e3-42f9-a5a5-5926d57a462a.gif)
  
  
#### 😏Advanced Usage
##### 🐄Chat Server
[TODO]
  
  
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
