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

func shift(bb: Bitboard, n: int): Bitboard {.inline.} =
  ## Signed shift: positive moves toward rank 8, negative toward rank 1.
  if n >= 0: bb shl n else: bb shr (-n)

  
## Sliding pieces  
type Direction* = enum
  dirN, dirNE, dirE, dirSE, dirS, dirSW, dirW, dirNW
 
const DirOffsets: array[Direction, int] = [8, 9, 1, -7, -8, -9, -1, 7]
 
# Positive-offset rays use LSB to find the nearest blocker;
# negative-offset rays use MSB.
const IsPositive: array[Direction, bool] =
  [true, true, true, false, false, false, false, true]
 
func computeRays(): array[Direction, array[64, Bitboard]] =
  for dir in Direction:
    let off = DirOffsets[dir]
    for sq in 0..63:
      var cur = sq
      while true:
        let nxt = cur + off
        if nxt notin 0..63: break
        if abs((nxt and 7) - (cur and 7)) > 1: break
        result[dir][sq].setBit(nxt)
        cur = nxt


const Rays*: array[Direction, array[64, Bitboard]] = computeRays()
 
func rayAttack(sq: int, dir: Direction, occupied: Bitboard): Bitboard {.inline.} =
  let ray      = Rays[dir][sq]
  let blockers = ray and occupied
  if blockers == 0: return ray
  let blockSq = if IsPositive[dir]: lsb(blockers) else: msb(blockers)
  ray xor Rays[dir][blockSq]
 
func rookAttacks*(sq: int, occupied: Bitboard): Bitboard {.inline.} =
  rayAttack(sq, dirN, occupied) or rayAttack(sq, dirE, occupied) or
  rayAttack(sq, dirS, occupied) or rayAttack(sq, dirW, occupied)
 
func bishopAttacks*(sq: int, occupied: Bitboard): Bitboard {.inline.} =
  rayAttack(sq, dirNE, occupied) or rayAttack(sq, dirNW, occupied) or
  rayAttack(sq, dirSE, occupied) or rayAttack(sq, dirSW, occupied)
 
func queenAttacks*(sq: int, occupied: Bitboard): Bitboard {.inline.} =
  rookAttacks(sq, occupied) or bishopAttacks(sq, occupied)
 
proc generateKnightMoves*(pos: Position): seq[Move] =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][ptKnight].squares:
    let attacks = KnightAttacks[sq] and not friendly
    result.add emitMoves(sq, attacks and enemy,     {mfCapture})
    result.add emitMoves(sq, attacks and not enemy, {})
 
proc generateKingMoves*(pos: Position): seq[Move] =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][ptKing].squares:
    let attacks = KingAttacks[sq] and not friendly
    result.add emitMoves(sq, attacks and enemy,     {mfCapture})
    result.add emitMoves(sq, attacks and not enemy, {})
 
proc generateRookMoves*(pos: Position): seq[Move] =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][ptRook].squares:
    let attacks = rookAttacks(sq, pos.occupied) and not friendly
    result.add emitMoves(sq, attacks and enemy,     {mfCapture})
    result.add emitMoves(sq, attacks and not enemy, {})
 
proc generateBishopMoves*(pos: Position): seq[Move] =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][ptBishop].squares:
    let attacks = bishopAttacks(sq, pos.occupied) and not friendly
    result.add emitMoves(sq, attacks and enemy,     {mfCapture})
    result.add emitMoves(sq, attacks and not enemy, {})
 
proc generateQueenMoves*(pos: Position): seq[Move] =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][ptQueen].squares:
    let attacks = queenAttacks(sq, pos.occupied) and not friendly
    result.add emitMoves(sq, attacks and enemy,     {mfCapture})
    result.add emitMoves(sq, attacks and not enemy, {})
 

## Now pawns
func emitPawnMoves(targets: Bitboard, shiftAmt: int, flags: MoveFlags = {}): seq[Move] =
  for target in targets.squares:
    result.add Move(start: Square(target.int - shiftAmt), finish: target,
                    promotion: ptPawn, flags: flags)
 
func emitPawnPromos(targets: Bitboard, shiftAmt: int, flags: MoveFlags = {}): seq[Move] =
  for target in targets.squares:
    let src = Square(target.int - shiftAmt)
    for promo in [ptKnight, ptBishop, ptRook, ptQueen]:
      result.add Move(start: src, finish: target, promotion: promo, flags: flags)
 
