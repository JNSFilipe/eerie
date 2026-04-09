# Stage 58 TODO

## Goal

Remove the legacy Eerie keypad state and use native Emacs 30+
which-key for leader-prefix discovery and the persistent multicursor
help popup.

## Tasks

- [x] Add failing ERT coverage for direct `SPC` leader prefixes,
  keypad removal, automatic `which-key-mode`, and multicursor help
  show/hide behavior
- [x] Delete the `eerie-keypad.el` module and remove the `keypad`
  state from state, face, variable, shim, and keymap registries
- [x] Bind normal, visual, and motion `SPC` directly to the dedicated
  Eerie leader keymap
- [x] Enable native `which-key-mode` from `eerie-global-mode` without
  disabling a user-managed which-key session on Eerie shutdown
- [x] Route the persistent multicursor help popup through native
  which-key wrappers
- [x] Raise the package baseline to Emacs 30.1+
- [x] Update `README.org`, `AGENTS.md`, `.plan/PLAN.md`, and this
  stage tracker
- [x] Run the focused Stage 58 ERT regression set
- [x] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [x] Run `emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit`

## Completed

- Wrote regression coverage before implementation and verified the new
  tests failed against the old keypad-backed behavior.
- Removed the old keypad module and its state machine surface.
- Replaced keypad-backed `SPC` dispatch with direct leader prefix
  maps, leaving regular `C-x` and `C-c` prefixes untouched.
- Added native which-key lifecycle management to `eerie-global-mode`.
- Moved multicursor persistent help display and teardown onto native
  which-key wrappers.
- Updated package metadata and canonical documentation for the Emacs
  30.1+ baseline and native which-key behavior.
- Re-ran the package load smoke test and full ERT suite after the
  migration.
