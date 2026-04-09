# Stage 41 TODO

## Goal

Make Vim-style block visual mode start with a real one-character-wide
rectangle so direct block operations work immediately from `C-v`.

## Tasks

- [x] Reproduce the block-visual regression with a real `C-v` flow
- [x] Change block visual startup so it selects the current character
  column instead of a zero-width rectangle
- [x] Keep blockwise vertical movement column-stable with the new
  initial rectangle width
- [x] Add regression coverage for the initial rectangle contents and a
  real `C-v j d` deletion flow
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
