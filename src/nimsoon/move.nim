import std/[options]

import types, position, zobrist

type
  MoveFlag* {.pure.} = enum
    Capture, Double, EnPassant, Kingside, Queenside
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
  let oldRights = pos.castlingRights
  let oldEp = pos.epSquare
  # Direction "behind" the moving pawn, used for EP capture and new EP square
  let pawnBack = if side == White: -8 else: 8
  var hash = result.hash

  xorSide(hash)
  xorCastling(hash, oldRights)
  xorEp(hash, oldEp)

  let movingPiece = result.pieceAt(fr)
  xorPiece(hash, fr, movingPiece, side)

  if Capture in f:
    if EnPassant in f:
      let capturedSquare = Square(to.int + pawnBack)
      xorPiece(hash, capturedSquare, Pawn, opp)
      result.removePiece(capturedSquare, opp, Pawn)
    else:
      let capturedPiece = result.pieceAt(to)
      xorPiece(hash, to, capturedPiece, opp)
      result.removePiece(to, opp, capturedPiece)

  xorPiece(hash, to, movingPiece, side)

  result.removePiece(fr, side, movingPiece)
  result.placePiece(to, side, movingPiece)

  if mv.promotion != Pawn:
    xorPiece(hash, to, Pawn, side)
    xorPiece(hash, to, mv.promotion, side)
    result.removePiece(to, side, Pawn)
    result.placePiece(to, side, mv.promotion)

  if Kingside in f:
    let (rf, rt) = if side == White: (7, 5) else: (63, 61)
    xorPiece(hash, Square(rf), Rook, side)
    xorPiece(hash, Square(rt), Rook, side)
    result.removePiece(Square(rf), side, Rook)
    result.placePiece(Square(rt), side, Rook)
  elif Queenside in f:
    let (rf, rt) = if side == White: (0, 3) else: (56, 59)
    xorPiece(hash, Square(rf), Rook, side)
    xorPiece(hash, Square(rt), Rook, side)
    result.removePiece(Square(rf), side, Rook)
    result.placePiece(Square(rt), side, Rook)

  result.epSquare = block:
                      if Double in f: some(Square(to.int + pawnBack)) else: none(Square)

  result.castlingRights = result.castlingRights * CastlingRightsMask[fr] * CastlingRightsMask[to]

  result.halfmoveClock =
    if movingPiece == Pawn or Capture in f: 0
    else: result.halfmoveClock + 1

  if side == Black: inc result.fullmoveClock

  result.side = opp
  
  xorSide(hash)
  xorCastling(hash, result.castlingRights)
  xorEp(hash, result.epSquare)

  result.hash = hash
