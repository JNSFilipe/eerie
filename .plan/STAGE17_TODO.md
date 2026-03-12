# Stage 17 TODO

## Goal

Make `w` behave like a real active selection after visible jumping, make
`ESC` exit that selection cleanly, and verify that `f` round-trips through
the jumplist.

## Scope

- [x] Promote `w` selections into Meow's charwise VISUAL state
- [x] Keep `w` compatible with visual movement extension
- [x] Keep `w` compatible with visual `d` / `c` / `y` actions
- [x] Make `ESC` exit the `w` selection cleanly
- [x] Fix visible-jump loop handling for raw control-key input
- [x] Add regression coverage for `f` jumplist round trips

## Verification

- [x] Add ERT coverage for `w` entering visual mode
- [x] Add ERT coverage for movement after `w`
- [x] Add ERT coverage for delete after `w`
- [x] Add ERT coverage for `ESC` exiting the `w` selection
- [x] Add ERT coverage for `f` working with `C-o` / `C-i`
- [x] Re-run the full existing ERT suite and batch load smoke test
