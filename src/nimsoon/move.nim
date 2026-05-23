import std/[options]
import types, position

type
  MoveFlag* = enum
    mfCapture, mfDouble, mfEp, mfKingside, mfQueenside
  MoveFlags* = set[MoveFlag]
  Move* = object
    start*: Square
    finish*: Square
    promotion*: PieceType
    flags*: MoveFlags

func doMove*(pos: Position, mv: Move): Position =
  result = pos
  let side = pos.side
  let opp  = side.opponent
  let fr   = mv.start
  let to   = mv.finish
  let f    = mv.flags
  # Direction "behind" the moving pawn, used for EP capture and new EP square
  let pawnBack = if side == White: -8 else: 8
 
  if mfCapture in f:
    if mfEp in f:
      result.removePiece(Square(to.int + pawnBack), opp, ptPawn)
    else:
      result.removePiece(to, opp, result.pieceAt(to))
 
  let movingPiece = result.pieceAt(fr)
  result.removePiece(fr, side, movingPiece)
  result.placePiece(to, side, movingPiece)
 
  if mv.promotion != ptPawn:
    result.removePiece(to, side, ptPawn)
    result.placePiece(to, side, mv.promotion)
 
  if mfKingside in f:
    let (rf, rt) = if side == White: (7, 5) else: (63, 61)
    result.removePiece(Square(rf), side, ptRook)
    result.placePiece(Square(rt), side, ptRook)
  elif mfQueenside in f:
    let (rf, rt) = if side == White: (0, 3) else: (56, 59)
    result.removePiece(Square(rf), side, ptRook)
    result.placePiece(Square(rt), side, ptRook)
 
  result.epSquare = block:
                      if mfDouble in f: some(Square(to.int + pawnBack)) else: none(Square)
 
  result.castlingRights = result.castlingRights * CastlingRightsMask[fr] * CastlingRightsMask[to]
 
  result.halfmoveClock =
    if movingPiece == ptPawn or mfCapture in f: 0
    else: result.halfmoveClock + 1
 
  if side == Black: inc result.fullmoveClock
 
  result.side = opp
