# Stage 34 TODO

## Goal

Keep live multi-cursor visual-entry and visual-retargeting commands in
the multi-cursor visual state so real keypress flows keep applying to
every cursor instead of silently dropping back to the primary one.

## Tasks

- [x] Keep visual-entry commands such as `v`, `V`, and `C-v` in
  `multicursor-visual` when a multi-cursor session is active
- [x] Keep visual retargeting commands such as `vi(` and `va"` in
  `multicursor-visual` when a multi-cursor session is active
- [x] Add live key-sequence coverage for multi-cursor `v`
- [x] Add live key-sequence coverage for multi-cursor `vi(`
- [x] Keep nested-input `f<char>1` coverage exercising the real
  post-command replay path
- [x] Harden the test harness so command-loop state from one test does
  not leak into later tests
- [x] Update README, AGENTS, and `.plan/PLAN.md`
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
