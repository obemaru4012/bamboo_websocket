import asyncdispatch, 
       asynchttpserver, 
       asyncnet, 
       base64, 
       httpclient, 
       httpcore, 
       json,
       nativesockets, 
       net, 
       oids, 
       sequtils, 
       std/sha1, 
       strutils, 
       streams,
       tables

from errors import 
  UnknownOpCodeReceiveError,
  WebSocketHandShakePreProcessError,
  WebSocketHandShakeSubProtcolsProcedureError,
  WebSocketHandShakePostProcessProcedureError,
  WebSocketDataReceivedPostProcessError,
  WebSocketHandShakeHeaderError,
  WebSocketOtherError

from frame import Frame
from websocket import WebSocket, ConnectionStatus, OpCode
from ./private/utilities import 
  convertBinaryStrings, 
  decodeHexStrings, 
  convertRuneSequence,
  generateMaskKey

proc handshake*(host: string, client_port: int, server_port: int, setting: TableRef[string, string]): Future[WebSocket] {.async.} =
  ##[
  
  ]##
  var ws = WebSocket()
  var client = newAsyncHttpClient()
  client.headers = newHttpHeaders({
                                   "Host": "$#:$#" % [host, $(client_port)],
                                   "Origin": "http://$#:$#" % [host, $(client_port)],
                                   "Upgrade": "$#" % [setting["upgrade"]], 
                                   "Connection": "$#" % [setting["connection"]], 
                                   "Sec-WebSocket-Key": "$#" % [setting["websocket_key"]],
                                   "Sec-WebSocket-Version": "13"
                                  })

  # [TODO] HTTP"S"
  try:
    var response = await client.get("http://$#:$#/" % [host, $(server_port)])
  except:
    # [TODO] raise error.
    ws.socket = nil
    ws.status = ConnectionStatus.INITIAl
    return ws

  ws.socket = client.getSocket()
  ws.status = ConnectionStatus.OPEN
  return ws

proc getSecWebSocketAccept(sec_webSocket_key: string, magic_strings="258EAFA5-E914-47DA-95CA-C5AB0DC85B11"): string =
  ##[
  リクエストヘッダーの「Sec-WebSocket-Key」から「Sec-WebSocket-Accept」を作成する
  ]##
  var sec_websocket_accept: string = $(sha1.secureHash(sec_webSocket_key & magic_strings))
  sec_websocket_accept = base64.encode(decodeHexStrings(sec_websocket_accept))
  return $(sec_webSocket_accept)

proc getHeaderValues(header: HttpHeaders, key: string): seq[string] =
  ##[
  NimのHttpHeaderはKeyにかぶりがあると先頭の値をデフォルトで取得するため、被りがあっても全件取得を行う
  ]##
  var headers: seq[string] = @[]
  var start: int = 0
  while true:
    try:
      var value: string = header[key, start]
      headers.add(value.toLower())
      start += 1
    except IndexDefect:
      # 取得できなくなるまで
      break

  return headers

proc loadServerSetting*(path="./setting.json"): TableRef[string, string] =
  ##[
  設定ファイルを読み込んでTableRefに変換する
  ]##
  let table = newTable[string, string]()
  let settings = parseFile(path)

  for setting in settings.keys():
      var tmp = $(settings[setting])
      table[setting] = tmp.strip(chars={'"', ' '})

  return table

proc preProcessProc*(ws: WebSocket, headers: HttpHeaders): bool {.gcsafe.}= 
  ##[
  
  ]##
  return true

proc subProtcolsProc*(ws: WebSocket, sub_protocol: seq[string]): bool {.gcsafe.} = 
  ##[

  ]##
  return true

proc postProcessProc*(ws: WebSocket): bool {.gcsafe.} = 
  ##[

  ]##
  return true

