import std/[unittest, bitops, options]

import nimsoon/[types, position, fen, move]

suite "doMove":
  test "quiet pawn move updates board and ep square":
    let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
    let mv = Move(start: parseSquare("e2"), finish: parseSquare("e4"), promotion: Pawn, flags: {Double})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Pawn], parseSquare("e4")) == true
    check testBit(next.pieces()[White][Pawn], parseSquare("e2")) == false
    check next.epSquare == some(parseSquare("e3"))
    check next.halfmoveClock == 0
    check next.side == Black

  test "capture removes enemy piece and resets halfmove":
    let pos = positionFromFen("8/8/8/3p4/4P3/8/8/4K3 w - - 5 3")
    let mv = Move(start: parseSquare("e4"), finish: parseSquare("d5"), promotion: Pawn, flags: {Capture})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Pawn], parseSquare("d5")) == true
    check testBit(next.pieces()[Black][Pawn], parseSquare("d5")) == false
    check next.halfmoveClock == 0

  test "en passant captures pawn on passed square":
    let pos = positionFromFen("8/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
    let mv = Move(start: parseSquare("e5"), finish: parseSquare("d6"), promotion: Pawn, flags: {Capture, EnPassant})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Pawn], parseSquare("d6")) == true
    check testBit(next.pieces()[Black][Pawn], parseSquare("d5")) == false

  test "kingside castling moves rook and clears white rights":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    let mv = Move(start: parseSquare("e1"), finish: parseSquare("g1"), promotion: Pawn, flags: {Kingside})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][King], parseSquare("g1")) == true
    check testBit(next.pieces()[White][Rook], parseSquare("f1")) == true
    check WhiteKingside notin next.castlingRights
    check WhiteQueenside notin next.castlingRights

  test "promotion replaces pawn with new piece":
    let pos = positionFromFen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
    let mv = Move(start: parseSquare("a7"), finish: parseSquare("a8"), promotion: Queen, flags: {})
    let next = doMove(pos, mv)

    check testBit(next.pieces()[White][Queen], parseSquare("a8")) == true
    check testBit(next.pieces()[White][Pawn], parseSquare("a8")) == false

  test "black move increments fullmove clock":
    let pos = positionFromFen("8/8/8/8/8/8/4p3/4K3 b - - 3 7")
    let mv = Move(start: parseSquare("e2"), finish: parseSquare("e1"), promotion: Pawn, flags: {})
    let next = doMove(pos, mv)

    check next.fullmoveClock == 8

  test "non-double move clears ep square":
    let pos = positionFromFen("8/8/8/8/8/8/4P3/4K3 w - e3 0 1")
    let mv = Move(start: parseSquare("e2"), finish: parseSquare("e3"), promotion: Pawn, flags: {})
    let next = doMove(pos, mv)

    check next.epSquare.isNone
