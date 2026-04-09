# Stage 44 TODO

## Goal

Remove non-canonical multiedit and multicursor compatibility paths that
no longer serve the shipped workflow.

## Tasks

- [x] Delete `eerie-visual-search-next-or-multicursor`, which Stage 43
  already classified as the only confirmed delete candidate
- [x] Replace the remaining helper-style multicursor tests with real
  key-sequence regressions for `m`, `.`, `,`, `-`, and `ESC`
- [x] Remove any dead keymap declarations or allowlist entries that only
  exist to preserve removed multiedit entry points
- [x] Re-run the focused multicursor and multiedit regressions after
  each cleanup slice
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite

## Completed

- Removed the legacy `eerie-visual-search-next-or-multicursor`
  compatibility entry point from `eerie-command.el`.
- Removed the dead `eerie-visual-search-next-or-multicursor`
  declaration from `eerie-keymap.el`.
- Removed the stale multi-edit post-command allowlist entry that only
  kept the deleted dispatcher alive.
- Replaced the remaining Stage 44 helper-style multicursor builder
  regressions with canonical `mw.,d` and `mw.-.d` key-sequence tests,
  plus a direct assertion that the deleted dispatcher is no longer
  defined.

## Retained On Purpose

- `eerie-multiedit-match-next`, `eerie-multiedit-unmatch-last`,
  `eerie-multiedit-skip-match`, and
  `eerie-multiedit-reverse-direction` remain live because the canonical
  multicursor builder still delegates to them internally and the test
  suite still exercises their shipped semantics.
