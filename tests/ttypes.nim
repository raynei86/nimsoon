import std/[unittest, bitops]
import nimsoon/[types]

suite "fileOf / rankOf":
  test "a1 is file 0, rank 0":
    check fileOf(0) == 0
    check rankOf(0) == 0

  test "h1 is file 7, rank 0":
    check fileOf(7) == 7
    check rankOf(7) == 0

  test "a8 is file 0, rank 7":
    check fileOf(56) == 0
    check rankOf(56) == 7

  test "h8 is file 7, rank 7":
    check fileOf(63) == 7
    check rankOf(63) == 7

  test "e4 (square 28) is file 4, rank 3":
    check fileOf(28) == 4
    check rankOf(28) == 3

  test "all squares: fileOf stays in 0..7":
    for sq in 0..63:
      check fileOf(sq) in 0..7

  test "all squares: rankOf stays in 0..7":
    for sq in 0..63:
      check rankOf(sq) in 0..7


suite "parseSquare":
  const a1 = parseSquare("a1")
  const h1 = parseSquare("h1")
  const a8 = parseSquare("a8")
  const h8 = parseSquare("h8")
  const e2 = parseSquare("e2")

  test "a1 should be square 0":
    check a1 == 0

  test "h1 should be square 7":
    check h1 == 7

  test "a8 should be square 56":
    check a8 == 56

  test "h8 should be square 63":
    check h8 == 63

  test "e2 should be square 12":
    check e2 == 12


suite "squares iterator":
  test "empty bitboard yields nothing":
    var found: seq[Square]
    for sq in squares(Bitboard(0)):
      found.add(sq)
    check found.len == 0

  test "single bit yields exactly that square":
    let bb = Bitboard(1) shl 27
    var found: seq[Square]
    for sq in bb.squares:
      found.add(sq)
    check found == @[Square(27)]

  test "multiple bits yields all set squares in LSB order":
    # Set squares 0, 7, 63
    let bb = Bitboard(1) or (Bitboard(1) shl 7) or (Bitboard(1) shl 63)
    var found: seq[Square]
    for sq in bb.squares:
      found.add(sq)
    check found == @[Square(0), Square(7), Square(63)]

  test "full board yields 64 squares":
    var count = 0
    for _ in FullBoard.squares:
      inc count
    check count == 64

  test "rank 1 constant yields squares 0..7":
    var found: seq[Square]
    for sq in Rank1.squares:
      found.add(sq)
    check found == @[Square(0), Square(1), Square(2), Square(3),
                     Square(4), Square(5), Square(6), Square(7)]

  test "rank 8 constant yields squares 56..63":
    var found: seq[Square]
    for sq in Rank8.squares:
      found.add(sq)
    check found == @[Square(56), Square(57), Square(58), Square(59),
                     Square(60), Square(61), Square(62), Square(63)]


suite "bitboard constants":
  test "Rank1 has exactly 8 bits set":
    check countSetBits(Rank1) == 8

  test "Rank2 has exactly 8 bits set":
    check countSetBits(Rank2) == 8

  test "Rank7 has exactly 8 bits set":
    check countSetBits(Rank7) == 8

  test "Rank8 has exactly 8 bits set":
    check countSetBits(Rank8) == 8

  test "NotFileA has exactly 56 bits set":
    check countSetBits(NotFileA) == 56

  test "NotFileH has exactly 56 bits set":
    check countSetBits(NotFileH) == 56

  test "FullBoard has all 64 bits set":
    check countSetBits(FullBoard) == 64

  test "Rank1 and Rank8 do not overlap":
    check (Rank1 and Rank8) == 0

  test "NotFileA and NotFileH together exclude exactly the corners":
    # Squares on file A (0,8,16..56) and file H (7,15,23..63) — 16 squares total
    let fileAandH = (not NotFileA) or (not NotFileH)
    check countSetBits(fileAandH) == 16
