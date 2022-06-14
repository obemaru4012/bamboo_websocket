import asyncnet
import connection_status
import tables

type
  WebSocketC* = ref object
    socket*: AsyncSocket            ## 接続本体
    status*: ConnectionStatus       ## 接続ステータス

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

#[
WebSocket Objectを保持する\n
]#
var WebSockets*: seq[WebSocket] = newSeq[WebSocket]() 

#[
WebSocket Objectをグループ分けして管理する.\n
属性:\n
]#
var WebSocketsGroups*: Table[string, seq[WebSocket]]  = initTable[string, seq[WebSocket]]() 