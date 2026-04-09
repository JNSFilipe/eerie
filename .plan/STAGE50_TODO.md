# Stage 50 TODO

## Goal

Rename the shipped Lisp symbol surface to `eerie-*` and make the renamed
ERT suite pass.

## Tasks

- [x] Run the renamed suite once and confirm it fails on stale
  pre-rename surface references
- [x] Rename shipped commands, variables, modes, faces, helpers, and
  internal state to `eerie-*`
- [x] Update `tests/eerie-vim-tests.el` and
  `tests/eerie-interactive-demo.el` to the new surface
- [x] Run the focused renamed regressions
- [x] Run the full renamed ERT suite
- [x] Commit the renamed Lisp symbol surface

## Completed

- Confirmed the renamed suite fails red before the symbol rename, with
  unresolved `eerie-*` symbols and stale pre-rename state references.
- Renamed the shipped Lisp symbol surface to `eerie-*`.
- Updated the renamed ERT suite and the interactive demo to use the
  `eerie-*` entry point and symbol surface.
- Verified the focused renamed regressions and the full renamed ERT
  suite pass.