proc openWebSocket*(request: Request,
                    setting: TableRef[string, string], 
                    preProcessProc: proc (ws: WebSocket, headers: HttpHeaders): bool = preProcessProc,
                    subProtcolsProc: proc (ws: WebSocket, sub_protocol: seq[string]): bool = subProtcolsProc,
                    postProcessProc: proc (ws: WebSocket): bool = postProcessProc):
                    Future[WebSocket] {.async.} =
  ##[

  ]##
  var ws = WebSocket(
    id: "",
    socket: nil,
    status: ConnectionStatus.INITIAl,
    sec_websocket_accept: "",
    sec_websocket_protocol: @[],
    version: "",
    upgrade: "",
    connection: "",
    optional_data: initTable[string, string]()
  )

  # ハンドシェイク開始
  ws.status = ConnectionStatus.CONNECTING

  # ハンドシェイクリクエスト解析
  var headers: HttpHeaders = request.headers

  # 高階関数 → 前処理
  if not ws.preProcessProc(headers):
    raise newException(WebSocketHandShakePreProcessError, "WebSocketハンドシェイク時の前処理（preProcessProc）でエラーが発生しています。")

  # Sec-WebSocket-Version: 現行の「13」ではない場合×
  if not headers.hasKey("sec-websocket-version"): 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダーに「sec-websocket-version」が見つかりません。")

  var sec_websocket_version = getHeaderValues(headers, "sec-websocket-version")
  if not all(sec_websocket_version, proc (x: string): bool = x == setting["websocket_version"]): 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダー「sec-websocket-version」の値が$#ではありません。（$#）" % [setting["websocket_version"], headers["sec-websocket-version"]])

  let version = sec_websocket_version[sec_websocket_version.low()]
  ws.version = version

  # Upgrade: 「websocket」が含まれない場合×
  if not headers.hasKey("Upgrade") : 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダーに「Upgrade」が見つかりません。")

  var upgrades = getHeaderValues(headers, "Upgrade")
  var upgrade_checker = proc (x: string): bool = x == setting["upgrade"]
  if not any(upgrades, upgrade_checker): 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダー「Upgrade」の値が$#ではありません。（$#）" % [setting["upgrade"], headers["Upgrade"]])

  let upgrade = setting["upgrade"]
  ws.upgrade = upgrade

  # Connection: 「upgrade」が含まれない場合×
  if not headers.hasKey("Connection") : 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダーに「Connection」が見つかりません。")

  var connections = getHeaderValues(headers, "Connection")
  var connections_checker = proc (x: string): bool = x == setting["connection"]
  if not any(connections, connections_checker): 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダー「Connection」の値が$#ではありません。（$#）" % [setting["connection"], headers["Connection"]])

  let connection = setting["connection"]
  ws.connection = connection

  # Sec-WebSocket-Key: 存在しない場合×
  if not headers.hasKey("Sec-WebSocket-Key"): 
    raise newException(WebSocketHandShakeHeaderError, "WebSocketハンドシェイクリクエストヘッダーに「Sec-WebSocket-Key」が見つかりません。")
  
  var sec_websocket_accept: string = getSecWebSocketAccept($headers["Sec-WebSocket-Key"].strip(), setting["magic_strings"])
  ws.sec_websocket_accept = sec_websocket_accept

  # レスポンス用ソケット取得
  ws.socket = request.client
  # レスポンスヘッダー文字列作成
  var response = "HTTP/1.1 101 Switching Protocols" & "\n"
  response.add("Sec-WebSocket-Accept: " & sec_websocket_accept & "\n")
  response.add("Connection: " & connection & "\n")
  response.add("Upgrade: " & upgrade & "\n")

  # Sec-WebSocket-Protocol: が存在する場合（なくてもよい）
  # ここに送付される値によってサーバの種類をハンドルする。
  if headers.hasKey("Sec-WebSocket-Protocol"): 
    var sub_protocol = getHeaderValues(headers, "Sec-WebSocket-Protocol")
    response.add("Sec-Websocket-Protocol: " & sub_protocol[sub_protocol.low()] & "\n")

    ws.sec_websocket_protocol = sub_protocol

    # Sec-WebSocket-Protocolの値に基づいて独自の処理を行う
    if not ws.subProtcolsProc(sub_protocol):
      raise newException(WebSocketHandShakeSubProtcolsProcedureError, "WebSocketハンドシェイク時の独自処理（subProtcolsProc）でエラーが発生しています。")

  # お尻に改行コード追加
  response.add("\n")

  # ハンドシェイク
  try:
    await ws.socket.send(response)
  except:
    raise newException(WebSocketOtherError, "WebSocketハンドシェイクレスポンスの送信でエラーが発生しています。")

  # 高階関数 → 追加処理
  if not ws.postProcessProc():
    raise newException(WebSocketHandShakePostProcessProcedureError, "WebSocketハンドシェイク時の後処理（postProcessProc）でエラーが発生しています。")

  ws.id = $(genOid())
  ws.status = ConnectionStatus.OPEN # ここでOPENに設定しておき、「newAsyncHttpServer」で回す

  return ws

