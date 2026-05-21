import std/[strutils, bitops]

import types
import position

proc fenCharToPiece(ch: char): PieceType =
  case ch.toLowerAscii()
  of 'p': Pawn
  of 'n': Knight
  of 'b': Bishop
  of 'r': Rook
  of 'q': Queen
  of 'k': King
  else: raise newException(ValueError, "Invalid FEN piece char: " & ch)

func fenCharToColor(ch: char): Color =
  if ch.isUpperAscii(): White else: Black

proc parsePlacement(pos: var Position, placementStr: string) =
  var rank = 7
  var file = 0
  
  for ch in placementStr:
    if ch == '/':
      file = 0
      dec rank
    elif ch.isDigit():
      # ch.int - '0'.int converts a char digit into its actual integer value
      file += (ch.int - '0'.int)
    else:
      let piece = fenCharToPiece(ch)
      let color = fenCharToColor(ch)
      let sq = rank * 8 + file
      pos.placePiece(sq, color, piece)
      inc file  

type BoardLayout = tuple[
  pieces: array[Color, array[PieceType, uint64]],
  byColor: array[Color, uint64],
  occupied: uint64
]

func parsePlacement(placementStr: string): BoardLayout =
  ## Pure function: Accepts a string, builds a layout locally, and returns it.
  var rank = 7
  var file = 0
  
  for ch in placementStr:
    if ch == '/':
      file = 0
      dec rank
    elif ch.isDigit():
      file += (ch.int - '0'.int)
    else:
      let piece = fenCharToPiece(ch)
      let color = fenCharToColor(ch)
      let sq = rank * 8 + file
      
      result.pieces[color][piece].setBit(sq)
      result.byColor[color].setBit(sq)
      result.occupied.setBit(sq)
      inc file

func parseCastling(castlingStr: string): CastlingRights =
  if castlingStr == "-": return CastlingRights({})
  for ch in castlingStr:
    case ch
    of 'K': result.incl(csWhiteKingside)
    of 'Q': result.incl(csWhiteQueenside)
    of 'k': result.incl(csBlackKingside)
    of 'q': result.incl(csBlackQueenside)
    else: discard

func parseEpSquare(epStr: string): Square =
  if epStr == "-": return 64
  let file = epStr[0].int - 'a'.int
  let rank = epStr[1].int - '1'.int
  return rank * 8 + file

func positionFromFen*(fen: string): Position =
  let tokens = fen.splitWhitespace()
  if tokens.len < 6:
    raise newException(ValueError, "Invalid FEN string")
    
  let (placement, side, castling, ep, halfmove, fullmove) = (
    tokens[0], tokens[1], tokens[2], tokens[3], tokens[4], tokens[5]
  )

  let layout = parsePlacement(placement)

  return Position(
    pieces: layout.pieces,
    colors: layout.byColor,
    occupied: layout.occupied,
    side: if side == "w": Color.White else: Color.Black,
    castlingRights: parseCastling(castling),
    epSquare: parseEpSquare(ep),
    halfmoveClock: uint8(parseUInt(halfmove)),
    fullmoveClock: uint8(parseUInt(fullmove))
  )
