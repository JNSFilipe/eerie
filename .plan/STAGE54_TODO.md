# Stage 54 TODO

## Goal

Finish the layout reorganization by updating canonical commands and
docs, deleting stale legacy files, and closing the final audit.

## Tasks

- [x] Update `README.md`, `AGENTS.md`, `.plan/*`, and the interactive
  demo header to use `-L lisp`
- [x] Delete the stale root `.org` docs
- [x] Delete the tracked editor backup files
- [x] Run the final stale-path audit
- [x] Run the final smoke test and the full ERT suite from `lisp/`
- [x] Mark the tracker complete and commit the closeout

## Completed

- Updated the canonical verification commands, tracker entries, and
  interactive demo launch comment to use the `lisp/` source layout.
- Deleted the stale root `.org` docs and removed the tracked editor
  backup clutter from the repository tree.
- Verified the final canonical-doc audit is clean and re-ran the final
  smoke test plus the full ERT suite from `lisp/`.
