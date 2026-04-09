# Stage 49 TODO

## Goal

Rename the original package entry point and module graph to `eerie` so
the renamed package loads again.

## Tasks

- [x] Rename the entry point to `eerie.el`
- [x] Rename every shipped module to `eerie-*.el`
- [x] Update file headers, `require`, `provide`, and `declare-function`
  references to `eerie-*`
- [x] Update `Eask` package metadata, file globs, and test script to the
  renamed package
- [x] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [x] Commit the renamed module graph

## Completed

- Renamed the original entry point and module graph to `eerie*.el`.
- Updated the file headers plus `require`, `provide`, and module-string
  references needed for the renamed feature graph to load.
- Updated `Eask` to package `eerie`, load `lisp/eerie.el`, glob
  `lisp/eerie*.el`, and run `tests/eerie-vim-tests.el`.
- Verified `emacs -Q --batch -L lisp -l lisp/eerie.el` passes.
