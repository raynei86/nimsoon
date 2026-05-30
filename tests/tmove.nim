import std/[unittest, bitops, options]

import nimsoon/[types, position, fen, move]

suite "doMove":
  test "quiet pawn move updates board and ep square":
    let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    let mv = Move(start: Square(12), finish: Square(28), promotion: Pawn, flags: {Double}) # e2e4
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Pawn], 28) == true
    check testBit(next.pieces()[White][Pawn], 12) == false
    check next.epSquare == some(Square(20))
    check next.halfmoveClock == 0
    check next.side == Black

  test "capture removes enemy piece and resets halfmove":
    let pos = positionFromFen("8/8/8/3p4/4P3/8/8/4K3 w - - 5 3")
    let mv = Move(start: Square(28), finish: Square(35), promotion: Pawn, flags: {Capture}) # e4xd5
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Pawn], 35) == true
    check testBit(next.pieces()[Black][Pawn], 35) == false
    check next.halfmoveClock == 0

  test "en passant captures pawn on passed square":
    let pos = positionFromFen("8/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
    let mv = Move(start: Square(36), finish: Square(43), promotion: Pawn, flags: {Capture, EnPassant})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Pawn], 43) == true
    check testBit(next.pieces()[Black][Pawn], 35) == false

  test "kingside castling moves rook and clears white rights":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    let mv = Move(start: Square(4), finish: Square(6), promotion: Pawn, flags: {Kingside})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][King], 6) == true
    check testBit(next.pieces()[White][Rook], 5) == true
    check WhiteKingside notin next.castlingRights
    check WhiteQueenside notin next.castlingRights

  test "promotion replaces pawn with new piece":
    let pos = positionFromFen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
    let mv = Move(start: Square(48), finish: Square(56), promotion: Queen, flags: {})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Queen], 56) == true
    check testBit(next.pieces()[White][Pawn], 56) == false

  test "black move increments fullmove clock":
    let pos = positionFromFen("8/8/8/8/8/8/4p3/4K3 b - - 3 7")
    let mv = Move(start: Square(12), finish: Square(4), promotion: Pawn, flags: {}) # e2e1
    let next = doMove(pos, mv)

    check next.fullmoveClock == 8

  test "non-double move clears ep square":
    let pos = positionFromFen("8/8/8/8/8/8/4P3/4K3 w - e3 0 1")
    let mv = Move(start: Square(12), finish: Square(20), promotion: Pawn, flags: {}) # e2e3
    let next = doMove(pos, mv)

    check next.epSquare.isNone
