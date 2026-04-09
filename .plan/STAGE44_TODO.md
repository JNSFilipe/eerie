# Stage 44 TODO

## Goal

Remove non-canonical multiedit and multicursor compatibility paths that
no longer serve the shipped workflow.

## Tasks

- [ ] Delete `meow-visual-search-next-or-multicursor`, which Stage 43
  already classified as the only confirmed delete candidate
- [ ] Replace the remaining helper-style multicursor tests with real
  key-sequence regressions for `m`, `.`, `,`, `-`, and `ESC`
- [ ] Remove any dead keymap declarations or allowlist entries that only
  exist to preserve removed multiedit entry points
- [ ] Re-run the focused multicursor and multiedit regressions after
  each cleanup slice
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
