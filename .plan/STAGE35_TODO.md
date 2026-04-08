# Stage 35 TODO

## Goal

Make `W` advance correctly when the cursor was spawned from a
`w`-style word selection and is sitting on the end-of-word boundary just
before a space.

## Tasks

- [x] Skip the immediate separator when `W` starts from a `w`-style
  end-of-word boundary
- [x] Keep repeated `W` behavior and line-end fallback intact
- [x] Add normal-mode regression coverage for the boundary case
- [x] Add multicursor regression coverage for `w -> m -> n -> W`
- [x] Update README, AGENTS, and `.plan/PLAN.md`
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
