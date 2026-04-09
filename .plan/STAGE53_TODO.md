# Stage 53 TODO

## Goal

Move the shipped `eerie` package into `lisp/` and restore package
loading under the new source layout.

## Tasks

- [x] Move `eerie.el` and every `eerie-*.el` module into `lisp/`
- [x] Update `Eask` to package and test from `lisp/`
- [x] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [x] Run the focused `-L lisp` ERT smoke test
- [x] Commit the `lisp/` source move

## Completed

- Moved the shipped `eerie` package entry point and every shipped
  module into `lisp/`.
- Updated `Eask` to package and test from the `lisp/` source layout.
- Verified the smoke test and focused ERT smoke test pass from
  `lisp/`.
