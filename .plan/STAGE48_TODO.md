# Stage 48 TODO

## Goal

Bootstrap the hard rename by creating the missing stage trackers and
moving the test harness onto the future `eerie` surface before the
package itself exists.

## Tasks

- [x] Add Stage 48 through Stage 51 entries to `.plan/PLAN.md`
- [x] Create `STAGE48_TODO.md` through `STAGE51_TODO.md`
- [x] Rename `tests/meow-vim-tests.el` to `tests/eerie-vim-tests.el`
- [x] Rename `tests/meow-interactive-demo.el` to
  `tests/eerie-interactive-demo.el`
- [x] Change the renamed ERT suite to `(require 'eerie)` and start
  renaming canonical test names to `eerie-*`
- [x] Run the focused renamed test and confirm it fails red because the
  `eerie` package surface does not exist yet
- [x] Commit the tracker bootstrap and red test harness

## Completed

- Added Stage 48 through Stage 51 tracker entries to `.plan/PLAN.md`
  and created `STAGE48_TODO.md` through `STAGE51_TODO.md`.
- Renamed the ERT suite and interactive demo to `tests/eerie-*`.
- Switched the renamed test harness to `(require 'eerie)` and renamed
  the canonical keymap smoke test to
  `eerie-default-normal-keymap-is-vim-like`.
- Verified the focused renamed test fails red with `Cannot open load
  file ... eerie`.
