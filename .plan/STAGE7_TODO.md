# Stage 7 TODO

## Goal

Extend the Vim-style operator-pending engine so `d`, `c`, and `y`
accept motion targets in addition to doubled operators and `i`/`a`
text objects.

## Scope

- [x] Add an internal motion-target parser used by operator-pending commands
- [x] Support word/symbol motions: `w`, `W`, `b`, `B`
- [x] Support char motions: `h`, `l`
- [x] Support line-edge motions: `0`, `$`
- [x] Support character-find motions: `f<char>`, `t<char>`
- [x] Preserve existing `dd` / `yy` / `cc` and `i` / `a` behavior
- [x] Keep `change` entering insert mode and `delete`/`yank` returning to normal

## Design Constraints

- [x] Do not reuse the current visual-mode command path for operators; operator-pending builds a target selection directly
- [x] Use existing Eerie movement/selection primitives where they produce correct Vim-like target bounds
- [x] Add a small normalization layer for inclusive vs exclusive motion endpoints so `dw`, `d$`, `df<char>`, and `dt<char>` behave predictably
- [x] Keep Stage 7 free of count parsing and advanced motion grammar

## Verification

- [x] Add ERT coverage for `dw`, `cw`, `yw`
- [x] Add ERT coverage for `db`, `cb`, `yb`
- [x] Add ERT coverage for `d0`, `c0`, `y0`
- [x] Add ERT coverage for `d$`, `c$`, `y$`
- [x] Add ERT coverage for `df<char>`, `cf<char>`, `yf<char>`
- [x] Add ERT coverage for `dt<char>`, `ct<char>`, `yt<char>`
- [x] Re-run the full existing ERT suite and batch load smoke test

## Deferred From This Stage

- [ ] Counts like `2dw` and `d2w`
- [ ] Search-repeat motions and larger Vim motion grammar
- [ ] Full `iw` / `aw` / `iW` / `aW` aliases
