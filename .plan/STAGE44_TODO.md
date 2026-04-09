# Stage 44 TODO

## Goal

Remove non-canonical multiedit and multicursor compatibility paths that
no longer serve the shipped workflow.

## Tasks

- [x] Delete `meow-visual-search-next-or-multicursor`, which Stage 43
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

- Removed the legacy `meow-visual-search-next-or-multicursor`
  compatibility entry point from `meow-command.el`.
- Removed the dead `meow-visual-search-next-or-multicursor`
  declaration from `meow-keymap.el`.
- Removed the stale multi-edit post-command allowlist entry that only
  kept the deleted dispatcher alive.
- Replaced the remaining Stage 44 helper-style multicursor builder
  regressions with canonical `mw.,d` and `mw.-.d` key-sequence tests,
  plus a direct assertion that the deleted dispatcher is no longer
  defined.

## Retained On Purpose

- `meow-multiedit-match-next`, `meow-multiedit-unmatch-last`,
  `meow-multiedit-skip-match`, and
  `meow-multiedit-reverse-direction` remain live because the canonical
  multicursor builder still delegates to them internally and the test
  suite still exercises their shipped semantics.
