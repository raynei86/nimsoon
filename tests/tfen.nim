import std/[unittest, bitops, sequtils, options]
import nimsoon/[fen, types, position]

suite "positionFromFen — starting position":
  let start = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
 
  test "occupied square count is 32":
    check countSetBits(start.occupied) == 32
 
  test "white pawns occupy rank 2 (squares 8–15)":
    for sq in 8..15:
      check testBit(start.pieces[Color.White][Pawn], sq) == true
 
  test "black pawns occupy rank 7 (squares 48–55)":
    for sq in 48..55:
      check testBit(start.pieces[Color.Black][Pawn], sq) == true
 
  test "ranks 3–6 are empty":
    for sq in 16..47:
      check start.isOccupied(sq) == false
 
  test "white king is on e1 (square 4)":
    check testBit(start.pieces[Color.White][King], 4) == true
 
  test "black king is on e8 (square 60)":
    check testBit(start.pieces[Color.Black][King], 60) == true
 
  test "white queen is on d1 (square 3)":
    check testBit(start.pieces[Color.White][Queen], 3) == true
 
  test "black queen is on d8 (square 59)":
    check testBit(start.pieces[Color.Black][Queen], 59) == true
 
  test "white rooks are on a1 and h1 (squares 0 and 7)":
    check testBit(start.pieces[Color.White][Rook], 0) == true
    check testBit(start.pieces[Color.White][Rook], 7) == true
 
  test "black rooks are on a8 and h8 (squares 56 and 63)":
    check testBit(start.pieces[Color.Black][Rook], 56) == true
    check testBit(start.pieces[Color.Black][Rook], 63) == true
 
  test "white knights are on b1 and g1 (squares 1 and 6)":
    check testBit(start.pieces[Color.White][Knight], 1) == true
    check testBit(start.pieces[Color.White][Knight], 6) == true
 
  test "black knights are on b8 and g8 (squares 57 and 62)":
    check testBit(start.pieces[Color.Black][Knight], 57) == true
    check testBit(start.pieces[Color.Black][Knight], 62) == true
 
  test "white bishops are on c1 and f1 (squares 2 and 5)":
    check testBit(start.pieces[Color.White][Bishop], 2) == true
    check testBit(start.pieces[Color.White][Bishop], 5) == true
 
  test "black bishops are on c8 and f8 (squares 58 and 61)":
    check testBit(start.pieces[Color.Black][Bishop], 58) == true
    check testBit(start.pieces[Color.Black][Bishop], 61) == true
 
  test "side to move is Color.White":
    check start.side == Color.White
 
  test "all four castling rights are set":
    check start.castlingRights == {WhiteKingside, WhiteQueenside,
                                   BlackKingside, BlackQueenside}
 
  test "no en passant square":
    check start.epSquare.isNone
 
  test "halfmove clock is 0":
    check start.halfmoveClock == 0
 
  test "fullmove clock is 1":
    check start.fullmoveClock == 1
 
 
suite "positionFromFen — side to move":
  test "white to move":
    let pos = positionFromFen("8/8/8/8/8/8/8/4K3 w - - 0 1")
    check pos.side == Color.White
 
  test "black to move":
    let pos = positionFromFen("4k3/8/8/8/8/8/8/4K3 b - - 0 1")
    check pos.side == Color.Black
 
 
suite "positionFromFen — castling rights":
  test "no castling rights":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w - - 0 1")
    check pos.castlingRights == {}
 
  test "white kingside only":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w K - 0 1")
    check pos.castlingRights == {WhiteKingside}
 
  test "white queenside only":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w Q - 0 1")
    check pos.castlingRights == {WhiteQueenside}
 
  test "black kingside only":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w k - 0 1")
    check pos.castlingRights == {BlackKingside}
 
  test "black queenside only":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w q - 0 1")
    check pos.castlingRights == {BlackQueenside}
 
  test "white both sides":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQ - 0 1")
    check pos.castlingRights == {WhiteKingside, WhiteQueenside}
 
  test "all four rights":
    let pos = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
    check pos.castlingRights == {WhiteKingside, WhiteQueenside,
                                 BlackKingside, BlackQueenside}
 
 
suite "positionFromFen — en passant square":
  test "no en passant":
    let pos = positionFromFen("8/8/8/8/8/8/8/4K3 w - - 0 1")
    check pos.epSquare.isNone
 
  test "en passant on e3 (square 20)":
    # After 1.e4, ep target is e3
    let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1")
    check pos.epSquare.get() == 20
 
  test "en passant on e6 (square 44)":
    # After 1...e5, ep target is e6
    let pos = positionFromFen("rnbqkbnr/pppp1ppp/8/4p3/8/8/PPPPPPPP/RNBQKBNR w KQkq e6 0 1")
    check pos.epSquare.get() == 44
 
  test "en passant on a6 (square 40)":
    let pos = positionFromFen("rnbqkbnr/1ppppppp/8/p7/8/8/PPPPPPPP/RNBQKBNR w KQkq a6 0 1")
    check pos.epSquare.get() == 40
 
  test "en passant on h3 (square 23)":
    let pos = positionFromFen("rnbqkbnr/ppppppp1/8/8/7P/8/PPPPPPP1/RNBQKBNR b KQkq h3 0 1")
    check pos.epSquare.get() == 23
 
 
suite "positionFromFen — clocks":
  test "halfmove and fullmove clocks are parsed":
    let pos = positionFromFen("8/8/8/8/8/8/8/4K3 w - - 12 34")
    check pos.halfmoveClock  == 12
    check pos.fullmoveClock  == 34
 
  test "zero clocks":
    let pos = positionFromFen("8/8/8/8/8/8/8/4K3 w - - 0 1")
    check pos.halfmoveClock == 0
    check pos.fullmoveClock == 1
 
 
suite "positionFromFen — piece placement edge cases":
  test "empty board (only kings)":
    let pos = positionFromFen("4k3/8/8/8/8/8/8/4K3 w - - 0 1")
    check countSetBits(pos.occupied) == 2
    check testBit(pos.pieces[Color.White][King], 4)  == true
    check testBit(pos.pieces[Color.Black][King], 60) == true
 
  test "FEN with digit runs spanning a full rank":
    # Rank of 8 empty squares
    let pos = positionFromFen("8/8/8/8/8/8/8/4K3 w - - 0 1")
    for sq in 8..63:
      if sq != 4:
        check pos.isOccupied(sq) == false
 
  test "known midgame position has correct piece count":
    # Ruy Lopez after 3.Bb5
    let pos = positionFromFen(
      "r1bqkbnr/pppp1ppp/2n5/1B2p3/4P3/5N2/PPPP1PPP/RNBQK2R b KQkq - 3 3")
    # 16 white + 16 black = 32 at start; 32 still on board here (no captures yet)
    check countSetBits(pos.occupied) == 32
 
  test "position after several captures has fewer pieces":
    # Simplified position: just kings and one pawn each
    let pos = positionFromFen("4k3/4p3/8/8/8/8/4P3/4K3 w - - 0 1")
    check countSetBits(pos.occupied) == 4
 
 
suite "positionFromFen — invalid input":
  test "too few FEN tokens raises ValueError":
    expect(ValueError):
      discard positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq -")
 
  test "invalid piece character raises ValueError":
    expect(ValueError):
      discard positionFromFen("rnbqkXnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
 
