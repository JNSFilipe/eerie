# Stage 15 TODO

## Goal

Stop horizontal movement from wrapping across line boundaries and add `$`
as a line-end motion in normal and visual mode.

## Scope

- [x] Make normal `h` clamp at the beginning of the line
- [x] Make normal `l` clamp at the end of the line
- [x] Make visual `h` / `l` clamp at line boundaries
- [x] Add normal `$` to move to the end of the current line
- [x] Add visual `$` to extend the selection to the end of the current
  line

## Verification

- [x] Add ERT coverage for normal `h` / `l` staying on the current line
- [x] Add ERT coverage for visual `h` / `l` staying on the current line
- [x] Add ERT coverage for normal `$`
- [x] Add ERT coverage for visual `$`
- [x] Re-run the full existing ERT suite and batch load smoke test
