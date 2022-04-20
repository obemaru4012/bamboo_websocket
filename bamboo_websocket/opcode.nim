type
  # 制御フレーム（0x8, 0x, 0xa）とデータフレーム（0x1, 0x2）
  Opcode* = enum
    CONTINUATION = 0x0 # 継続フレーム
    TEXT         = 0x1 # テキストフレーム
    BINARY       = 0x2 # バイナリフレーム
    CLOSE        = 0x8 # クローズフレーム
    PING         = 0x9 # ピン！
    PONG         = 0xa # ポン！
    EXCEPT       = 0xf # 例外！