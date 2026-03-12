# Stage 16 TODO

## Goal

Replace the useful visible-jump parts of the user-provided `avy.el` with
Meow-native commands for `f` and `w` so the external file is no longer
needed at runtime.

## Scope

- [x] Add a Meow-owned visible jump loop for current-window candidates
- [x] Bind normal-mode `f` to visible char jumping
- [x] Bind normal-mode `w` to visible word-occurrence jumping
- [x] Support digits `1` through `9` for candidate selection
- [x] Support `;` to reverse jump direction inside the loop
- [x] Reuse Meow overlays and jumplist helpers instead of depending on
  `avy.el`
- [x] Remove shipped default references to external `avy-*` commands

## Verification

- [x] Add ERT coverage for normal-mode `f` and `w` key bindings
- [x] Add ERT coverage for numbered visible-char jumps
- [x] Add ERT coverage for `;` direction reversal
- [x] Add ERT coverage for visible word-occurrence jumps
- [x] Update the interactive smoke buffer with `f` / `w` targets
- [x] Re-run the full existing ERT suite and batch load smoke test
