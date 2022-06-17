import asyncnet
import tables

type

  # 接続ステータス
  ConnectionStatus* = enum
    INITIAl     = 0 # 初期状態
    CONNECTING  = 1 # 接続中...
    OPEN        = 2 # 接続済
    CLOSING     = 3 # 切断中...
    CLOSED      = 4 # 切断済

  # WebSocketオブジェクト
  WebSocket* = ref object
    id*: string                           ## 接続ID（OID）
    socket*: AsyncSocket                  ## 接続本体
    status*: ConnectionStatus             ## 接続ステータス
    sec_websocket_accept*: string         ## Sec-WebSocket-Accept
    sec_websocket_protocol*: seq[string]  ## Sec-WebSocket-Protocol
    version*: string                      ## バージョン（現行は13）
    upgrade*: string                      ## Upgradeリクエスト
    connection*: string                   ## Connectionリクエスト
    optional_data*: Table[string, string] ## 追加情報（接続名などを追加の情報をTable保持）