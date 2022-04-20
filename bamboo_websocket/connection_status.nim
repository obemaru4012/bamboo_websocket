type
  # 接続ステータス
  ConnectionStatus* = enum
    INITIAl     = 0 # 初期状態
    CONNECTING  = 1 # 接続中...
    OPEN        = 2 # 接続済
    CLOSING     = 3 # 切断中...
    CLOSED      = 4 # 切断済