proc sendMessage*(ws: WebSocket, message: string, opcode: uint8, per_length: int=3000, is_masked: bool=false): Future[void] {.async.} =
  ##[

  ]##
  # 1回に送信するデータ量ごとに分割する。デフォルトはおおよそ10KB分の文字数。
  var messages: seq[string]
  messages = convertRuneSequence(message, per_length)

  if ws.status != ConnectionStatus.OPEN: 
    raise newException(WebSocketOtherError, "端点との接続が確立されていません。")

  let length = messages.len() - 1
  for index, m in messages:
    var frame = Frame()
    # 一発で送信される場合
    if length == 0:
      frame.FIN = true # 一発終了
      frame.RSV1 = false # 基本0
      frame.RSV2 = false # 基本0
      frame.RSV3 = false # 基本0
      frame.OPCODE = OpCode(opcode)
      frame.MASK = is_masked # SERVER => CLIENTの場合はFalse、CLIENT => SERVERの場合はTrueが基本線
      frame.DATA = m # 送信データ

    # 分割して送信される場合（初回）
    elif length > 0 and index == 0:
      frame.FIN = false # 一発終了
      frame.RSV1 = false # 基本0
      frame.RSV2 = false # 基本0
      frame.RSV3 = false # 基本0
      frame.OPCODE = OpCode(opcode)
      frame.MASK = is_masked # SERVER => CLIENTの場合はFalseでよし
      frame.DATA = m # 送信データ

    # 分割して送信される場合（初回～最後の1つ前まで）
    elif length > 0 and length > index and index != 0:
      frame.FIN = false # 一発終了
      frame.RSV1 = false # 基本0
      frame.RSV2 = false # 基本0
      frame.RSV3 = false # 基本0
      frame.OPCODE = OpCode.CONTINUATION
      frame.MASK = is_masked # SERVER => CLIENTの場合はFalseでよし
      frame.DATA = m # 送信データ

    elif length > 0 and length == index:
      frame.FIN = true # 一発終了
      frame.RSV1 = false # 基本0
      frame.RSV2 = false # 基本0
      frame.RSV3 = false # 基本0
      frame.OPCODE = OpCode.CONTINUATION
      frame.MASK = is_masked # SERVER => CLIENTの場合はFalseでよし
      frame.DATA = m # 送信データ

    var stream = newStringStream()

    # 先頭1bitから8bit
    var bytes_0_7: uint8
    # 先頭4bit
    if frame.FIN:
      bytes_0_7 = 0x80 # 1000_0000
    
    if frame.RSV1:
      bytes_0_7 = bytes_0_7 or 0x40 # 1100_0000

    if frame.RSV2:
      bytes_0_7 = bytes_0_7 or 0x20 # 1x10_0000

    if frame.RSV3:
      bytes_0_7 = bytes_0_7 or 0x10 # 1xx1_0000

    # OPCODE（下4桁）
    bytes_0_7 = bytes_0_7 or frame.OPCODE.uint8()
    stream.write(bytes_0_7)

    # 先頭9bitから16bit
    var bytes_8_15: uint8
    if frame.MASK:
      bytes_8_15 = 0x80
    else:
      bytes_8_15 = 0x00

    var data_length = frame.DATA.len()
    if data_length <= 125:
      bytes_8_15 = bytes_8_15 or data_length.uint8()
    elif data_length == 126:
      bytes_8_15 = bytes_8_15 or 126.uint8()
    else:
      bytes_8_15 = bytes_8_15 or 127.uint8()
    stream.write(bytes_8_15)

    if data_length == 126:
      # 後続2byteが16bit無符号整数に解釈されて長さになる
      var length_16 = data_length.uint16()
      # 右シフト2回で先頭から2回追加（uint8に変換すれば余計なものはそぎ落とされる）
      stream.write((length_16 shr 8).uint8()) # 先頭8bit
      stream.write(length_16.uint8())         # お尻8bit

    elif data_length > 0xffff:
      # 後続8byteが長さなのでuint64にして突っ込む
      var length_16_80 = data_length.uint64()
      # 右シフト8回で先頭から8回追加（uint8に変換すれば余計なものはそぎ落とされる）
      stream.write(((length_16_80 shr 56) and 0x0000_0000_0000_00ff).uint8())
      stream.write(((length_16_80 shr 48) and 0x0000_0000_0000_00ff).uint8())
      stream.write(((length_16_80 shr 40) and 0x0000_0000_0000_00ff).uint8())
      stream.write(((length_16_80 shr 32) and 0x0000_0000_0000_00ff).uint8())
      stream.write(((length_16_80 shr 24) and 0x0000_0000_0000_00ff).uint8())
      stream.write(((length_16_80 shr 16) and 0x0000_0000_0000_00ff).uint8())
      stream.write(((length_16_80 shr 8) and 0x0000_0000_0000_00ff).uint8())
      stream.write((length_16_80 and 0x0000_0000_0000_00ff).uint8())

    # マスク
    if frame.MASK:
      # サーバーからの送信は基本マスクはしない
      var mask_key :seq[char] = generateMaskKey()
      var masked_m :string

      # 結果のデータ[i] = 元のデータ[i] xor key [i mod 4]
      for index in countup(0, m.len() - 1):
        masked_m.add((m[index].uint8() xor mask_key[index mod 4].uint8()).char())
      
      stream.write(mask_key[0].uint8())
      stream.write(mask_key[1].uint8())
      stream.write(mask_key[2].uint8())
      stream.write(mask_key[3].uint8())
      stream.write(masked_m)
    
    else:
      # ペイロード
      stream.write(m)

    # 送信
    stream.setPosition(0)

    try:
      await ws.socket.send(stream.readAll())
    except: # その他の例外をキャッチ
      await ws.sendMessage("", 0x8) # Close
      raise newException(WebSocketOtherError, "データ送信時に未知のエラーが発生しました。")

