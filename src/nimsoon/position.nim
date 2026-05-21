import std/[bitops]

# The main object representing a chess position
type
  Position* = object
    pieces*: array[Color, array[PieceType, Bitboard]]
    colors*: array[Color, Bitboard]
    occupied*: Bitboard

    side*: Color
    castlingRights*: CastingRights
    epSquare*: Square
    halfmoveClock: uint8
    fullmoveClock: uint16
    hash*: HashKey

func isOccupied*(pos: Position, sq: Square): bool {.inline.} =
  result = testBit(pos.occupied[sq])

func colorAt*(pos: Position, sq: Square): Color {.inline.} =
  ## Assumes square is occupied
  if testBit(pos.colors[Color.White][sq]): return Color.White
  elif testBit(pos.colors[Color.Black][sq]): return Color.Black
  else: assert false, "colorAt called on an empty square" & $sq

func pieceAt(pos: Position, sq: Square): PieceType {.inline.} =
  ## Assumes square is occupied
  for piece in Pawn..King:
    let combinedBB = boards.pieces[White][piece] or board.pieces[Black][piece]

    if combinedBB.testBit(sq):
      return piece

  assert false, "pieceAt called on an empty square" & $sq

proc placePiece(pos: var Position, sq: Square, color: Color, piece: pieceType) =
  pos.pieces[color][piece].setBit(sq)
  pos.colors[color].setBit(sq)
  pos.occupied.setBit(sq)

proc placePiece(pos: var Position, sq: Square, color: Color, piece: pieceType) =
  pos.pieces[color][piece].clearBit(sq)
  pos.colors[color].clearBit(sq)
  pos.occupied.clearBit(sq)
