# Stage 13 TODO

## Goal

Close two Vim-parity nits: keep yank operators from moving the cursor and
add `%` matching-delimiter jumps.

## Scope

- [x] Keep the cursor at its original position after Vim-style yank
  operators such as `yy`
- [x] Add normal-mode `%` for matching `(`/`)`, `[`/`]`, `{`/`}`,
  `"` and `'`
- [x] Add visual-mode `%` so matching-delimiter jumps extend the active
  selection
- [x] Reuse the existing Vim text-object delimiter mapping for `%`

## Verification

- [x] Add ERT coverage for `yy` preserving point
- [x] Add ERT coverage for normal `%` on bracket and quote delimiters
- [x] Add ERT coverage for visual `%` extending the selection
- [x] Re-run the full existing ERT suite and batch load smoke test