proc receiveFrame(ws: WebSocket): Future[Frame] {.async.} =
  ##[

  ]##
  var frame = Frame()
  var receive: string
  receive = await ws.socket.recv(2) # 2Byte

  let bytes_0_7: string = convertBinaryStrings(receive[0]) # 逐次2進数に変換して判定

  frame.FIN = bytes_0_7[0] == '1'
  frame.RSV1 = bytes_0_7[1] == '1'
  frame.RSV2 = bytes_0_7[2] == '1'
  frame.RSV3 = bytes_0_7[3] == '1'
  
  case bytes_0_7[4..7]
    of "0000":
      frame.OPCODE = OpCode.CONTINUATION
    of "0001":
      frame.OPCODE = OpCode.TEXT
    of "0010":
      frame.OPCODE = OpCode.BINARY
    of "1000":
      frame.OPCODE = OpCode.CLOSE
    of "1001":
      frame.OPCODE = OpCode.PING
    of "1010":
      frame.OPCODE = OpCode.PONG
    else:
      # 未知なOpCodeが受信された場合は接続をCloseする
      ws.status = ConnectionStatus.CLOSING
      raise newException(UnknownOpCodeReceiveError, "未知なOpCodeを受信しました。（$#）" % [$(bytes_0_7[4..7])])

  let bytes_8_15: string = convertBinaryStrings(receive[1]) # 逐次2進数に変換して判定
  frame.MASK = bytes_8_15[0] == '1'
  # if not frame.MASK:
    # マスクされていないフレームを受信した際には接続をCloseする
  #  raise newException(NoMaskedFrameReceiveError, "マスクされていないフレームを受信しました。（$#）" % [$(bytes_8_15[0])])

  # ペイロードの長さ
  frame.PAYLOAD_LENGTH = fromBin[int8]("0b" & bytes_8_15[1..7])
  let payload_length = fromBin[int8]("0b" & bytes_8_15[1..7])

  var true_payload_length: uint = 0
  # 真のペイロードの長さ
  if payload_length == 0x7e:
    # 126
    var length = await ws.socket.recv(2)
    true_payload_length = cast[ptr uint16](length[0].addr)[].htons()

  elif payload_length == 0x7f:
    # 127
    var length = await ws.socket.recv(8)
    true_payload_length = cast[ptr uint32](length[4].addr)[].htonl()

  else:
    # 0~125まで
    true_payload_length = uint8(payload_length)

  # マスクキー取得
  if frame.MASK:
    frame.MASK_KEY = await ws.socket.recv(4)
  
  # 素のデータを引っ張ってくる
  var data = await ws.socket.recv(int true_payload_length)

  # 非マスク化
  if frame.MASK:
    for index in countup(0, data.len() - 1):
      frame.DATA.add($(data[index].uint8() xor frame.MASK_KEY[index mod 4].uint8()).char())
  else:
    frame.DATA.add(data)

  # echo(frame)
  return frame

