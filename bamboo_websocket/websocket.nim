import asyncnet
import connection_status
import tables

type
  ##[
  ##### 基本のWebSocket Object.
  * 属性:
    * id                     : WebSocket Objectに対して一意に割り振られる。\n
    * socket                 : ソケット本体。\n
    * status                 : 接続ステータス。「ConnectionStatus」を参照。\n
    * sec_websocket_accept   : ハンドシェイク時に発行されたキー。\n
    * sec_websocket_protocol : サブプロトコル。Bambooにおいては非常に重要。\n
    * version                : WebSocketのバージョン。現在（2022/04）は「13」。\n
    * upgrade                : 「websocket」固定。\n
    * connection             : 「upgrade」固定。\n
  ]##
  WebSocket* = ref object
    id*: string                     ## 接続ID（OID）
    name*: string                    ## 名前（OID or ユーザー名などを由設定）
    group_id*: string                ## 所属グループID（OID）
    group_name*: string              ## 所属グループ名
    is_parent*: bool                 ## 所属グループの長であるかどうか
    socket*: AsyncSocket            ## 接続本体
    status*: ConnectionStatus       ## 接続ステータス
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