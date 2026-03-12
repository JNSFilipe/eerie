# Stage 21 TODO

## Goal

Make reverse visual `f` skip the character currently under the visual
cursor, including when the selection was started by `w`.

## Scope

- [x] Identify the actual visible cursor character for an active visual
  selection
- [x] Exclude that current cursor character from reverse visual `f`
  candidates
- [x] Fix `f<char> ; 1` on both plain visual and `w`-started selections

## Verification

- [x] Add ERT coverage for reverse visual `f` on a plain visual selection
- [x] Add ERT coverage for reverse visual `f` on a `w`-started selection
- [x] Re-run the full existing ERT suite and batch load smoke test
