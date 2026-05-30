import std/unittest

import nimsoon/[types, fen, move, zobrist]

suite "zobrist hashing":
  test "positionFromFen sets hash and matches recompute":
    let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    check pos.hash == hashPosition(pos)

  test "hash is deterministic for identical FEN":
    let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    let pos2 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    check pos1.hash == pos2.hash

  test "incremental hash matches recompute after quiet move":
    let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    let mv = Move(start: parseSquare("e2"), finish: parseSquare("e4"), promotion: Pawn, flags: {})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after capture":
    let pos = positionFromFen("8/8/8/3p4/4P3/8/8/4K3 w - - 0 1")
    let mv = Move(start: parseSquare("e4"), finish: parseSquare("d5"), promotion: Pawn, flags: {Capture})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after en passant":
    let pos = positionFromFen("8/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
    let mv = Move(start: parseSquare("e5"), finish: parseSquare("d6"), promotion: Pawn, flags: {Capture, EnPassant})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after castling":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    let mv = Move(start: parseSquare("e1"), finish: parseSquare("g1"), promotion: Pawn, flags: {Kingside})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after promotion":
    let pos = positionFromFen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
    let mv = Move(start: parseSquare("a7"), finish: parseSquare("a8"), promotion: Queen, flags: {})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)
