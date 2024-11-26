# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.
include ./private/utilities

import unittest
import base64,
       json,
       nativesockets, 
       net, 
       std/sha1, 
       strutils

# ダミー設定テーブル作成
var setting = parseJson("""{"websocket_version": "13","upgrade": "websocket","connection": "upgrade","websocket_key": "dGhlIHNhbXBsZSBub25jZQ==","magic_strings": "258EAFA5-E914-47DA-95CA-C5AB0DC85B11","mask_key_seeder": "514902776"}""")

suite "utilities test":

  test "convertBinaryStrings('P'): string":
    check convertBinaryStrings('P') == "01010000"

  test "convertBinaryStrings('A'): string":
    check convertBinaryStrings('A') == "01000001"

  test "convertBinaryStrings('N'): string":
    check convertBinaryStrings('N') == "01001110"

  test "convertBinaryStrings('D'): string":
    check convertBinaryStrings('D') == "01000100"

  test "convertBinaryStrings('A'): string":
    check convertBinaryStrings('A') == "01000001"

  test "fourBitFromChar('y'): int":
    check fourBitFromChar('y') == 34

  test "decodeHexStrings(dGhlIHNhbXBsZSBub25jZQ==): string":
    var sec_websocket_accept: string = $(sha1.secureHash("dGhlIHNhbXBsZSBub25jZQ==" & "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
    sec_websocket_accept = base64.encode(decodeHexStrings(sec_websocket_accept))
    check sec_websocket_accept == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="

  test "convertRuneSequence(ぷーゆーゆ！ぷーゆーゆ！ぷーゆーゆ！)":
    check convertRuneSequence("ぷーゆーゆ！ぷーゆーゆ！ぷーゆーゆ！", 8) == @["ぷーゆーゆ！ぷー", "ゆーゆ！ぷーゆー", "ゆ！"]

  test "convertRuneSequence(ゆめちゃん、ぷゆゆ、ぺゆゆ、天才、ぱゆゆ、サムス、ホッティ)":
    check convertRuneSequence("ゆめちゃん、ぷゆゆ、ぺゆゆ、天才、ぱゆゆ、サムス、ホッティ", 4) == @["ゆめちゃ", "ん、ぷゆ", "ゆ、ぺゆ", "ゆ、天才", "、ぱゆゆ", "、サムス", "、ホッテ", "ィ"]

  test "generateMaskKey(1)":
    check generateMaskKey(1) == @['j', '`', '}', '\x84']

  test "generateMaskKey(514902776)":
    check generateMaskKey(514902776) == @['\x82', '\x00', ']', '\x8D']