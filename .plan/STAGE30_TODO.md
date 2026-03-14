# Stage 30 TODO

## Goal

Promote an active multi-edit target set into a normal-like multi-cursor
state.

## Scope

- [x] Add a dedicated Meow multi-cursor state with its own keymap and
  `ESC` cancellation path
- [x] Make visual `n` promote an active multi-edit target set into that
  multi-cursor state while still falling back to visual search repeat
  when multi-edit is inactive
- [x] Render secondary cursors with Meow fake-cursor overlays instead of
  keeping the original visual multi-edit overlays
- [x] Replay deterministic normal-mode key sequences across the
  secondary cursors from the primary cursor
- [x] Add dedicated multi-cursor `f` and `W` motions for line-local
  character finding and next-space movement across all cursors
- [x] Replay the primary insert session to the secondary cursors after
  insert-like commands such as `i`, `a`, `I`, `A`, and `c`
- [x] Clean up multi-edit and multi-cursor state on `ESC` and on mode
  shutdown

## Verification

- [x] Add ERT coverage for visual `n` promotion from multi-edit
- [x] Add ERT coverage for multi-cursor normal-mode replay
- [x] Add ERT coverage for multi-cursor `f`
- [x] Add ERT coverage for multi-cursor `W`
- [x] Add ERT coverage for multi-cursor insert replay
- [x] Add ERT coverage for `ESC` cancellation
- [x] Re-run the full existing ERT suite and batch load smoke test
