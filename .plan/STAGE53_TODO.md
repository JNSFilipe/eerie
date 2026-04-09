# Stage 53 TODO

## Goal

Move the shipped `eerie` package into `lisp/` and restore package
loading under the new source layout.

## Tasks

- [ ] Move `eerie.el` and every `eerie-*.el` module into `lisp/`
- [ ] Update `Eask` to package and test from `lisp/`
- [ ] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [ ] Run the focused `-L lisp` ERT smoke test
- [ ] Commit the `lisp/` source move

## Completed

- None yet.
