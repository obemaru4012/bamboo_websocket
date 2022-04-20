##[
errors.nim

]##
type
  WebSocketHandShakePreProcessError* = object of CatchableError
  WebSocketHandShakeSubProtcolsProcedureError* = object of CatchableError
  WebSocketHandShakePostProcessProcedureError* = object of CatchableError
  WebSocketHandShakeHeaderError* = object of ValueError
  WebSocketDatReceivedPostProcessError* = object of CatchableError
  UnknownOpcodeReceiveError* = object of ValueError
  NoMaskedFrameReceiveError* = object of ValueError
  WebSocketOtherError* = object of IOError