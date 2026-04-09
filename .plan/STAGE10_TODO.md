# Stage 10 TODO

## Goal

Close the first round of user-reported regressions after the Stage 9
feature work and add a manual smoke-test buffer.

## Scope

- [x] Bind normal-mode `u` to `eerie-undo`
- [x] Switch `eerie-undo` and `eerie-undo-in-selection` to Emacs-native
  undo commands
- [x] Fix linewise visual startup so `V` selects the current line at
  buffer edges
- [x] Fix blockwise vertical movement so `C-v` preserves the active
  column on `j` / `k`
- [x] Add an interactive demo file for manual smoke testing

## Verification

- [x] Add ERT coverage for the `u` binding
- [x] Add ERT coverage for linewise visual startup at buffer edges
- [x] Add ERT coverage for blockwise vertical movement preserving column
- [x] Re-run the full existing ERT suite and batch load smoke test

## Deferred From This Stage

- [ ] Full Vim-style block change/insert semantics
- [ ] Richer manual smoke documentation beyond the demo buffer itself
