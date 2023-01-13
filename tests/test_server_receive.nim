# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.
import unittest
import asyncdispatch, 
       asynchttpserver, 
       httpcore, 
       json,
       nativesockets, 
       net, 
       strutils, 
       tables,
       uri

from websocket import WebSocket, Opcode
from bamboo_websocket import 
  handshake,
  openWebSocket, 
  receiveMessage, 
  sendMessage

# ダミー設定テーブル作成
var setting = %* {
               "websocket_version": "13", 
               "upgrade": "websocket", 
               "connection": "upgrade", 
               "websocket_key": "dGhlIHNhbXBsZSBub25jZQ==",
               "magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
               "mask_key_seeder": "514902776"
              }.newTable()


proc sendMessageCallBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()
  var message {.global.} : tuple[opcode: Opcode, message: string]
  if request.url.path == "/":
    try:
      ws = await openWebSocket(request, setting)
      message = await ws.receiveMessage()
      await ws.sendMessage(message[1], 0x1, 1000, true)
    except:
      discard

suite "receive message":

  test "receive message":
    var server = newAsyncHttpServer()
    asyncCheck server.serve(Port(9001), sendMessageCallBack, "localhost")
    var ws = waitFor handshake("localhost", 80, 9001, setting)
    waitFor ws.sendMessage("ぶんぶんぶんなぐり！", 0x1, 1000, true)
    var r = waitFor ws.receiveMessage()
    check r[1] == "ぶんぶんぶんなぐり！"

