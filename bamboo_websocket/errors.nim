##[
errors.nim

]##
type
  WebSocketHandShakeSubProtcolsProcedureError* = object of CatchableError
  WebSocketHandShakeHeaderError* = object of ValueError
  WebSocketDataReceivedPostProcessError* = object of CatchableError
  UnknownOpcodeReceiveError* = object of ValueError
  WebSocketOtherError* = object of IOError
  ServerSettingNotEnoughError* = object of KeyError
