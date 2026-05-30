import std/[unittest, bitops, sequtils, options]
import nimsoon/[types, position, fen, move, movegen, magic]

suite "Move Generation":

  test "Starting position has correct move count":
    block:
      let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      let moves = toSeq(generateMoves(pos))
      check moves.len == 20  # Standard chess starting position has 20 pseudo-legal moves

  test "Pawn moves from starting position":
    block:
      let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      let pawnMoves = toSeq(generatePawnMoves(pos))
      # 8 pawns × 2 moves each (single push or double push)
      check pawnMoves.len == 16

  test "Knight moves from starting position":
    block:
      let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      let knightMoves = toSeq(generateKnightMoves(pos))
      # 2 knights × 2 moves each
      check knightMoves.len == 4

  test "Castling kingside white":
    block:
      let pos1 = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
      let castlingMoves = toSeq(generateCastlingMoves(pos1))
      # White can castle kingside and queenside
      check castlingMoves.len == 2

  test "Knight moves do not affect castling rights":
    block:
      let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      check (WhiteKingside in pos1.castlingRights or WhiteQueenside in pos1.castlingRights)

      let move = Move(start: Square(1), finish: Square(16), promotion: Pawn, flags: {})
      let pos2 = doMove(pos1, move)
      # Castling rights should be preserved after knight move
      check (WhiteKingside in pos2.castlingRights or WhiteQueenside in pos2.castlingRights)
      let pos1b = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      check pos1b.side == Color.White

      let move2 = Move(start: Square(12), finish: Square(20), promotion: Pawn, flags: {})
      let pos3 = doMove(pos1b, move2)
      check pos3.side == Color.Black

  test "En passant square set on double pawn push":
    block:
      let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      let move = Move(start: Square(12), finish: Square(28), promotion: Pawn, flags: {Double})
      let pos2 = doMove(pos1, move)
      check pos2.epSquare.get() == 20  # en passant square is one rank behind the pawn

  test "Castling kingside white (second test)":
    block:
      let pos1 = positionFromFen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
      let castlingMoves = toSeq(generateCastlingMoves(pos1))
      # White can castle kingside and queenside
      check castlingMoves.len == 2

  test "Bishop attack mask generation":
    block:
      let pos = positionFromFen("8/8/8/3b4/8/8/8/8 w - - 0 1")
      # Bishop on d5 should have diagonal attacks in all directions
      let attacks = bishopAttacks(Square(35), Bitboard(0))
      check attacks != 0

  test "Rook attack mask generation":
    block:
      let pos = positionFromFen("8/8/8/3r4/8/8/8/8 w - - 0 1")
      # Rook on d5 should have orthogonal attacks in all directions
      let attacks = rookAttacks(Square(35), Bitboard(0))
      check attacks != 0

  test "Check detection - pawn check":
    block:
      let pos = positionFromFen("4k3/8/8/8/8/4p3/4K3/8 w - - 0 1")
      # Black pawn on e3 does not check white king on e2 (pawns attack diagonally)
      check not isKingChecked(pos, Color.White)

  test "Check detection - knight check":
    block:
      let pos = positionFromFen("8/8/8/3n4/8/4K3/8/8 w - - 0 1")
      # Black knight on d5 checks white king on e3
      check isKingChecked(pos, Color.White)

  test "Perft starting position depth 1":
    block:
      let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      let count = perft(pos, 1)
      check count == 20

  test "Move without capture doesn't reset halfmove clock":
    block:
      let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 5 3")
      let move = Move(start: Square(1), finish: Square(16), promotion: Pawn, flags: {})
      let pos2 = doMove(pos1, move)
      check pos2.halfmoveClock == 6

  test "Move with capture resets halfmove clock":
    block:
      let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 5 3")
      var pos2 = pos1
      # Place a black pawn on b4 to capture
      pos2.placePiece(Square(25), Color.Black, Pawn)

      let move = Move(start: Square(1), finish: Square(25), promotion: Pawn, flags: {Capture})
      let pos3 = doMove(pos2, move)
      check pos3.halfmoveClock == 0

  test "Pawn move resets halfmove clock":
    block:
      let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 5 3")
      let move = Move(start: Square(12), finish: Square(20), promotion: Pawn, flags: {})
      let pos2 = doMove(pos1, move)
      check pos2.halfmoveClock == 0

  test "Fullmove number increments after black move":
    block:
      let pos1 = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
      check pos1.fullmoveClock == 1

      let move1 = Move(start: Square(12), finish: Square(20), promotion: Pawn, flags: {})
      let pos2 = doMove(pos1, move1)
      check pos2.fullmoveClock == 1

      let move2 = Move(start: Square(52), finish: Square(36), promotion: Pawn, flags: {})
      let pos3 = doMove(pos2, move2)
      check pos3.fullmoveClock == 2
