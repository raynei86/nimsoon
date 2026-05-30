# Nimsoon
A rewrite of [monsoon](https://github.com/raynei86/monsoon) in Nim
because performance optimization is too fun.


# Examples

Generate pseudo-legal moves:

```nim
import nimsoon

let pos = positionFromFen("rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1")
for mv in pos.pseudoLegalMoves:
  discard mv

# Alternatively:
import std/sequtils
let moves = toSeq(pos.pseudoLegalMoves)
# Now do what you need to do with a sequence...
```


# Disclaimer
I oversaw all the code written in this codebase, but it was created
with the help of coding agents. Basically all the tests were created
by agents. But the logic of the main library was taken from my
original Lisp implementation.
