# Stage 56 TODO

## Goal

Restore the root logo on the GitHub-rendered Org README by replacing
the HTML export block with an Org-native image link.

## Tasks

- [x] Replace the `README.org` logo HTML export block with a direct
  Org image link to `eerie.png`
- [x] Keep the rest of the canonical README content unchanged
- [x] Run `rg -n --fixed-strings '[[file:eerie.png]]' README.org`
- [x] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [x] Run `emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit`

## Completed

- Replaced the `README.org` logo HTML export block with a direct Org
  image link to `eerie.png`.
- Kept the rest of the canonical README content unchanged.
- Re-ran the smoke test and full ERT suite after the README rendering
  fix.
