# Stage 29 TODO

## Goal

Make multi-edit `i` and `a` behave like Vim-style insert and append.

## Scope

- [x] Make active multi-edit visual `i` enter INSERT at the beginning of
  every selected target
- [x] Make active multi-edit visual `a` enter INSERT after every
  selected target
- [x] Reuse the replay path from multi-edit `c` for both commands
- [x] Use exact insertion positions so append does not drift by one
  character during replay
- [x] Keep plain visual `i` and `a` working as text-object selectors
  outside multi-edit

## Verification

- [x] Add ERT coverage for multi-edit visual `i`
- [x] Add ERT coverage for multi-edit visual `a`
- [x] Re-run the full existing ERT suite and batch load smoke test
