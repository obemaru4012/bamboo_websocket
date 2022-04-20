import opcode

type 
  # 受信オブジェクト
  ReceiveResult* = object # 受信結果を格納する
    OPCODE*: Opcode        # 受信したOpCode
    MESSAGE*: string       # 受信したメッセージ