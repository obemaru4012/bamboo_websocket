import mersenne, random, strutils, unicode

proc convertBinaryStrings*(bytes: char): string =
  ##[
  数字を2進数型の文字列に変換する
  EX: 255 => "111111111"
  ]##
  return bytes.BiggestInt.toBin(8)

proc convertBinaryStrings*(bytes: int32): string =
  ##[
  数字を2進数型の文字列に変換する
  EX: 10 => "00001010"
  ]##
  return bytes.toBin(8)

proc convertBinaryStrings*(bytes: int64): string =
  ##[
  数字を2進数型の文字列に変換する
  EX: 255 => "111111111"
  ]##
  return bytes.toBin(8)

proc fourBitFromChar(c: char): int =
  ##[
  文字から4bitに変換
  EX: a => 10, b => 11
  ]##
  if c in "0123456789":
    return ord(c) - ord('0')
    
  if c in "abcdefghijklmnopqrstuvwxyz":
    return ord(c) - ord('a') + 10

  if c in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
    return ord(c) - ord('A') + 10

  return 0

proc decodeHexStrings*(hex: string): string =
  ##[
  16進数の形の文字列をデコードする
  ]##
  var byte_strings :seq[string] = newSeq[string](hex.len() div 2)
  for i in countup(0, byte_strings.len() - 1):
    byte_strings[i] = $(chr((fourBitFromChar(hex[2 * i]) shl 4) or fourBitFromChar(hex[2 * i + 1])))
  return byte_strings.join("")

proc convertRuneSequence*(message: string, per_length: int=3000): seq[string] =
  ##[
  StringsをRune文字列に変換しつつ、per_lengthごとの文字数に分割する。
  全部日本語で1MBはおおよそ33万文字なので、デフォルトは10KB文字分ごとぐらいにしておく。
  ]##
  var message_to_rune = toRunes(message)

  var count: int = message_to_rune.len() div per_length
  var modulo: int = message_to_rune.len() mod per_length

  var messages: seq[string]
  var left: int = 0
  var right: int = per_length
  for n in countup(0, count):
      if n == count:
          # echo(left, "..<", left + modulo, ": ", message_to_rune[left..<left + modulo])
          if len(message_to_rune[left..<left + modulo]) > 0:
            messages.add($message_to_rune[left..<left + modulo])
      else:
          # echo(left, "..<", right, ": ", message_to_rune[left..<right])
          messages.add($message_to_rune[left..<right])
          left = right
          right += per_length
  
  if messages.len() == 0:
    messages.add("")

  return messages

proc generateMaskKey*(seeder: int=0): seq[char] =
  ##[
  マスク用のKeyを生成する。
  マスク用のKeyはランダムな32bit値である。
  ]##
  var uin32_seeder: uint32
  try:
    # seederが0の場合は
    if seeder == 0:
      uin32_seeder = uint32(seeder)
    else:
      uin32_seeder = uint32(rand(2147483647))
  except:
    uin32_seeder = uint32(rand(2147483647))

  var twister = newMersenneTwister(uin32_seeder)
  var twister_string = twister.getNum().BiggestInt.toBin(32)

  var mask_key: seq[char]
  var left = 0
  for i in countup(7, 31, 7):
    mask_key.add(char(fromBin[uint8]("0b" & twister_string[left..i])))
    left = i

  return mask_key