# Stage 20 TODO

## Goal

Make `f` extend an active visual selection, including selections that were
started by `w`.

## Scope

- [x] Add a visual-state `f` command
- [x] Reuse the visible-char hint loop for visual `f`
- [x] Make visual `f` extend the current selection instead of replacing it
- [x] Bind `f` in the visual-state keymap

## Verification

- [x] Add ERT coverage for visual `f` extending a plain visual selection
- [x] Add ERT coverage for visual `f` extending a `w`-started selection
- [x] Re-run the full existing ERT suite and batch load smoke test
