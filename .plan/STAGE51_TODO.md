# Stage 51 TODO

## Goal

Finish the hard rename by updating canonical docs and packaging, then
auditing the shipped surface for stale pre-rename references.

## Tasks

- [x] Update `README.md`, `AGENTS.md`, `.plan/PLAN.md`, and
  `.plan/STAGE48_TODO.md` through `.plan/STAGE51_TODO.md` to `eerie`
- [x] Update `CHANGELOG.md` with a short note about the hard rename
- [x] Audit the shipped surface for stale pre-rename references
- [x] Run the final package-load smoke test
- [x] Run the final full renamed ERT suite
- [x] Commit the canonical doc and packaging pass

## Completed

- Updated the canonical docs and tracker files to the `eerie` package
  identity.
- Added a changelog note for the hard rename and clarified that the
  historical changelog entries are mechanically rewritten to the
  current surface.
- Renamed `meow.svg` to `eerie.svg`, updated the local `README.org`
  reference, and aligned `Eask` package metadata with the renamed
  package identity.
- Verified the shipped-surface audit is clean and re-ran the final
  smoke test plus the full renamed ERT suite.
