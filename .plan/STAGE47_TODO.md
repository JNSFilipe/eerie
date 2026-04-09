# Stage 47 TODO

## Goal

Make linewise visual `V` and its numbered hint loop follow logical
buffer lines even when display wrapping is active, so repeated line
jumps do not get stuck on wrapped rows.

## Tasks

- [x] Add a wrapped-line regression for repeated `V` hint selection
- [x] Make linewise visual range and movement use logical lines
- [x] Keep the existing linewise hint, anchor, and edge behavior green
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite

## Completed

- Added a regression for `V1111` on a wrapped first line and locked the
  expected behavior to logical line advancement instead of wrapped-row
  reuse.
- Switched the linewise visual range, linewise movement, and visible
  line-candidate collector from wrapped visual rows to logical lines.
- Removed the old wrapped-row direction probe behavior at buffer edges
  by using logical line stepping in the `V` hint path.
