# Stage 14 TODO

## Goal

Make `%` reliable across nested delimiters and common cursor positions at
end of line or end of buffer.

## Scope

- [x] Fix `%` for nested openers such as the inner `(` in `(())`
- [x] Keep `%` working for `(`/`)`, `[`/`]`, `{`/`}`, `"` and `'`
- [x] Make `%` work when point sits after a closing delimiter at end of
  line or end of buffer
- [x] Preserve visual `%` behavior on top of the corrected matcher

## Verification

- [x] Add ERT coverage for nested-opener `%`
- [x] Add ERT coverage for `%` at end of line before newline
- [x] Add ERT coverage for `%` at end of buffer after the last delimiter
- [x] Re-run the full existing ERT suite and batch load smoke test
