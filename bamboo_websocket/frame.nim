##[
fram.nim

Frame format:
​​
      0                   1                   2                   3
      0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
     +-+-+-+-+-------+-+-------------+-------------------------------+
     |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
     |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
     |N|V|V|V|       |S|             |   (if payload len==126/127)   |
     | |1|2|3|       |K|             |                               |
     +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
     |     Extended payload length continued, if payload len == 127  |
     + - - - - - - - - - - - - - - - +-------------------------------+
     |                               |Masking-key, if MASK set to 1  |
     +-------------------------------+-------------------------------+
     | Masking-key (continued)       |          Payload Data         |
     +-------------------------------- - - - - - - - - - - - - - - - +
     :                     Payload Data continued ...                :
     + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
     |                     Payload Data continued ...                |
     +---------------------------------------------------------------+
]##
from websocket import OpCode

type
  # フレームオブジェクト
  Frame* = object
  # 受信継続のためにnil許容とする
    FIN*: bool            # メッセージのお尻かどうかをチェック(0: お尻じゃない, 1: お尻)
    RSV1*: bool           # 基本0で0以外が受信されたら「通信を閉じるべし！」
    RSV2*: bool           # 基本0で0以外が受信されたら「通信を閉じるべし！」
    RSV3*: bool           # 基本0で0以外が受信されたら「通信を閉じるべし！」
    OPCODE*: Opcode       # ペイロードがどんなものかを定義
    MASK*: bool           # データがマスクされているかチェック「1」の場合はペイロード内にマスク用キーがあるのでそれを利用する
                          # C => Sの場合は基本「1」であることが約束されている
    PAYLOAD_LENGTH*: int8 # 0 〜 125 => それが長さ, 
                          # 126 => 後続の2バイトが16bit無符号整数に解釈されてペイロードの長さになる
                          # 127 => 後続の8バイトが64bit無符号整数（最上位bitは0でなければならない）に解釈されてペイロードの長さになる
    MASK_KEY*: string     # マスクキー
    DATA*: string         # ペイロードデータ