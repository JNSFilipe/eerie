# Stage 42 TODO

## Goal

Make block visual `I` and `A` behave like multi-line insert and
append instead of being undefined in `C-v`.

## Tasks

- [x] Reproduce the missing `C-v I` and `C-v A` bindings with real key
  sequences
- [x] Bind visual `I` and `A` to block-specific insert and append
  commands
- [x] Extend replay targeting so block insert sessions can target a
  column on each selected line
- [x] Add regression coverage for real `C-v j I ... ESC` and
  `C-v j A ... ESC` flows
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
