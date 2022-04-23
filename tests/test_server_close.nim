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
       nativesockets, 
       net, 
       strutils, 
       tables,
       uri

from opcode import OpCode
from websocket import WebSocket, WebSockets
from receive_result import ReceiveResult
from bamboo_websocket import 
  handshake,
  openWebSocket, 
  receiveMessage, 
  sendMessage

# ダミー設定テーブル作成
var setting = {
               "websocket_version": "13", 
               "upgrade": "websocket", 
               "connection": "upgrade", 
               "websocket_key": "dGhlIHNhbXBsZSBub25jZQ==",
               "magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11",
               "mask_key_seeder": "514902776"
              }.newTable()


proc sendMessageCallBack(request: Request) {.async, gcsafe.} =
  var ws = WebSocket()
  var message {.global.} : ReceiveResult 
  if request.url.path == "/":
    try:
      ws = await openWebSocket(request, setting)
      message = await ws.receiveMessage()
    except:
      discard

suite "receive close":

  test "receive close":
    var server = newAsyncHttpServer()
    asyncCheck server.serve(Port(9001), sendMessageCallBack, "localhost")
    var ws = waitFor handshake("localhost", 80, 9001, setting)
    waitFor ws.sendMessage("", 0x8, 1000, true)
    var r = waitFor ws.receiveMessage()
    check r.OPCODE == OpCode.CLOSE

