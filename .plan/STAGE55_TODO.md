# Stage 55 TODO

## Goal

Replace the canonical Markdown README with an Org README and update
the repository tracker to point at the new canonical file.

## Tasks

- [x] Convert the root README content from `README.md` to `README.org`
- [x] Update `AGENTS.md` and `.plan/*` to treat `README.org` as the
  canonical user-facing overview
- [x] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [x] Run `emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit`

## Completed

- Converted the root user-facing overview from `README.md` to
  `README.org` without changing the documented behavior.
- Updated `AGENTS.md` and the canonical tracker to point at
  `README.org` as the maintained README.
- Re-ran the standard smoke test and full ERT suite after the
  canonical README format change.
