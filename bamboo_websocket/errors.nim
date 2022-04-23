##[
errors.nim

]##
type
  WebSocketHandShakePreProcessError* = object of CatchableError
  WebSocketHandShakeSubProtcolsProcedureError* = object of CatchableError
  WebSocketHandShakePostProcessProcedureError* = object of CatchableError
  WebSocketHandShakeHeaderError* = object of ValueError
  WebSocketDataReceivedPostProcessError* = object of CatchableError
  UnknownOpcodeReceiveError* = object of ValueError
  WebSocketOtherError* = object of IOError