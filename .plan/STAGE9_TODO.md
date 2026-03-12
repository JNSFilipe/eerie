# Stage 9 TODO

## Goal

Finish the remaining jumplist gaps by making jump history window-local,
adding Vim-style search jumps, and automatically capturing registered
third-party navigation commands.

## Scope

- [x] Move jump back and forward stacks to per-window storage while keeping
  `C-o` and `C-i` behavior intact
- [x] Add `/`, `?`, `n`, and `N` style search commands in normal mode
- [x] Reuse Emacs regex search primitives and Meow's search ring for the new
  search commands
- [x] Add automatic jump recording for registered non-Meow navigation
  commands
- [x] Ship a default tracked-command list for core Emacs jump commands and
  common third-party navigation packages

## Design Constraints

- [x] Record only successful relocations and keep duplicate suppression
- [x] Avoid double-recording Meow commands that already use explicit jump
  helpers
- [x] Treat the destination selected window as the owner of the new jump
  entry
- [x] Keep search commands in normal mode without creating visual selections

## Verification

- [x] Add ERT coverage for `/`, `?`, `n`, and `N` key dispatch
- [x] Add ERT coverage for search commands creating jumplist entries and
  supporting `C-o` / `C-i`
- [x] Add ERT coverage for automatic capture of a non-Meow navigation command
- [x] Add ERT coverage that jumplists are isolated per window
- [x] Re-run the full existing ERT suite and batch load smoke test

## Deferred From This Stage

- [ ] Search motions as operator targets
- [ ] Full Vim search options such as `*`, `#`, and search offsets
- [ ] Cross-session persistence of jump history
