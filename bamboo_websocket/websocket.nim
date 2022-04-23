import asyncnet
import connection_status
import tables

type
  WebSocketC* = ref object
    socket*: AsyncSocket            ## 接続本体
    status*: ConnectionStatus       ## 接続ステータス

  WebSocket* = ref object
    id*: string                     ## 接続ID（OID）
    name*: string                   ## 名前（OID or ユーザー名などを由設定）
    socket*: AsyncSocket            ## 接続本体
    group_id*: string               ## 所属グループID（OID）
    group_name*: string             ## 所属グループ名
    status*: ConnectionStatus       ## 接続ステータス
    is_parent*: bool                ## 所属グループの長であるかどうか
    sec_websocket_accept*: string   ## Sec-WebSocket-Accept
    sec_websocket_protocol*: string ## Sec-WebSocket-Protocol
    version*: string                ## バージョン（現行は13）
    upgrade*: string                ## Upgradeリクエスト
    connection*: string             ## Connectionリクエスト

#[
WebSocket Objectを保持する\n
]#
var WebSockets*: seq[WebSocket] = newSeq[WebSocket]() 

#[
WebSocket Objectをグループ分けして管理する.\n
属性:\n
]#
var WebSocketsGroups*: Table[string, seq[WebSocket]]  = initTable[string, seq[WebSocket]]() 