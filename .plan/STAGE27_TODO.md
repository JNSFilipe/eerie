# Stage 27 TODO

## Goal

Make the multi-edit target set manageable before destructive actions.

## Scope

- [x] Add visual `,` to remove the most recently added multi-edit target
- [x] Keep target ordering stable so later actions apply predictably
- [x] Keep overlap handling strict so partial overlaps are rejected
- [x] Keep the original multi-edit seed text unchanged for later `m` and
  `s` matching

## Verification

- [x] Add ERT coverage for visual `,`
- [x] Re-run the full existing ERT suite and batch load smoke test
