##[
errors.nim

]##
type
  NoMaskedFrameReceiveError* = object of ValueError
  ServerSettingNotEnoughError* = object of KeyError
  WebSocketHandShakeSubProtcolsProcedureError* = object of CatchableError
  WebSocketHandShakeHeaderError* = object of ValueError
  WebSocketDataReceivedPostProcessError* = object of CatchableError
  UnknownOpcodeReceiveError* = object of ValueError
  WebSocketOtherError* = object of IOError