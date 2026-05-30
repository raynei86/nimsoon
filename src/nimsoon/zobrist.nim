import std/options

import types
import position

type
  ZobristTables = tuple[
    piece: array[Color, array[PieceType, array[64, HashKey]]],
    side: HashKey,
    castling: array[CastlingSide, HashKey],
    epFile: array[8, HashKey]
  ]

func splitmix64(state: var uint64): uint64 {.compileTime.} =
  state = state + 0x9E3779B97F4A7C15'u64
  var z = state
  z = (z xor (z shr 30)) * 0xBF58476D1CE4E5B9'u64
  z = (z xor (z shr 27)) * 0x94D049BB133111EB'u64
  z xor (z shr 31)

func buildZobrist(): ZobristTables {.compileTime.} =
  var state = 0xDECAFBAD'u64
  for color in Color:
    for piece in PieceType:
      for sq in 0..63:
        result.piece[color][piece][sq] = HashKey(splitmix64(state))

  result.side = HashKey(splitmix64(state))

  for side in CastlingSide:
    result.castling[side] = HashKey(splitmix64(state))

  for file in 0..7:
    result.epFile[file] = HashKey(splitmix64(state))

const
  Zobrist = buildZobrist()
  PieceKeys = Zobrist.piece
  SideKey = Zobrist.side
  CastlingKeys = Zobrist.castling
  EpFileKeys = Zobrist.epFile

func xorPiece*(hash: var HashKey, sq: Square, piece: PieceType, color: Color) {.inline.} =
  hash = hash xor PieceKeys[color][piece][sq]

func xorSide*(hash: var HashKey) {.inline.} =
  hash = hash xor SideKey

func xorCastling*(hash: var HashKey, rights: CastlingRights) {.inline.} =
  for side in CastlingSide:
    if side in rights:
      hash = hash xor CastlingKeys[side]

func xorEp*(hash: var HashKey, ep: Option[Square]) {.inline.} =
  if ep.isSome:
    hash = hash xor EpFileKeys[fileOf(ep.get)]

func hashPosition*(pos: Position): HashKey =
  var hash: HashKey = 0
  let pieceBoards = pos.pieces()
  for color in Color:
    for piece in PieceType:
      for sq in pieceBoards[color][piece].squares:
        hash = hash xor PieceKeys[color][piece][sq]

  if pos.side == Black:
    hash = hash xor SideKey

  xorCastling(hash, pos.castlingRights)
  xorEp(hash, pos.epSquare)

  hash
