# Stage 25 TODO

## Goal

Introduce a first-class multi-edit session lifecycle that integrates
with the current visual workflow.

## Scope

- [x] Add buffer-local session state for the immutable seed text,
  direction, primary target, secondary targets, and search head
- [x] Render secondary targets with Eerie overlays instead of live cursors
- [x] Restrict v1 session startup to active charwise visual selections
- [x] Clear the full session on `ESC`, including overlays and active
  selection state
- [x] Tear down extra targets when unsupported commands leave the
  builder flow

## Verification

- [x] Add ERT coverage for session startup from a charwise visual
  selection
- [x] Add ERT coverage for `ESC` clearing the full multi-edit session
- [x] Re-run the full existing ERT suite and batch load smoke test
