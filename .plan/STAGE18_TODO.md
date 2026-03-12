# Stage 18 TODO

## Goal

Keep the `w` visible-jump selection behavior from Stage 17, but place
point at the end of the selected word instead of the beginning.

## Scope

- [x] Change `w` so the selected word bounds stay the same
- [x] Place point at the end of the selected word after `w`
- [x] Preserve the existing visual-state behavior for movement, actions,
  and `ESC`

## Verification

- [x] Update ERT coverage for `w` to assert the selected bounds
- [x] Update ERT coverage for `w` to assert point is at the word end
- [x] Re-run the full existing ERT suite and batch load smoke test
