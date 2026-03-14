# Stage 32 TODO

## Goal

Make `W` fall back to the end of the current line when no later spaces
remain.

## Scope

- [x] Change the shared next-space helper so normal `W` falls back to
  `line-end-position` when no later spaces remain on the current line
- [x] Apply the same fallback to multi-cursor `W`
- [x] Keep repeated `W` advancing through later spaces before falling
  back to line end
- [x] Sync the docs and smoke notes with the new fallback behavior

## Verification

- [x] Add ERT coverage for normal `W` line-end fallback
- [x] Extend the existing multi-cursor `W` regression to cover line-end
  fallback
- [x] Re-run the full existing ERT suite and batch load smoke test
