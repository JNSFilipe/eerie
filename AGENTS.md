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
- Normal mode currently supports `gg`, `G`, `$`, `gd`, `f`, `w`, `/`, `?`, `n`, `N`, `u`, `x`, `yy`, `dd`, `cc`, `p`, `i`, `I`, `a`, `A`, `C-o`, `C-i`, and `SPC`.
- Normal mode currently also supports `W` for moving to the next space on the current line, or to line end when no later space remains.
- Normal mode currently also supports `%` for matching-delimiter jumps.
- Normal `f` and `w` use a Meow-native visible-jump loop with digits `1` through `9`, and `;` reverses direction while the loop is active.
- Normal `f` should participate in the Meow jumplist so `C-o` / `C-i` round-trip through it.
- Normal `w` should leave an active charwise VISUAL selection behind with point at the end of the selected word, never assign a numbered hint to the currently selected occurrence, and still let movement keys extend it, visual `d` / `c` / `y` work on it, and `ESC` exit it cleanly.
- Normal `m` now enters the canonical multicursor session and keeps a persistent keypad-style multicursor cheat sheet visible while that session is active.
- Operator-pending currently supports doubled linewise operators, motion targets `w`, `W`, `b`, `B`, `h`, `l`, `0`, `$`, `f<char>`, and `t<char>`, plus `i`/`a` text objects for `(` `[` `{` `"` and `'`.
- Visual mode currently supports charwise, anchor-based linewise, and block selection, plus `d`, `c`, `y`, `i`, `a`, and `$`.
- Block visual `C-v` should immediately select the current character column as a one-character-wide rectangle, so flows like `C-v j d` delete a real column block instead of a zero-width no-op.
- Block visual `I` should enter INSERT at the left edge of the selected block on every selected line, and block visual `A` should append at the right edge of the selected block on every selected line.
- Visual `m` should enter the canonical multicursor session from the current charwise visual selection and use that selection as the immutable exact-match seed.
- Charwise visual selections inside the multicursor session, including selections created by normal `w`, now seed the canonical exact-match builder.
- Multicursor visual `.` adds the next exact match of the original seed text, multicursor visual `,` removes the newest target, and multicursor visual `-` skips one match without adding it.
- The canonical `m w .` path must preserve that marked target set through the real command loop, keep both matches highlighted, and let a follow-up visual `d` or `c` consume the full set.
- The canonical multicursor builder is buffer-local, exact, case-sensitive, non-overlapping, and limited to charwise seeds; older matches are rendered as secondary overlays instead of live cursors until promotion into multicursor normal.
- Plain visual `n` is visual search repeat again; it no longer promotes the old builder into multi-cursor mode.
- Multi-cursor mode now mirrors the normal keymap, and multi-cursor visual mode mirrors the visual keymap.
- Multicursor visual `v` should promote the active marked target set into multicursor normal instead of clearing the session.
- Promoted marked targets should remain highlighted through the initial multicursor-normal transition.
- While a promoted marked target set is still active in multicursor normal mode, bare `d`, `c`, `i`, and `a` should consume that full marked set instead of operating only on the primary cursor.
- Multi-cursor visual-entry and visual-retargeting commands such as `v`, `V`, `C-v`, `vi(`, and `va"` should stay in `multicursor-visual` during live command execution instead of dropping through plain `visual`.
- Multi-cursor replay should preserve selection entry and visual flows such as `v`, `V`, `C-v`, `vi(`, `va"`, and normal `f<char>1`.
- Multi-cursor replay should reuse recorded follow-up `read-key`, `read-char`, and `read-from-minibuffer` inputs when it replays supported commands across secondary cursors.
- Multi-cursor insert-like commands such as `i`, `a`, `I`, `A`, and `c` still replay the primary insert session to the secondary cursors on `ESC`.
- Direct marked-target `y` in multicursor normal still yanks only the primary active target; full multi-target yank remains deferred.
- Multi-cursor `W` should share the same next-space and line-end fallback semantics as normal `W`, but apply to every cursor in the active set.
- Normal `W` should share the same next-space and line-end fallback semantics as multi-cursor `W`, but only move the primary cursor.
- `W` should skip the immediate separator when point is sitting on the `w`-style end-of-word boundary just before that separator, so `w`-seeded multicursor spawns visibly advance on the first `W`.
- `ESC` should cancel the full multi-cursor session and return to normal mode.
- While the canonical multicursor builder is active, visual `i` enters INSERT at the beginning of every current target and visual `a` enters INSERT after every current target.
- While the canonical multicursor builder is active, visual `d` deletes all targets and visual `c` deletes all targets then replays the primary insert session to the others on `ESC`.
- Multi-edit `y` still acts only on the primary active target; full multi-target yank remains deferred.
- `ESC` should clear the full multi-cursor session, cancel the active selection, and return to normal mode.
- Unsupported commands currently still clear extra target-builder state instead of trying to preserve the session through arbitrary interactive flows.
- `V` should start linewise visual mode, immediately show numbered visible-line hints, support `;` direction reversal inside that hint loop, and keep the same anchored linewise selection behavior once a line is chosen.
- `V` should recenter the window when needed so forward or reverse line hints can expose up to 9 numbered targets before the real buffer boundary is reached.
- Visual mode currently also supports `f` as a visible character jump that extends the active selection, including selections that were started by `w`.
- Reverse visual `f` should skip the character currently under the visual cursor, so `f<char> ; 1` moves to the previous matching character instead of staying on the current one.
- Reverse visual `f` should also refresh its numbered candidates after each jump inside the same hint loop, so the visible labels and numeric choices stay aligned after `;`.
- Visual mode currently also supports `%` to extend the active selection to the matching delimiter.
- Visual `gg`, `G`, `/`, `?`, `n`, and `N` currently extend the active selection instead of dropping out of visual behavior.
- Horizontal `h` / `l` movement should clamp at line boundaries in normal and visual mode instead of wrapping across lines.
- Jump history is currently window-local and records explicit relocations such as `gg`, `G`, `gd`, `meow-goto-line`, `/?nN`, Meow's mark/global-mark jump helpers, and registered third-party navigation commands.
- Third-party jump capture ships with a default tracked-command list for built-in jumps and common `consult-*` commands, and can be extended through `meow-register-jump-command`.
- Doubled linewise operators such as `dd`, `yy`, and `cc` should not leave numeric expand overlays behind.
- Yank operators such as `yy` should preserve the original cursor position after copying.
- `%` should work for nested delimiters and when point is just after a closing delimiter at end of line or end of buffer.
- The interactive manual smoke buffer lives at `tests/meow-interactive-demo.el` and includes visible-jump targets for `f` and `w`.
- Cleanup stages 43 through 46 are complete; the dead
  `meow-visual-search-next-or-multicursor` dispatcher and the
  unreachable `meow-open-above` / `meow-open-below` command family are
  gone, while `meow-multiedit-*` and `meow-multicursor-spawn` remain as
  internal bridge helpers for the shipped multicursor flow.
- Counts, search-repeat motion targets inside operators, word text-object aliases like `iw` / `aw`, fuller Vim search syntax, bulk multi-edit builders, full multi-target yank, multi-edit text-object retargeting under a dedicated binding, linewise/blockwise multicursor match seeds, broader arbitrary interactive multi-cursor flows beyond the current mirrored normal/visual replay coverage, and full Vim-style block `c` semantics remain deferred until they exist.
