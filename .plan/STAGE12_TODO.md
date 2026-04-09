# Stage 12 TODO

## Goal

Make visual-mode navigation keys extend the active selection reliably
and stop doubled line operators from showing Eerie's numeric expand
overlays.

## Scope

- [x] Fix visual `gg` and `G` so they extend the current selection in
  charwise, linewise, and blockwise visual modes
- [x] Keep visual `/`, `?`, `n`, and `N` extending the active selection
  with the fork's current charwise visual semantics
- [x] Ensure charwise visual `G` reaches the real end of buffer
- [x] Prevent `dd`, `yy`, and `cc` from creating numeric expand
  overlays

## Verification

- [x] Add ERT coverage for visual `gg` / `G` in charwise, linewise, and
  blockwise visual modes
- [x] Add ERT coverage for visual search extension
- [x] Add ERT coverage that `dd` and `yy` leave `eerie--expand-overlays`
  empty
- [x] Re-run the full existing ERT suite and batch load smoke test