proc postMessageReceivedProc*(ws: WebSocket, receive_result: tuple[opcode: OpCode, message: string]): bool {.gcsafe.} =
  ##[

  ]##
  return true

proc receiveMessage*(ws: WebSocket, postMessageReceivedProc: proc (ws: WebSocket, receive_result: tuple[opcode: OpCode, message: string]): bool = postMessageReceivedProc): Future[tuple[opcode: OpCode, message: string]] {.async.} =
  ##[

  ]##
  var receive_result: tuple[opcode: OpCode, message: string]
  var code: OpCode
  var message: string

  var frame = Frame()
  try:
    frame = await ws.receiveFrame()
    message &= frame.DATA

    while frame.FIN == false:
      frame = await ws.receiveFrame()
      # 結果は逐一保存
      code = frame.OpCode
      message &= frame.DATA

      if frame.OpCode != CONTINUATION:
        raise newException(UnknownOpCodeReceiveError, "継続以外のOpCodeを受信しました。（$#）" % [$(frame.OpCode)])

  except UnknownOpCodeReceiveError:
    await ws.sendMessage("", 0x8) # Close
    raise newException(UnknownOpCodeReceiveError, "未知のOPCODEを持つデータを受信しました。")
  
  #except NoMaskedFrameReceiveError:
  #  await ws.sendMessage("", 0x8) # Close
  #  raise newException(NoMaskedFrameReceiveError, "マスクされていないデータを受信しました。")

  except: # その他の例外をキャッチ
    await ws.sendMessage("", 0x8) # Close
    raise newException(WebSocketOtherError, "データ受信時に未知のエラーが発生しました。")

  # OpCodeで分岐させる
  if frame.OPCODE == OpCode.CLOSE:
    # Closeフレームを受信した端点は、それまでにCloseフレームを送信していなかったならば、
    # 応答として Close フレームを送信しなければならない。
    await ws.sendMessage("", 0x8) # Close
    ws.status = ConnectionStatus.CLOSED
    ws.socket.close()
    code = OpCode.CLOSE

  if frame.OPCODE == OpCode.PING:
    # PINGフレームを受信したら即座にPONGフレームを返す
    await ws.sendMessage("", 0xa)
    code = OpCode.PING

  if frame.OPCODE == OpCode.PONG:
    code = OpCode.PONG

  if frame.OPCODE == OpCode.TEXT:
    code = OpCode.TEXT

  if frame.OPCODE == OpCode.BINARY:
    # [TODO] いつか実装したいね
    code = OpCode.BINARY

  if not ws.postMessageReceivedProc(receive_result):
    raise newException(WebSocketDataReceivedPostProcessError, "WebSocketデータ受信時の後処理（postMessageReceivedProcedure）でエラーが発生しています。")

  receive_result = (code, message)
  return receive_result