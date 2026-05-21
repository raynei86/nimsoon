import std/bitops

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

func emitMoves*(source: Square, targets: Bitboard, flags: MoveFlags = {}): seq[Move] =
  ## Generate moves from a source square to all targets in a bitboard
  for target in targets.squares:
    result.add(Move(start: source, finish: target, promotion: ptPawn, flags: flags))

    
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

## Sliding moves
func generateRayTable(offset: int): array[64, Bitboard] =
  for sq in 0..63:
    var current = sq
    let cf = fileOf(current)
    
    while true:
      let next = current + offset
      if next notin 0..63:
        break

      let nf = fileOf(next)

      # Check if we're wrapping around files or ranks
      let df = abs(int(nf) - int(cf))

      if df > 1:
        break

      result[sq].setBit(next)
      current = next


const Rays*: array[8, array[64, Bitboard]] =
  [generateRayTable(8), generateRayTable(9),
   generateRayTable(1), generateRayTable(-7),
   generateRayTable(-8), generateRayTable(-9),
   generateRayTable(-1), generateRayTable(7)]

func rayAttacksPositive*(sq: Square, direction: int, occupied: Bitboard): Bitboard =
  ## Attacks along a positive ray from square, cut off at first obstacle
  let ray = Rays[direction][sq]
  let blockers = ray and occupied

  if blockers == 0:
    ray
  else:
    # Cut off the ray at the first blocker
    let firstBlocker = lsb(blockers)
    ray xor Rays[direction][firstBlocker]

func rayAttacksNegative*(sq: Square, direction: int, occupied: Bitboard): Bitboard =
  ## Attacks along a negative ray from square, cut off at first obstacle
  let ray = Rays[direction][sq]
  let blockers = ray and occupied

  if blockers == 0:
    ray
  else:
    # Cut off the ray at the first blocker
    let lastBlocker = msb(blockers)
    ray xor Rays[direction][lastBlocker]

func rookAttackMask*(sq: Square, occupied: Bitboard): Bitboard =
  ## Compute rook attacks from a square given occupied squares
  rayAttacksPositive(sq, 0, occupied) or    # North
  rayAttacksPositive(sq, 2, occupied) or    # East
  rayAttacksNegative(sq, 4, occupied) or    # South
  rayAttacksNegative(sq, 6, occupied)       # West

func bishopAttackMask*(sq: Square, occupied: Bitboard): Bitboard =
  ## Compute bishop attacks from a square given occupied squares
  rayAttacksPositive(sq, 1, occupied) or    # NE
  rayAttacksPositive(sq, 7, occupied) or    # NW
  rayAttacksNegative(sq, 3, occupied) or    # SE
  rayAttacksNegative(sq, 5, occupied)       # SW

func queenAttackMask*(sq: Square, occupied: Bitboard): Bitboard =
  ## Compute queen attacks from a square given occupied squares
  rookAttackMask(sq, occupied) or bishopAttackMask(sq, occupied)

func generateKnightMoves*(pos: Position): seq[Move] =
  ## Generate pseudo-legal knight moves for the side to move
  let side = pos.side
  let friendly = pos.colors[side]
  let enemy = pos.colors[pos.side.opponent]
  let knights = pos.pieces[side][ptKnight]

  for sq in knights.squares:
    let attacks = KnightAttacks[sq] and (not friendly)

    let captures = attacks and enemy
    let quiets = attacks and (not enemy)

    result.add(emitMoves(sq, captures, {mfCapture}))
    result.add(emitMoves(sq, quiets))

func generateBishopMoves*(pos: Position): seq[Move] =
  ## Generate pseudo-legal bishop moves for the side to move
  let side = pos.side
  let friendly = pos.colors[side]
  let enemy = pos.colors[pos.side.opponent]
  let bishops = pos.pieces[side][ptBishop]

  for sq in bishops.squares:
    let attacks = bishopAttackMask(sq, pos.occupied) and (not friendly)

    let captures = attacks and enemy
    let quiets = attacks and (not enemy)

    result.add(emitMoves(sq, captures, {mfCapture}))
    result.add(emitMoves(sq, quiets))

func generateRookMoves*(pos: Position): seq[Move] =
  ## Generate pseudo-legal rook moves for the side to move
  let side = pos.side
  let friendly = pos.colors[side]
  let enemy = pos.colors[pos.side.opponent]
  let rooks = pos.pieces[side][ptRook]

  for sq in rooks.squares:
    let attacks = rookAttackMask(sq, pos.occupied) and (not friendly)

    let captures = attacks and enemy
    let quiets = attacks and (not enemy)

    result.add(emitMoves(sq, captures, {mfCapture}))
    result.add(emitMoves(sq, quiets))

func generateQueenMoves*(pos: Position): seq[Move] =
  ## Generate pseudo-legal queen moves for the side to move
  let side = pos.side
  let friendly = pos.colors[side]
  let enemy = pos.colors[pos.side.opponent]
  let queens = pos.pieces[side][ptQueen]

  for sq in queens.squares:
    let attacks = queenAttackMask(sq, pos.occupied) and (not friendly)

    let captures = attacks and enemy
    let quiets = attacks and (not enemy)

    result.add(emitMoves(sq, captures, {mfCapture}))
    result.add(emitMoves(sq, quiets))

func generateKingMoves*(pos: Position): seq[Move] =
  ## Generate pseudo-legal king moves for the side to move
  let side = pos.side
  let friendly = pos.colors[side]
  let enemy = pos.colors[pos.side.opponent]
  let kings = pos.pieces[side][ptKing]

  for sq in kings.squares:
    let attacks = KingAttacks[sq] and (not friendly)

    let captures = attacks and enemy
    let quiets = attacks and (not enemy)

    result.add(emitMoves(sq, captures, {mfCapture}))
    result.add(emitMoves(sq, quiets))
