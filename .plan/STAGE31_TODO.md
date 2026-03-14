# Stage 31 TODO

## Goal

Make `W` a first-class normal-mode motion and align it with the
dedicated multi-cursor `W` behavior.

## Scope

- [x] Add normal-mode `W` as a next-space motion on the current line
- [x] Share the underlying next-space helper between normal `W` and
  multi-cursor `W`
- [x] Keep repeat behavior consistent so a repeated `W` advances to the
  following space
- [x] Keep multi-cursor `W` as a dedicated multicursor-native command

## Verification

- [x] Add ERT coverage for normal `W`
- [x] Re-run the existing multi-cursor `W` coverage
- [x] Re-run the full existing ERT suite and batch load smoke test
