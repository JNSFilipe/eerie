# Stage 28 TODO

## Goal

Make multi-edit delete and change act across the full target set.

## Scope

- [x] Make visual multi-edit `d` delete all current targets
- [x] Leave point at the primary target start after multi-edit delete
- [x] Make visual multi-edit `c` delete all current targets and enter a
  replay-backed INSERT session at the primary target
- [x] Replay the primary insert session to the remaining targets on
  `ESC`
- [x] Clear the multi-edit session once delete or change finishes

## Verification

- [x] Add ERT coverage for multi-edit visual `d`
- [x] Add ERT coverage for replay-backed multi-edit visual `c`
- [x] Re-run the full existing ERT suite and batch load smoke test
