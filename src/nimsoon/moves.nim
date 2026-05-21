import std/bitops

import types

type
  MoveFlag* = enum
    mfCapture, mfDouble, mfEp, mfKingside, mfQueenside
  MoveFlags* = set[MoveFlag]
  Move* = object
    start*: Square
    finish*: Square
    promotion*: PieceType
    flags*: MoveFlags

func computeKnightAttacks(): array[64, Bitboard] =
  const offsets = [17, 10, -6, -15, -17, -10, 6, 15]
  
  for sq in 0..63:
    let fromFile = fileOf(sq)
    let fromRank = rankOf(sq)
    
    for offset in offsets:
      let toSq = sq + offset
      
      if toSq in 0..63:
        let toFile = fileOf(toSq)
        let toRank = rankOf(toSq)
        let df = abs(fromFile - toFile)
        let dr = abs(fromRank - toRank)
        
        if (df == 1 and dr == 2) or (dr == 1 and df == 2):
          result[sq].setBit(toSq)

func computeKingAttacks(): array[64, Bitboard] =
  const offsets = [8, -8, 1, -1, 9, 7, -7, -9]
  
  for sq in 0..63:
    let fromFile = fileOf(sq)
    
    for offset in offsets:
      let toSq = sq + offset
      
      if toSq in 0..63:
        let toFile = fileOf(toSq)
        
        if abs(fromFile - toFile) <= 1:
          result[sq].setBit(toSq)

const KnightAttacks*: array[64, Bitboard] = computeKnightAttacks()
const KingAttacks*: array[64, Bitboard] = computeKingAttacks()
