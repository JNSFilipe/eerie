# Stage 8 TODO

## Goal

Broaden jump history so `C-o` and `C-i` work across the fork's explicit
location-jump commands instead of only `gg`, `G`, and `gd`, while keeping
the jumplist small and predictable.

## Scope

- [x] Introduce a single reusable helper for recording a jump before
  commands that intentionally relocate point
- [x] Preserve the current back-stack and forward-stack model, including
  duplicate suppression and dead-marker pruning
- [x] Extend jump recording to `meow-goto-line`, `meow-goto-buffer-start`,
  `meow-goto-buffer-end`, and `meow-goto-definition`
- [x] Extend jump recording to Meow's mark-based jump helpers
  `meow-pop-to-mark`, `meow-unpop-to-mark`, and `meow-pop-to-global-mark`
- [x] Keep ordinary movement commands and operator motions out of jump
  history

## Design Constraints

- [x] Record only explicit relocations that users will reasonably expect to
  revisit with `C-o` and `C-i`
- [x] Recording a fresh jump clears forward history, but moving backward or
  forward through the jumplist does not
- [x] Keep the implementation local to Meow-owned commands instead of
  globally advising every point-moving command
- [x] Support cross-buffer round trips without depending on buffer-local
  state

## Verification

- [x] Add ERT coverage for repeated-location dedupe when a jump command is
  invoked twice at the same point
- [x] Add ERT coverage for `meow-goto-line` recording the pre-jump location
- [x] Add ERT coverage for cross-buffer jump back/forward round trips
- [x] Add ERT coverage that a new jump after `C-o` clears the forward stack
- [x] Add ERT coverage for mark-based jump helpers participating in the
  jumplist
- [x] Re-run the full existing ERT suite and batch load smoke test

## Deferred From This Stage

- [ ] Search-driven jump entries once `/`, `n`, and `N` style motions exist
- [ ] Automatic capture of arbitrary third-party navigation commands
- [ ] Window-local jumplist semantics
