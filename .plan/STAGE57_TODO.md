# Stage 57 TODO

## Goal

Make `C-n`, `C-p`, `C-b`, and `C-f` available as Emacs-style
navigation in normal mode, and expose standard `C-x` / `C-c` prefixes
there without changing insert mode semantics.

## Tasks

- [x] Update the normal-mode keymap contract in the ERT suite for
  `C-n`, `C-p`, `C-b`, `C-f`, `C-x`, and `C-c`
- [x] Bind normal and multicursor-normal `C-n`, `C-p`, `C-b`, and
  `C-f` to the existing movement commands
- [x] Expose the regular Emacs `C-x` and `C-c` prefix maps in normal mode
- [x] Keep `h`, `j`, `k`, and `l` working after adding the control-key aliases
- [x] Move the `SPC` leader off `mode-specific-map` so `C-c` stays vanilla
- [x] Update `README.org`, `AGENTS.md`, and `.plan/*` to match the new
  shipped defaults
- [x] Run `emacs -Q --batch -L lisp -l lisp/eerie.el`
- [x] Run `emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit`

## Completed

- Updated the normal-mode keymap contract in the ERT suite for
  `C-n`, `C-p`, `C-b`, `C-f`, and the regular `C-x` / `C-c` control
  prefixes.
- Bound normal and multicursor-normal `C-n`, `C-p`, `C-b`, and `C-f`
  to the shipped movement commands while keeping the plain defaults on
  `f`, `p`, and `n`.
- Replaced the old macro-based vertical motions with direct line
  movement so `h j k l` and `C-n` / `C-p` work together without
  recursive keybinding loops.
- Adjusted that shared vertical motion path to follow wrapped screen
  lines again, while restoring the original buffer column whenever the
  move lands on a different logical line.
- Moved the `SPC` leader bindings onto a dedicated Eerie leader keymap
  so normal-mode `C-c` remains the regular Emacs prefix map instead of
  carrying Eerie leader entries.
- Updated `README.org`, `AGENTS.md`, `.plan/*`, and the interactive
  demo to match the new normal-mode defaults.
- Added real key-sequence regression coverage for `h j k l`,
  `C-n C-p C-b C-f`, and the dedicated leader-map split before
  re-running the package smoke test and full ERT suite.
