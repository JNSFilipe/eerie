# Stage 19 TODO

## Goal

Ensure the currently selected `w` occurrence is never assigned a numbered
hint, including after `;` reverses direction.

## Scope

- [x] Add candidate exclusion support to the visible regex collector
- [x] Exclude the active `w` selection from numbered hints
- [x] Fix `w ; 1` so it jumps to the previous occurrence instead of the
  current word

## Verification

- [x] Add ERT coverage for `w ; 1` skipping the current word
- [x] Re-run the full existing ERT suite and batch load smoke test
