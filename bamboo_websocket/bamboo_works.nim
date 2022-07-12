import httpclient, 
       httpcore, 
       tables

type BambooWorks* = object
  headers*: HttpHeaders
  setting*: TableRef[string, string]
  sub_protocol*: seq[string]

proc initBambooWorks*(): BambooWorks =
  return BambooWorks(headers: HttpHeaders(), setting: TableRef[string, string](), sub_protocol: newSeq[string]())