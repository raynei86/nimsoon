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
    let mv = Move(start: Square(12), finish: Square(28), promotion: Pawn, flags: {}) # e2e4
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after capture":
    let pos = positionFromFen("8/8/8/3p4/4P3/8/8/4K3 w - - 0 1")
    let mv = Move(start: Square(28), finish: Square(35), promotion: Pawn, flags: {Capture}) # e4xd5
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after en passant":
    let pos = positionFromFen("8/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
    let mv = Move(start: Square(36), finish: Square(43), promotion: Pawn, flags: {Capture, EnPassant})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after castling":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    let mv = Move(start: Square(4), finish: Square(6), promotion: Pawn, flags: {Kingside})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)

  test "incremental hash matches recompute after promotion":
    let pos = positionFromFen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
    let mv = Move(start: Square(48), finish: Square(56), promotion: Queen, flags: {})
    let next = doMove(pos, mv)
    check next.hash == hashPosition(next)
