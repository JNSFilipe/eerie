# Stage 52 TODO

## Goal

Bootstrap the repository layout reorganization by adding honest stage
trackers and proving the future `lisp/` load path is red before the
source move.

## Tasks

- [x] Add Stage 52 through Stage 54 to `.plan/PLAN.md`
- [x] Create `STAGE52_TODO.md` through `STAGE54_TODO.md`
- [x] Point `tests/eerie-vim-tests.el` at the future `lisp/` load path
- [x] Run the focused `-L lisp` ERT command and confirm it fails red
- [x] Commit the tracker bootstrap

## Completed

- Added Stage 52 through Stage 54 to the canonical tracker and created
  the new stage TODO files.
- Pointed `tests/eerie-vim-tests.el` at the future `lisp/` load path.
- Verified the focused `-L lisp` ERT command fails red because the
  source directory has not moved yet.
