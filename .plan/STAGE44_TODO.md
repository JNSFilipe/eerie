# Stage 44 TODO

## Goal

Remove non-canonical multiedit and multicursor compatibility paths that
no longer serve the shipped workflow.

## Tasks

- [ ] Delete the compatibility surface Stage 43 marked dead, starting
  with `meow-visual-search-next-or-multicursor`
- [ ] Replace the remaining helper-style multicursor tests with real
  key-sequence regressions for `m`, `.`, `,`, `-`, and `ESC`
- [ ] Remove any dead keymap declarations or allowlist entries that only
  exist to preserve removed multiedit entry points
- [ ] Re-run the focused multicursor and multiedit regressions after
  each cleanup slice
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
