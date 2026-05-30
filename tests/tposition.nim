import std/[unittest, bitops]
import nimsoon/[position, types]

suite "placePiece / removePiece / isOccupied":
  test "empty position has no occupied squares":
    var pos: Position
    for sq in 0..63:
      check pos.isOccupied(sq) == false
 
  test "placePiece sets occupied":
    var pos: Position
    pos.placePiece(parseSquare("a1"), Color.White, King)
    check pos.isOccupied(parseSquare("a1")) == true
 
  test "placePiece does not affect other squares":
    var pos: Position
    pos.placePiece(parseSquare("c2"), Color.White, Pawn)
    check pos.isOccupied(parseSquare("b2")) == false
    check pos.isOccupied(parseSquare("d2")) == false
 
  test "removePiece clears occupied":
    var pos: Position
    pos.placePiece(parseSquare("a1"), Color.White, King)
    pos.removePiece(parseSquare("a1"), Color.White, King)
    check pos.isOccupied(parseSquare("a1")) == false
 
  test "placePiece sets color bitboard":
    var pos: Position
    pos.placePiece(parseSquare("f1"), Color.Black, Queen)
    check testBit(pos.colors[Color.Black], parseSquare("f1")) == true
    check testBit(pos.colors[Color.White], parseSquare("f1")) == false
 
  test "placePiece sets piece bitboard":
    var pos: Position
    pos.placePiece(parseSquare("e2"), Color.White, Rook)
    check testBit(pos.pieces[Color.White][Rook], parseSquare("e2")) == true
 
  test "removePiece clears piece bitboard":
    var pos: Position
    pos.placePiece(parseSquare("e2"), Color.White, Rook)
    pos.removePiece(parseSquare("e2"), Color.White, Rook)
    check testBit(pos.pieces[Color.White][Rook], parseSquare("e2")) == false
 
  test "removePiece clears color bitboard":
    var pos: Position
    pos.placePiece(parseSquare("e2"), Color.White, Rook)
    pos.removePiece(parseSquare("e2"), Color.White, Rook)
    check testBit(pos.colors[Color.White], parseSquare("e2")) == false
 
  test "multiple pieces can coexist":
    var pos: Position
    pos.placePiece(parseSquare("a1"), Color.White, Rook)
    pos.placePiece(parseSquare("h1"), Color.White, Rook)
    pos.placePiece(parseSquare("a8"), Color.Black, Rook)
    pos.placePiece(parseSquare("h8"), Color.Black, Rook)
    check pos.isOccupied(parseSquare("a1")) == true
    check pos.isOccupied(parseSquare("h1")) == true
    check pos.isOccupied(parseSquare("a8")) == true
    check pos.isOccupied(parseSquare("h8")) == true
    check countSetBits(pos.occupied) == 4
 
 
suite "colorAt":
  test "white piece returns Color.White":
    var pos: Position
    pos.placePiece(parseSquare("e1"), Color.White, King)
    check pos.colorAt(parseSquare("e1")) == Color.White
 
  test "black piece returns Color.Black":
    var pos: Position
    pos.placePiece(parseSquare("e8"), Color.Black, King)
    check pos.colorAt(parseSquare("e8")) == Color.Black
 
  test "white and black pieces at different squares":
    var pos: Position
    pos.placePiece(parseSquare("a1"), Color.White, Rook)
    pos.placePiece(parseSquare("h8"), Color.Black, Rook)
    check pos.colorAt(parseSquare("a1")) == Color.White
    check pos.colorAt(parseSquare("h8")) == Color.Black

suite "Position helpers":
  test "sideToMove returns current side":
    var pos: Position
    pos.side = Color.White
    check pos.sideToMove() == Color.White
    pos.side = Color.Black
    check pos.sideToMove() == Color.Black
