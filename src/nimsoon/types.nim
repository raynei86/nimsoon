import std/[bitops]


# ===============================================================================
# BOARD TYPES & UTILITIES
# ===============================================================================

type
  Square* = range[0..63]
  Rank = range[0..7]
  File = range[0..7]
  Bitboard* = uint64
  HashKey* = uint64

func fileOf*(sq: Square): File {.inline.} = File(sq and 7)
func rankOf*(sq: Square): Rank {.inline.} = Rank(sq shr 3)

func parseSquare*(name: string): Square {.compileTime.} =
  let
    f = int(name[0]) - int('a')
    r = int(name[1]) - int('1')
  result = Square((r * 8) + f)

iterator squares*(bb: Bitboard): Square =
  ## Returns the square index for each set bit on each iteration
  var bits = bb
  while bits != 0:
    let sq = countTrailingZeroBits(bits)
    yield Square(sq)
    bits = bits and (bits - 1)

func lsb*(bb: Bitboard): Square {.inline.} =
  Square(countTrailingZeroBits(bb))

func msb*(bb: Bitboard): Square {.inline.} =
  Square(63 - countLeadingZeroBits(bb))

func shift*(bb: Bitboard, n: int): Bitboard {.inline.} =
  ## Signed shift: positive moves toward rank 8, negative toward rank 1.
  if n >= 0: bb shl n else: bb shr (-n)

const
  FullBoard* : Bitboard = 0xFFFFFFFFFFFFFFFF'u64
  Rank1* : Bitboard = 0x00000000000000FF'u64
  Rank2* : Bitboard = 0x000000000000FF00'u64
  Rank7* : Bitboard = 0x00FF000000000000'u64
  Rank8* : Bitboard = 0xFF00000000000000'u64
  FileA*: Bitboard = 0x0101010101010101'u64
  FileH*: Bitboard = 0x8080808080808080'u64
  NotFileA* : Bitboard = 0xFEFEFEFEFEFEFEFE'u64
  NotFileH* : Bitboard = 0x7F7F7F7F7F7F7F7F'u64

  WhiteKingsidePath* : Bitboard = (1'u64 shl 5) or (1'u64 shl 6)   # f1, g1
  WhiteQueensidePath* : Bitboard = (1'u64 shl 1) or (1'u64 shl 2) or (1'u64 shl 3)  # b1, c1, d1
  BlackKingsidePath* : Bitboard = (1'u64 shl 61) or (1'u64 shl 62)  # f8, g8
  BlackQueensidePath* : Bitboard = (1'u64 shl 57) or (1'u64 shl 58) or (1'u64 shl 59)  # b8, c8, d8

# ===============================================================================
# PIECE TYPES & UTILITIES
# ===============================================================================

type
  Color* {.pure.} = enum 
    White, Black
  PieceType* = enum
    ptPawn, ptKnight, ptBishop, ptRook, ptQueen, ptKing
  ColoredPiece* = object
    color*: Color
    kind*: PieceType
  CastlingSide* = enum
    csWhiteKingside, csWhiteQueenside, csBlackKingside, csBlackQueenside
  CastlingRights* = set[CastlingSide]

const CastlingRightsMask*: array[64, CastlingRights] = block:
  var mask: array[64, CastlingRights]
  # Initialize all squares with full rights (no restriction)
  for i in 0..63:
    mask[i] = {csWhiteKingside, csWhiteQueenside, csBlackKingside, csBlackQueenside}

  # White king on e1 - removes both white castling rights
  mask[4] = {csBlackKingside, csBlackQueenside}

  # Black king on e8 - removes both black castling rights
  mask[60] = {csWhiteKingside, csWhiteQueenside}

  # White rooks
  mask[0] = {csWhiteKingside, csBlackKingside, csBlackQueenside}  # a1 - removes white queenside
  mask[7] = {csWhiteQueenside, csBlackKingside, csBlackQueenside}  # h1 - removes white kingside

  # Black rooks
  mask[56] = {csWhiteKingside, csWhiteQueenside, csBlackKingside}  # a8 - removes black queenside
  mask[63] = {csWhiteKingside, csWhiteQueenside, csBlackQueenside}  # h8 - removes black kingside

  mask

func opponent*(c: Color): Color =
  if c == Color.White:
    Color.Black
  else:
    Color.White
