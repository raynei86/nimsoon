import std/[bitops, options]
import types, position, move, magic

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

iterator knightMoves*(pos: Position): Move {.inline.} =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][Knight].squares:
    let attacks = KnightAttacks[sq] and not friendly
    for target in (attacks and enemy).squares:
      yield Move(start: sq, finish: target, flags: {Capture})
    for target in (attacks and not enemy).squares:
      yield Move(start: sq, finish: target, flags: {})
 
iterator kingMoves*(pos: Position): Move {.inline.} =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][King].squares:
    let attacks = KingAttacks[sq] and not friendly
    for target in (attacks and enemy).squares:
      yield Move(start: sq, finish: target, flags: {Capture})
    for target in (attacks and not enemy).squares:
      yield Move(start: sq, finish: target, flags: {})
 
iterator rookMoves*(pos: Position): Move {.inline.} =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][Rook].squares:
    let attacks = rookAttacks(sq, pos.occupied) and not friendly
    for target in (attacks and enemy).squares:
      yield Move(start: sq, finish: target, flags: {Capture})
    for target in (attacks and not enemy).squares:
      yield Move(start: sq, finish: target, flags: {})

 
iterator bishopMoves*(pos: Position): Move {.inline.} =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][Bishop].squares:
    let attacks = bishopAttacks(sq, pos.occupied) and not friendly
    for target in (attacks and enemy).squares:
      yield Move(start: sq, finish: target, flags: {Capture})
    for target in (attacks and not enemy).squares:
      yield Move(start: sq, finish: target, flags: {})
 
iterator queenMoves*(pos: Position): Move {.inline.} =
  let friendly = pos.colors[pos.side]
  let enemy    = pos.colors[pos.side.opponent]
  for sq in pos.pieces[pos.side][Queen].squares:
    let attacks = queenAttacks(sq, pos.occupied) and not friendly
    for target in (attacks and enemy).squares:
      yield Move(start: sq, finish: target, flags: {Capture})
    for target in (attacks and not enemy).squares:
      yield Move(start: sq, finish: target, flags: {})
 

## Now pawns
iterator pawnMoves*(pos: Position): Move {.inline.} =
  let side  = pos.side
  let enemy = pos.colors[side.opponent]
  let empty = not pos.occupied
  
  let (pushShift, capEShift, capWShift, startRank, promoRank) =
    if side == White: ( 8,  9,  7, Rank2, Rank8)
    else:             (-8, -7, -9, Rank7, Rank1)
  
  let pawns = pos.pieces[side][Pawn]
  
  # Single and double pushes
  let push1 = shift(pawns, pushShift) and empty
  let push2 = shift(shift(pawns and startRank, pushShift) and empty, pushShift) and empty
  
  # Diagonal captures (mask the wrapping file before shifting)
  let capE = shift(pawns and NotFileH, capEShift) and enemy
  let capW = shift(pawns and NotFileA, capWShift) and enemy

  # Local templates allow yielding directly from the iterator's context!
  template yieldPawnMoves(targets: Bitboard, shiftAmt: int, mFlags: MoveFlags = {}) =
    for target in targets.squares:
      yield Move(start: Square(target.int - shiftAmt), finish: target, promotion: Pawn, flags: mFlags)

  template yieldPawnPromos(targets: Bitboard, shiftAmt: int, mFlags: MoveFlags = {}) =
    for target in targets.squares:
      let src = Square(target.int - shiftAmt)
      for promo in [Knight, Bishop, Rook, Queen]:
        yield Move(start: src, finish: target, promotion: promo, flags: mFlags)

  yieldPawnMoves( push1 and not promoRank, pushShift)
  yieldPawnMoves( push2,                   pushShift * 2, {Double})
  yieldPawnMoves( capE  and not promoRank, capEShift,     {Capture})
  yieldPawnMoves( capW  and not promoRank, capWShift,     {Capture})
  
  yieldPawnPromos(push1 and promoRank,     pushShift)
  yieldPawnPromos(capE  and promoRank,     capEShift,     {Capture})
  yieldPawnPromos(capW  and promoRank,     capWShift,     {Capture})
  
  # En passant: same capture logic but targeted at the ep square bitboard
  if pos.epSquare.isSome:
    let epBB   = Bitboard(1) shl pos.epSquare.get
    let epCapE = shift(pawns and NotFileH, capEShift) and epBB
    let epCapW = shift(pawns and NotFileA, capWShift) and epBB
    yieldPawnMoves(epCapE, capEShift, {Capture, EnPassant})
    yieldPawnMoves(epCapW, capWShift, {Capture, EnPassant})
 