proc generatePawnMoves*(pos: Position): seq[Move] =
  let side  = pos.side
  let enemy = pos.colors[side.opponent]
  let empty = not pos.occupied
 
  let (pushShift, capEShift, capWShift, startRank, promoRank) =
    if side == White: ( 8,  9,  7, Rank2, Rank8)
    else:             (-8, -7, -9, Rank7, Rank1)
 
  let pawns = pos.pieces[side][ptPawn]
 
  # Single and double pushes
  let push1 = shift(pawns, pushShift) and empty
  # Double push: only from the starting rank, through the single-push square
  let push2 = shift(shift(pawns and startRank, pushShift) and empty,
                    pushShift) and empty
 
  # Diagonal captures (mask the wrapping file before shifting)
  let capE = shift(pawns and NotFileH, capEShift) and enemy
  let capW = shift(pawns and NotFileA, capWShift) and enemy
 
  result.add emitPawnMoves( push1 and not promoRank, pushShift)
  result.add emitPawnMoves( push2,                   pushShift * 2, {mfDouble})
  result.add emitPawnMoves( capE  and not promoRank, capEShift,     {mfCapture})
  result.add emitPawnMoves( capW  and not promoRank, capWShift,     {mfCapture})
  result.add emitPawnPromos(push1 and promoRank,     pushShift)
  result.add emitPawnPromos(capE  and promoRank,     capEShift,     {mfCapture})
  result.add emitPawnPromos(capW  and promoRank,     capWShift,     {mfCapture})
 
  # En passant: same capture logic but targeted at the ep square bitboard
  if pos.epSquare != 64:
    let epBB   = Bitboard(1) shl pos.epSquare
    let epCapE = shift(pawns and NotFileH, capEShift) and epBB
    let epCapW = shift(pawns and NotFileA, capWShift) and epBB
    result.add emitPawnMoves(epCapE, capEShift, {mfCapture, mfEp})
    result.add emitPawnMoves(epCapW, capWShift, {mfCapture, mfEp})
 
const
  WhiteKingsidePath  = (Bitboard(1) shl  5) or (Bitboard(1) shl  6)
  WhiteQueensidePath = (Bitboard(1) shl  1) or (Bitboard(1) shl  2) or
                       (Bitboard(1) shl  3)
  BlackKingsidePath  = (Bitboard(1) shl 61) or (Bitboard(1) shl 62)
  BlackQueensidePath = (Bitboard(1) shl 57) or (Bitboard(1) shl 58) or
                       (Bitboard(1) shl 59)
 
proc generateCastlingMoves*(pos: Position): seq[Move] =
  let rights   = pos.castlingRights
  let occupied = pos.occupied
  if pos.side == White:
    if csWhiteKingside  in rights and (occupied and WhiteKingsidePath) == 0:
      result.add Move(start: Square(4),  finish: Square(6),  promotion: ptPawn, flags: {mfKingside})
    if csWhiteQueenside in rights and (occupied and WhiteQueensidePath) == 0:
      result.add Move(start: Square(4),  finish: Square(2),  promotion: ptPawn, flags: {mfQueenside})
  else:
    if csBlackKingside  in rights and (occupied and BlackKingsidePath) == 0:
      result.add Move(start: Square(60), finish: Square(62), promotion: ptPawn, flags: {mfKingside})
    if csBlackQueenside in rights and (occupied and BlackQueensidePath) == 0:
      result.add Move(start: Square(60), finish: Square(58), promotion: ptPawn, flags: {mfQueenside})
 
proc generateMoves*(pos: Position): seq[Move] =
  result.add generatePawnMoves(pos)
  result.add generateKnightMoves(pos)
  result.add generateBishopMoves(pos)
  result.add generateRookMoves(pos)
  result.add generateQueenMoves(pos)
  result.add generateKingMoves(pos)
  result.add generateCastlingMoves(pos)
 

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
 
  result.epSquare = if mfDouble in f: Square(to.int + pawnBack) else: Square(64)
 
  result.castlingRights = result.castlingRights * CastlingRightsMask[fr] * CastlingRightsMask[to]
 
  result.halfmoveClock =
    if movingPiece == ptPawn or mfCapture in f: 0
    else: result.halfmoveClock + 1
 
  if side == Black: inc result.fullmoveClock
 
  result.side = opp
 
 
func kingInCheck*(pos: Position, color: Color): bool =
  let kingBB = pos.pieces[color][ptKing]
  if kingBB == 0: return false
  let kSq  = lsb(kingBB)
  let opp  = color.opponent
  let occ  = pos.occupied
 
  let diagSliders = pos.pieces[opp][ptBishop] or pos.pieces[opp][ptQueen]
  let orthSliders = pos.pieces[opp][ptRook]   or pos.pieces[opp][ptQueen]
 
  # Cast "pawn attacks" from the king outward; if an enemy pawn occupies
  # one of those squares it is giving check.
  let (capE, capW) = if color == White: (9, 7) else: (-7, -9)
  let pawnThreat =
    (shift(kingBB and NotFileH, capE) or shift(kingBB and NotFileA, capW)) and
    pos.pieces[opp][ptPawn]
 
  pawnThreat != 0 or
  (KnightAttacks[kSq]        and pos.pieces[opp][ptKnight]) != 0 or
  (bishopAttacks(kSq, occ)   and diagSliders)               != 0 or
  (rookAttacks(kSq, occ)     and orthSliders)               != 0 or
  (KingAttacks[kSq]          and pos.pieces[opp][ptKing])   != 0
 
func isLegalMove*(pos: Position, mv: Move): bool =
  not kingInCheck(doMove(pos, mv), pos.side)
 
func generateLegalMoves*(pos: Position): seq[Move] =
  for mv in generateMoves(pos):
    if isLegalMove(pos, mv):
      result.add mv
 
func perft*(pos: Position, depth: int): int =
  if depth == 0: return 1
  for mv in generateMoves(pos):
    if isLegalMove(pos, mv):
      result += perft(doMove(pos, mv), depth - 1)
 
