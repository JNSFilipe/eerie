# Stage 50 TODO

## Goal

Rename the shipped Lisp symbol surface to `eerie-*` and make the renamed
ERT suite pass.

## Tasks

- [ ] Run the renamed suite once and confirm it fails on stale
  `meow-*` surface references
- [ ] Rename shipped commands, variables, modes, faces, helpers, and
  internal state from `meow-*` to `eerie-*`
- [ ] Update `tests/eerie-vim-tests.el` and
  `tests/eerie-interactive-demo.el` to the new surface
- [ ] Run the focused renamed regressions
- [ ] Run the full renamed ERT suite
- [ ] Commit the renamed Lisp symbol surface

## Completed

- None yet.
