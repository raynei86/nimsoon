import std/[bitops]

# Board related types and utils
type
  Square* = range[0..64]
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

const
  FullBoard* : Bitboard = 0xFFFFFFFFFFFFFFFF'u64
  Rank1* : Bitboard = 0x00000000000000FF'u64
  Rank2* : Bitboard = 0x000000000000FF00'u64
  Rank7* : Bitboard = 0x00FF000000000000'u64
  Rank8* : Bitboard = 0xFF00000000000000'u64
  NotFileA* : Bitboard = 0xFEFEFEFEFEFEFEFE'u64
  NotFileH* : Bitboard = 0x7F7F7F7F7F7F7F7F'u64


# Pieces related types
type
  Color* {.pure.} = enum 
    White, Black
  PieceType* = enum
    ptPawn, ptKnight, ptBishop, ptRook, ptQueen, ptKing
  CastlingSide* = enum
    csWhiteKingside, csWhiteQueenside, csBlackKingside, csBlackQueenside
  CastlingRights* = set[CastlingSide]
