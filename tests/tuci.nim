import std/[options, unittest]

import nimsoon/[uci, types, move, movegen, position]

type
  TestEngine = ref object of UciEngine
    pos: Position

method name*(engine: TestEngine): string =
  "test-engine"

method author*(engine: TestEngine): string =
  "nimsoon-tests"

method setPosition*(engine: TestEngine, pos: Position) =
  engine.pos = pos

method go*(engine: TestEngine, params: GoParams): UciResult =
  for mv in pseudoLegalMoves(engine.pos):
    return UciResult(bestmove: some(mv))
  UciResult(bestmove: none(Move))

suite "uci helpers":
  test "parseUciMove parses basic move":
    let pos = Position()
    let mv = parseUciMove("e2e4", pos)
    check mv.start == parseSquare("e2")
    check mv.finish == parseSquare("e4")

  test "parseUciMove parses promotion":
    let pos = Position()
    let mv = parseUciMove("a7a8q", pos)
    check mv.start == parseSquare("a7")
    check mv.finish == parseSquare("a8")
    check mv.promotion == Queen

  test "formatUciMove formats promotion":
    let mv = Move(start: parseSquare("a7"), finish: parseSquare("a8"), promotion: Queen, flags: {})
    check formatUciMove(mv) == "a7a8q"
