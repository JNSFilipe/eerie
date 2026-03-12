# Repository Instructions

## Working Rules

- Keep `README.md`, `AGENTS.md`, `.plan/PLAN.md`, and every `.plan/STAGE#_TODO.md` updated whenever behavior or stage status changes.
- Treat `README.md` as the canonical user-facing overview for this fork.
- Treat `.plan/*` as the canonical implementation tracker.
- Record deferred work explicitly in `.plan/*`; do not leave it undocumented.
- Keep `tests/meow-vim-tests.el` aligned with the shipped behavior.

## Product Direction

- This is a hard fork of Meow with Vim-style defaults.
- Keep `meow-*` file names and Lisp symbols for now unless a later task says otherwise.
- Prefer Emacs-native commands and data structures where they can support the Vim-like behavior cleanly.
- Preserve non-colliding Emacs bindings, especially in insert mode and for modified keys in normal/visual mode.

## Verification Expectations

- Add or update ERT coverage for behavior changes.
- Run `emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el -f ert-run-tests-batch-and-exit` before closing a stage.
- Run a package load smoke test with `emacs -Q --batch -L . -l meow.el`.
- Keep stage files honest about what is done, in progress, or deferred.

## Current Scope Notes

- Default bindings are active on `meow-global-mode` without a setup function.
- Normal mode currently supports `gg`, `G`, `$`, `gd`, `/`, `?`, `n`, `N`, `u`, `x`, `yy`, `dd`, `cc`, `p`, `i`, `I`, `a`, `A`, `C-o`, `C-i`, and `SPC`.
- Normal mode currently also supports `%` for matching-delimiter jumps.
- Operator-pending currently supports doubled linewise operators, motion targets `w`, `W`, `b`, `B`, `h`, `l`, `0`, `$`, `f<char>`, and `t<char>`, plus `i`/`a` text objects for `(` `[` `{` `"` and `'`.
- Visual mode currently supports charwise, anchor-based linewise, and block selection, plus `d`, `c`, `y`, `i`, `a`, and `$`.
- Visual mode currently also supports `%` to extend the active selection to the matching delimiter.
- Visual `gg`, `G`, `/`, `?`, `n`, and `N` currently extend the active selection instead of dropping out of visual behavior.
- Horizontal `h` / `l` movement should clamp at line boundaries in normal and visual mode instead of wrapping across lines.
- Jump history is currently window-local and records explicit relocations such as `gg`, `G`, `gd`, `meow-goto-line`, `/?nN`, Meow's mark/global-mark jump helpers, and registered third-party navigation commands.
- Third-party jump capture ships with a default tracked-command list and can be extended through `meow-register-jump-command`.
- Doubled linewise operators such as `dd`, `yy`, and `cc` should not leave numeric expand overlays behind.
- Yank operators such as `yy` should preserve the original cursor position after copying.
- `%` should work for nested delimiters and when point is just after a closing delimiter at end of line or end of buffer.
- The interactive manual smoke buffer lives at `tests/meow-interactive-demo.el`.
- Counts, search-repeat motion targets inside operators, word text-object aliases like `iw` / `aw`, and fuller Vim search syntax remain deferred until they exist.
