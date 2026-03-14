# Stage 26 TODO

## Goal

Implement the first multi-edit occurrence builder with visual `m`, `;`,
and `s`.

## Scope

- [x] Start or extend multi-edit from the current charwise visual
  selection with visual `m`
- [x] Freeze the original seed text and match exact, case-sensitive,
  non-overlapping occurrences in the current buffer
- [x] Make repeated `m` add the next unselected match in the current
  direction
- [x] Make visual `;` reverse the builder direction for later `m` and
  `s`
- [x] Make visual `s` skip one match in the current direction without
  adding it
- [x] Keep the newest target as the active visual selection and render
  older targets as secondary overlays

## Verification

- [x] Add ERT coverage for forward `m`
- [x] Add ERT coverage for repeated forward `m`
- [x] Add ERT coverage for reverse `; m`
- [x] Add ERT coverage for `s m`
- [x] Add ERT coverage for starting from a `w`-created selection
- [x] Re-run the full existing ERT suite and batch load smoke test
