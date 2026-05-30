import std/[options, parseutils, strutils]

import types
import position
import move
import movegen
import fen

type
  GoParams* = object
    depth*: Option[int]
    nodes*: Option[int]
    movetime*: Option[int]
    wtime*: Option[int]
    btime*: Option[int]
    winc*: Option[int]
    binc*: Option[int]
    infinite*: bool
    ponder*: bool

  UciResult* = object
    bestmove*: Option[Move]
    ponder*: Option[Move]
    info*: seq[string]

  UciEngine* = ref object of RootObj

method name*(engine: UciEngine): string {.base.} =
  "unknown"

method author*(engine: UciEngine): string {.base.} =
  "unknown"

method newGame*(engine: UciEngine) {.base.} =
  discard

method setPosition*(engine: UciEngine, pos: Position) {.base.} =
  discard

method go*(engine: UciEngine, params: GoParams): UciResult {.base.} =
  discard

method stop*(engine: UciEngine) {.base.} =
  discard

func defaultGoParams(): GoParams =
  GoParams(
    depth: none(int),
    nodes: none(int),
    movetime: none(int),
    wtime: none(int),
    btime: none(int),
    winc: none(int),
    binc: none(int),
    infinite: false,
    ponder: false
  )

func parseUciMove*(s: string, pos: Position): Move =
  if s.len < 4:
    return Move(start: Square(0), finish: Square(0), promotion: Pawn, flags: {})

  let fromSq = parseSquare(s[0..1])
  let toSq = parseSquare(s[2..3])
  var promo: PieceType = Pawn
  if s.len >= 5:
    case s[4]
    of 'q': promo = Queen
    of 'r': promo = Rook
    of 'b': promo = Bishop
    of 'n': promo = Knight
    else: discard

  Move(start: fromSq, finish: toSq, promotion: promo, flags: {})

func formatUciMove*(mv: Move): string =
  let fileChars = "abcdefgh"
  let rankChars = "12345678"
  let frFile = fileChars[fileOf(mv.start)]
  let frRank = rankChars[rankOf(mv.start)]
  let toFile = fileChars[fileOf(mv.finish)]
  let toRank = rankChars[rankOf(mv.finish)]
  result = $frFile & $frRank & $toFile & $toRank
  if mv.promotion != Pawn:
    let promoChar = case mv.promotion
      of Knight: 'n'
      of Bishop: 'b'
      of Rook: 'r'
      of Queen: 'q'
      else: 'q'
    result.add(promoChar)

proc applyUciMoves(pos: var Position, moves: seq[string]) =
  for moveStr in moves:
    let mv = parseUciMove(moveStr, pos)
    pos = doMove(pos, mv)

func parseGoParams(line: string): GoParams =
  result = defaultGoParams()
  var i = 0
  var key = ""
  while i < line.len:
    i += skipWhitespace(line, i)
    if i >= line.len:
      break
    key.setLen(0)
    let keyLen = parseIdent(line, key, i)
    if keyLen == 0:
      break
    i += keyLen
    case key
    of "depth":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.depth = some(val)
        i += read
    of "nodes":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.nodes = some(val)
        i += read
    of "movetime":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.movetime = some(val)
        i += read
    of "wtime":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.wtime = some(val)
        i += read
    of "btime":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.btime = some(val)
        i += read
    of "winc":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.winc = some(val)
        i += read
    of "binc":
      var val: int
      i += skipWhitespace(line, i)
      let read = parseInt(line, val, i)
      if read > 0:
        result.binc = some(val)
        i += read
    of "infinite":
      result.infinite = true
    of "ponder":
      result.ponder = true
    else:
      discard

proc defaultBestMove(pos: Position): Option[Move] =
  for mv in generateMoves(pos):
    return some(mv)
  none(Move)

proc runUci*(engine: UciEngine) =
  var currentPos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
  while true:
    if stdin.endOfFile: break
    let line = stdin.readLine().strip()
    if line.len == 0: continue
    let tokens = line.splitWhitespace()
    case tokens[0]
    of "uci":
      stdout.writeLine("id name " & engine.name)
      stdout.writeLine("id author " & engine.author)
      stdout.writeLine("uciok")
      stdout.flushFile()
    of "isready":
      stdout.writeLine("readyok")
      stdout.flushFile()
    of "ucinewgame":
      engine.newGame()
    of "position":
      var idx = 1
      if idx < tokens.len and tokens[idx] == "startpos":
        currentPos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
        inc idx
      elif idx < tokens.len and tokens[idx] == "fen":
        let fenStr = tokens[idx + 1 ..< min(tokens.len, idx + 7)].join(" ")
        currentPos = positionFromFen(fenStr)
        idx = idx + 7
      if idx < tokens.len and tokens[idx] == "moves":
        applyUciMoves(currentPos, tokens[(idx + 1) .. ^1])
      engine.setPosition(currentPos)
    of "go":
      let params = if line.len > 2: parseGoParams(line[2 .. ^1]) else: defaultGoParams()
      var result = engine.go(params)
      if result.bestmove.isNone:
        result.bestmove = defaultBestMove(currentPos)
      if result.bestmove.isSome:
        var line = "bestmove " & formatUciMove(result.bestmove.get())
        if result.ponder.isSome:
          line.add(" ponder " & formatUciMove(result.ponder.get()))
        stdout.writeLine(line)
      else:
        stdout.writeLine("bestmove 0000")
      stdout.flushFile()
    of "stop":
      engine.stop()
    of "quit":
      break
    else:
      discard
