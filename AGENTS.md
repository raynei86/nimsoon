# Nimsoon Agent Guide

This document is a practical reference for contributors and automation agents working on Nimsoon. It focuses on implementation details, performance considerations, and the idiomatic Nim style that the library strives to preserve.

## Goals

- Provide a clear, consistent API for chess engine operations.
- Favor performance-critical patterns that are common in engine code.
- Keep the public API idiomatic to Nim, minimizing surprising constructs.
- Ensure deterministic behavior in compile-time generated data.

## Code Organization

Nimsoon is organized into small, focused modules. The dependency direction is intentionally shallow to keep compile-time and runtime costs predictable.

- `src/nimsoon/types.nim`
  - Core types such as `Square`, `Bitboard`, `HashKey`, `Color`, and `PieceType`.
  - Board constants (files, ranks, castling paths) and fast bitboard utilities.
  - Keep types compact; prefer enums and bitboards for hot-path operations.

- `src/nimsoon/position.nim`
  - `Position` owns the board state and game state.
  - Board fields (`pieces`, `colors`, `occupied`) are private and exposed via read-only getters.
  - Mutation happens through dedicated procedures (`placePiece`, `removePiece`).

- `src/nimsoon/move.nim`
  - `Move` representation plus `MoveFlag`.
  - `doMove` performs a full state transition and updates clocks/rights.

- `src/nimsoon/movegen.nim`
  - Bitboard-driven move generation with inline iterators.
  - Public iterators are nouns (`pawnMoves`, `pseudoLegalMoves`).
  - Templates are used for local code reuse (pawn generation).

- `src/nimsoon/magic.nim`
  - Magic bitboard tables and compile-time generation for rook/bishop attacks.

- `src/nimsoon/fen.nim`
  - FEN parsing and construction of `Position`.

- `src/nimsoon/zobrist.nim`
  - Deterministic Zobrist hashing tables generated at compile time.
  - Small helper APIs for hashing pieces, castling, side-to-move, and en passant.

## Performance Principles

Performance matters. The code intentionally uses patterns that keep hot paths tight and predictable.

- **Bitboards first**: Board operations use `uint64` bitboards and bitwise ops for speed.
- **Inline hot functions**: Small, frequently used functions use `{.inline.}`.
- **Compile-time precomputation**: Large tables (magic, Zobrist) are generated with `{.compileTime.}` and stored as `const`.
- **Iterators for movegen**: `iterator` is used for streaming moves without allocations.
- **Avoid extra allocations**: Prefer `array` and `set` over `seq` in hot code.

## Idiomatic Nim Style

Nimsoon aims to be idiomatic without sacrificing performance. Key style conventions:

- **CamelCase** for function names (`fileOf`, `rankOf`, `parseSquare`).
- **Pure enums** with `{.pure.}` so values are unprefixed and names are clean (`Pawn`, `WhiteKingside`).
- **Subject-first parameter ordering** for methods (`isOccupied(pos, sq)`).
- **`func` vs `proc`**: use `func` for side-effect-free work, `proc` for mutations.
- **Explicit mutability** with `var` parameters for state changes.

## Zobrist Hashing

Zobrist hashing is implemented in `src/nimsoon/zobrist.nim` with a deterministic seed.

- **Seed**: `0xDECAFBAD'u64` (fixed for reproducibility).
- **PRNG**: compile-time `splitmix64` to generate table values.
- **Tables**:
  - `PieceKeys[color][piece][sq]`
  - `SideKey`
  - `CastlingKeys[side]`
  - `EpFileKeys[file]`

### Hashing Strategy

- **Piece placement**: XOR key for every occupied square by color/piece.
- **Side to move**: XOR `SideKey` for black.
- **Castling rights**: XOR each active castling key.
- **En passant**: XOR by **file only** (standard Zobrist practice).

### Incremental Updates

When hash updates are incremental in `doMove`, the sequence should be:

1. XOR out old side/castling/ep.
2. XOR out moving piece from source square.
3. XOR out captured piece (or EP capture square).
4. XOR in moving piece on target square.
5. Handle promotions and castling rook moves.
6. XOR in new side/castling/ep.

Keep this logic in sync with `hashPosition` so you can validate correctness by recomputing.

## Position Construction

`Position` fields `pieces`, `colors`, and `occupied` are private to protect invariants. Use:

- `newPosition(...)` for controlled initialization.
- `placePiece` / `removePiece` for updates.

Avoid setting board bitboards directly; it breaks encapsulation and may desync derived data.

## Compile-Time Generation Guidance

Compile-time functions are used to generate tables for speed and determinism. Rules:

- Keep compile-time functions pure and deterministic.
- Avoid heap allocations or I/O.
- Return `array`/`tuple` structures rather than `seq`.

## Testing Expectations

When adding or changing logic, update tests accordingly:

- Validate Zobrist determinism for fixed FENs.
- Check that `doMove` hash matches `hashPosition` recompute.
- Ensure castling/ep/promotion/capture cases are covered.

## Typical Workflow

- Add or modify APIs in `types.nim` and `position.nim` only when necessary.
- Keep hot-path changes minimal and measure where possible.
- Prefer compile-time tables over runtime computation in performance-critical code.

## Common Pitfalls

- Direct access to private fields in `Position`
- Forgetting to update hash when altering `doMove` logic.
- Diverging incremental hash updates from `hashPosition`.
- Introducing `seq` allocations in hot-path move generation.

## Agent Guidance

- Preserve consistent naming and module boundaries.
- Optimize only where it matters, and document non-obvious optimizations.
- Run tests with `nimble build`
- Individual tests can be run with `nim r tests/test_file.nim`
