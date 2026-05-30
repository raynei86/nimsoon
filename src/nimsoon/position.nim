import std/[bitops, options]

import types

# The main object representing a chess position
type
  Position* = object
    pieces: array[Color, array[PieceType, Bitboard]]
    colors: array[Color, Bitboard]
    occupied: Bitboard

    side*: Color
    castlingRights*: CastlingRights
    epSquare*: Option[Square]
    halfmoveClock*: uint8
    fullmoveClock*: uint16
    hash*: HashKey

func newPosition*(
    pieces: array[Color, array[PieceType, Bitboard]],
    colors: array[Color, Bitboard],
    occupied: Bitboard,
    side: Color = Color.White,
    castlingRights: CastlingRights = {WhiteKingside, WhiteQueenside, BlackKingside, BlackQueenside},
    epSquare: Option[Square] = none(Square),
    halfmoveClock: uint8 = 0,
    fullmoveClock: uint16 = 0,
    hash: HashKey = 0
): Position =
  Position(
    pieces: pieces,
    colors: colors,
    occupied: occupied,
    side: side,
    castlingRights: castlingRights,
    epSquare: epSquare,
    halfmoveClock: halfmoveClock,
    fullmoveClock: fullmoveClock,
    hash: hash
  )

func pieces*(pos: Position): array[Color, array[PieceType, Bitboard]] {.inline.} = pos.pieces
func colors*(pos: Position): array[Color, Bitboard] {.inline.} = pos.colors
func occupied*(pos: Position): Bitboard {.inline.} = pos.occupied

func isOccupied*(pos: Position, sq: Square): bool {.inline.} =
  pos.occupied.testBit(sq)

func colorAt*(pos: Position, sq: Square): Color {.inline.} =
  ## Assumes square is occupied
  if testBit(pos.colors[Color.White], sq): return Color.White
  elif testBit(pos.colors[Color.Black], sq): return Color.Black
  else: assert false, "colorAt called on an empty square" & $sq

func pieceAt*(pos: Position, sq: Square): PieceType {.inline.} =
  ## Assumes square is occupied
  for piece in Pawn..King:
    let combinedBB = pos.pieces[White][piece] or pos.pieces[Black][piece]

    if combinedBB.testBit(sq):
      return piece

  assert false, "pieceAt called on an empty square" & $sq

func `[]`*(pos: Position, sq: Square): ColoredPiece =
  ColoredPiece(color: pos.colorAt(sq), kind: pos.pieceAt(sq))

proc placePiece*(pos: var Position, sq: Square, color: Color, piece: PieceType) =
  pos.pieces[color][piece].setBit(sq)
  pos.colors[color].setBit(sq)
  pos.occupied.setBit(sq)

proc removePiece*(pos: var Position, sq: Square, color: Color, piece: PieceType) =
  pos.pieces[color][piece].clearBit(sq)
  pos.colors[color].clearBit(sq)
  pos.occupied.clearBit(sq)
