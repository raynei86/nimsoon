import std/[unittest, bitops]
import nimsoon/[position, types]

suite "placePiece / removePiece / isOccupied":
  test "empty position has no occupied squares":
    var pos: Position
    for sq in 0..63:
      check pos.isOccupied(sq) == false
 
  test "placePiece sets occupied":
    var pos: Position
    pos.placePiece(0, Color.White, ptKing)
    check pos.isOccupied(0) == true
 
  test "placePiece does not affect other squares":
    var pos: Position
    pos.placePiece(10, Color.White, ptPawn)
    check pos.isOccupied(9)  == false
    check pos.isOccupied(11) == false
 
  test "removePiece clears occupied":
    var pos: Position
    pos.placePiece(0, Color.White, ptKing)
    pos.removePiece(0, Color.White, ptKing)
    check pos.isOccupied(0) == false
 
  test "placePiece sets color bitboard":
    var pos: Position
    pos.placePiece(5, Color.Black, ptQueen)
    check testBit(pos.colors[Color.Black], 5) == true
    check testBit(pos.colors[Color.White], 5) == false
 
  test "placePiece sets piece bitboard":
    var pos: Position
    pos.placePiece(12, Color.White, ptRook)
    check testBit(pos.pieces[Color.White][ptRook], 12) == true
 
  test "removePiece clears piece bitboard":
    var pos: Position
    pos.placePiece(12, Color.White, ptRook)
    pos.removePiece(12, Color.White, ptRook)
    check testBit(pos.pieces[Color.White][ptRook], 12) == false
 
  test "removePiece clears color bitboard":
    var pos: Position
    pos.placePiece(12, Color.White, ptRook)
    pos.removePiece(12, Color.White, ptRook)
    check testBit(pos.colors[Color.White], 12) == false
 
  test "multiple pieces can coexist":
    var pos: Position
    pos.placePiece(0,  Color.White, ptRook)
    pos.placePiece(7,  Color.White, ptRook)
    pos.placePiece(56, Color.Black, ptRook)
    pos.placePiece(63, Color.Black, ptRook)
    check pos.isOccupied(0)  == true
    check pos.isOccupied(7)  == true
    check pos.isOccupied(56) == true
    check pos.isOccupied(63) == true
    check countSetBits(pos.occupied) == 4
 
 
suite "colorAt":
  test "white piece returns Color.White":
    var pos: Position
    pos.placePiece(4, Color.White, ptKing)
    check pos.colorAt(4) == Color.White
 
  test "black piece returns Color.Black":
    var pos: Position
    pos.placePiece(60, Color.Black, ptKing)
    check pos.colorAt(60) == Color.Black
 
  test "white and black pieces at different squares":
    var pos: Position
    pos.placePiece(0,  Color.White, ptRook)
    pos.placePiece(63, Color.Black, ptRook)
    check pos.colorAt(0)  == Color.White
    check pos.colorAt(63) == Color.Black