iterator castlingMoves*(pos: Position): Move {.inline.} =
  let rights   = pos.castlingRights
  let occupied = pos.occupied
  if pos.side == White:
    if WhiteKingside  in rights and (occupied and WhiteKingsidePath) == 0:
      yield Move(start: Square(4),  finish: Square(6),  promotion: Pawn, flags: {Kingside})
    if WhiteQueenside in rights and (occupied and WhiteQueensidePath) == 0:
      yield Move(start: Square(4),  finish: Square(2),  promotion: Pawn, flags: {Queenside})
  else:
    if BlackKingside  in rights and (occupied and BlackKingsidePath) == 0:
      yield Move(start: Square(60), finish: Square(62), promotion: Pawn, flags: {Kingside})
    if BlackQueenside in rights and (occupied and BlackQueensidePath) == 0:
      yield Move(start: Square(60), finish: Square(58), promotion: Pawn, flags: {Queenside})
 
func isKingChecked*(pos: Position, color: Color): bool =
  let kingBB = pos.pieces[color][King]
  if kingBB == 0: return false
  let kSq  = lsb(kingBB)
  let opp  = color.opponent
  let occ  = pos.occupied
  
  let diagSliders = pos.pieces[opp][Bishop] or pos.pieces[opp][Queen]
  let orthSliders = pos.pieces[opp][Rook]   or pos.pieces[opp][Queen]
  
  # Cast "pawn attacks" from the king outward; if an enemy pawn occupies
  # one of those squares it is giving check.
  let (capE, capW) = if color == White: (9, 7) else: (-7, -9)
  let pawnThreat =
    (shift(kingBB and NotFileH, capE) or shift(kingBB and NotFileA, capW)) and
    pos.pieces[opp][Pawn]
  
  pawnThreat != 0 or
  (KnightAttacks[kSq]        and pos.pieces[opp][Knight]) != 0 or
  (bishopAttacks(kSq, occ)   and diagSliders)               != 0 or
  (rookAttacks(kSq, occ)     and orthSliders)               != 0 or
  (KingAttacks[kSq]          and pos.pieces[opp][King])   != 0
 
func isLegalMove*(pos: Position, mv: Move): bool =
  not isKingChecked(doMove(pos, mv), pos.side)

iterator pseudoLegalMoves*(pos: Position): Move {.inline.} =
  for mv in pawnMoves(pos): yield mv
  for mv in knightMoves(pos): yield mv
  for mv in bishopMoves(pos): yield mv
  for mv in rookMoves(pos): yield mv
  for mv in queenMoves(pos): yield mv
  for mv in kingMoves(pos): yield mv
  for mv in castlingMoves(pos): yield mv

iterator legalMoves*(pos: Position): Move {.inline.} =
  for mv in pos.pseudoLegalMoves:
    if isLegalMove(pos, mv):
      yield mv

iterator quietMoves*(pos: Position): Move {.inline.} =
  for mv in pos.pseudoLegalMoves:
    if Capture notin mv.flags:
      yield mv

iterator captureMoves*(pos: Position): Move {.inline.} =
  for mv in pos.pseudoLegalMoves:
    if Capture in mv.flags:
      yield mv

func perft*(pos: Position, depth: int): int =
  if depth == 0: return 1
  for mv in pos.legalMoves:
    result += perft(doMove(pos, mv), depth - 1)
