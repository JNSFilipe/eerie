# Vim-Style Meow Fork Plan

## Goal
Turn this Meow fork into a Vim-first modal editing package with:
- Vim-style normal, visual, and insert behavior
- Built-in opinionated defaults
- Emacs-native editing and jump primitives where practical
- Living documentation and stage tracking inside this repository

## Stage Overview
1. Planning, docs, and verification scaffold
2. Dedicated visual state and state-machine split
3. Opinionated Vim-style defaults and normal-mode bindings
4. Operator-pending core and text objects
5. Visual char/line/block behavior and visual actions
6. Documentation sync, regression fixes, and release polish
7. Motion-based operators and motion target parser
8. Jump history expansion and jumplist policy
9. Search jumps, third-party capture, and window-local jumplists
10. Undo binding, visual regressions, and manual smoke buffer
11. Linewise visual anchor fixes
12. Visual navigation extension and operator overlay cleanup
13. Matching-delimiter jump and yank cursor preservation
14. Matching-delimiter reliability fixes
15. Horizontal movement clamping and line-end motion
16. Meow-native visible jumps for `f` and `w`
17. `w` visual-selection polish and `f` jumplist verification
18. `w` cursor placement polish
19. `w` reverse-hint exclusion fix
20. Visual `f` selection extension
21. Visual `f` reverse-cursor exclusion fix
22. Visual `f` same-loop reverse refresh fix
23. Visible line hints for `V`
24. `V` recentering for full 9 line hints
25. Multi-edit session core
26. Multi-edit occurrence builder with `m`, `;`, and `s`
27. Multi-edit target management
28. Multi-edit delete/change execution
29. Multi-edit insert/append entry semantics
30. Multi-cursor spawn from multi-edit
31. Shared `W` next-space motion
32. `W` line-end fallback
33. Multi-cursor normal and visual parity
34. Live multi-cursor visual-state retention
35. `W` boundary advance after `w`-seeded spawn
36. Dedicated multicursor-mark entry and persistent menu
37. Match builder remap to `.`, `,`, and `-`
38. Canonical multicursor action flow and mirrored mode execution
39. Multicursor redesign cleanup and documentation sync
40. Visual `m` entry into canonical multicursor mode
41. Block-visual rectangle initialization fix
42. Block-visual `I` and `A` replay insert/append

## Update Policy
- Keep this file, every `.plan/STAGE#_TODO.md`, `README.md`, and `AGENTS.md` in sync with the current implementation.
- Update the active stage file before starting work on that stage and before closing it.
- Record any intentionally deferred work in the relevant stage file instead of leaving it implicit.

## Current Status
- Active stage: Complete
- Verification:
  - package load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes
- Deferred items:
  - bulk multi-edit builders such as add-all and edit-lines
  - multi-edit yank across all targets
  - linewise and blockwise multicursor match seeds
  - broader arbitrary interactive multicursor flows beyond the mirrored normal/visual command set
  - full Vim-style block `c` semantics
  - rewriting the legacy upstream `.org` docs
  - operator counts and additional Vim motions beyond the Stage 7 scope
  - search motions as operator targets
  - full Vim search options such as `*`, `#`, and search offset syntax
  - cross-session persistence of jump history
  - old internal compatibility helpers such as `meow-multiedit-*`,
    `meow-multicursor-spawn`, and `meow-visual-search-next-or-multicursor`
    still exist, but normal `m` plus multicursor `.` / `,` / `-` is now the canonical user-facing flow
## Stage 36 Summary
- Goal: replace the old visual-only entry point with a canonical normal `m` multicursor session and keep a persistent multicursor cheat sheet visible while that session is active.
- Implemented scope:
  - bound normal `m` to `meow-multicursor-start`
  - reused the existing multicursor normal and visual states as the canonical user-facing mode
  - added a persistent keypad-style multicursor help popup that refreshes while the session is active and clears on exit
  - kept `ESC` as a full session cancel back to normal
- Verification:
  - batch load smoke test passes
  - ERT suite passes with coverage for normal `m` entry, menu display, and `ESC` teardown

## Stage 37 Summary
- Goal: replace the old visual multi-edit builder keys with the new canonical `.`, `,`, and `-` flow inside multicursor visual mode.
- Implemented scope:
  - bound multicursor visual `.` to add the next exact match of the current seed, `,` to remove the newest target, and `-` to skip the next exact match
  - kept the seed immutable, exact, case-sensitive, current-buffer, and charwise
  - removed the old visual `m`, `;`, `s`, and visual `n` builder path from the shipped keymaps
  - restored plain visual `n` to plain visual search repeat
- Verification:
  - batch load smoke test passes
  - ERT suite passes with coverage for the new `.` / `,` / `-` flow from normal `m`

## Stage 38 Summary
- Goal: make the normal `m` flow hand off cleanly into mirrored multicursor normal replay so broader Vim-style actions work without a second explicit spawn key.
- Implemented scope:
  - added multicursor visual `v` as a dedicated exit command that promotes the active marked target set into multicursor normal instead of clearing it
  - kept mirrored normal and visual replay available after that promotion for flows like `vi(` and visible `f<char>1`
  - preserved the replay-backed insert and change path for `i`, `a`, `I`, `A`, and `c`
- Verification:
  - batch load smoke test passes
  - ERT suite passes with coverage for multicursor visual `v` promotion and new-flow `vi(`

## Stage 39 Summary
- Goal: sync the living docs, interactive demo, and stage trackers to the shipped multicursor redesign.
- Implemented scope:
  - updated README, AGENTS, and the stage tracker to describe normal `m`, multicursor `.` / `,` / `-`, and multicursor visual `v`
  - documented that promoted marked targets stay highlighted in multicursor normal long enough for direct `d` / `c` / `i` / `a` to consume the whole marked set
  - fixed the canonical `m w .` regression so the marked target set survives the real command-loop path instead of only direct helper calls
  - updated the interactive demo buffer for the new flow
  - added regression coverage for the new entry, promotion, direct normal-mode marked-target edits, real `m w .` builder execution, and exit behavior
- Verification:
  - batch load smoke test passes
  - full ERT suite passes

## Stage 40 Summary
- Goal: let plain visual selections enter the canonical multicursor session directly with `m`, using the current selection as the exact-match seed.
- Implemented scope:
  - bound visual `m` to a dedicated multicursor entry command instead of leaving visual mode without a direct handoff
  - preserved the current charwise visual selection while switching into `multicursor-visual`, then seeded the canonical exact-match builder from that restored selection
  - kept the new visual-entry command alive across the multicursor and multiedit post-command cleanup hooks so the seeded session survives the command boundary
  - added regression coverage for direct visual `m` entry and the real `m.` key sequence from visual mode
- Verification:
  - batch load smoke test passes
  - full ERT suite passes

## Stage 41 Summary
- Goal: make Vim-style block visual mode start with a real one-character-wide rectangle so direct block actions work from `C-v` without a dummy horizontal move.
- Implemented scope:
  - changed `meow-visual-block-start` so a fresh `C-v` selection marks the current character column instead of a zero-width rectangle
  - kept blockwise vertical movement column-stable while updating the initial rectangle width to match the visible cursor column
  - added regressions for the initial rectangle contents, the shifted mark column, and a real `C-v j d` key sequence that must delete the selected column block
- Verification:
  - batch load smoke test passes
  - full ERT suite passes

## Stage 42 Summary
- Goal: make block visual `I` and `A` work like Vim-style multi-line insert and append instead of being undefined keys.
- Implemented scope:
  - bound visual `I` and `A` and made them dispatch to block-specific replay-backed insert and append commands
  - extended the replay engine so block insert sessions can target a column on each selected line, not just a raw marker position
  - added real `C-v j I ... ESC` and `C-v j A ... ESC` regression coverage
- Verification:
  - batch load smoke test passes
  - full ERT suite passes

## Stage 29 Summary
- Goal: make multi-edit `i` and `a` follow Vim-style insert and append semantics instead of reusing visual text-object retargeting.
- Implemented scope:
  - made multi-edit visual `i` enter INSERT at the beginning of every selected target
  - made multi-edit visual `a` enter INSERT after every selected target
  - reused the same replay path as multi-edit `c`, but switched it to exact insertion positions so append does not drift by one character
  - kept plain visual `i` and `a` working as inner and around text-object selectors when multi-edit is not active
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for multi-edit insert and append replay

## Stage 30 Summary
- Goal: let an active multi-edit target set promote into a normal-like multi-cursor state so broader Vim-style actions can run across all selected matches.
- Implemented scope:
  - added visual `n` as a multi-edit-aware dispatcher that promotes the current multi-edit target set into a dedicated multi-cursor state, while still falling back to normal visual search repeat when multi-edit is inactive
  - added a dedicated `multicursor` Meow state with its own keymap, indicator name, and `ESC` cancellation path
  - reused Meow fake-cursor overlays for secondary cursors and replayed deterministic normal-mode key sequences across them from the primary cursor
  - added dedicated multi-cursor `f` and `W` motions so line-local character finding and next-space movement work across all cursors without depending on the generic key replay path
  - wired insert-like commands such as `i`, `a`, `I`, `A`, and `c` into the existing replay-backed insert machinery so the primary insert session is replayed to the secondary cursors on `ESC`
  - cleaned up multi-edit and multi-cursor state during mode shutdown so temporary overlays and hooks are not left behind
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for visual `n` promotion, normal-mode replay, multi-cursor `f`, multi-cursor `W`, insert replay, and `ESC` cancellation

## Stage 31 Summary
- Goal: make `W` a first-class normal-mode motion and align its semantics with the dedicated multi-cursor `W` motion.
- Implemented scope:
  - added normal-mode `W` as a next-space motion on the current line
  - refactored the line-local next-space behavior into a shared helper so normal `W` and multi-cursor `W` follow the same first-jump and repeat semantics
  - kept multi-cursor `W` as a dedicated multicursor-native command while exposing the same motion in regular normal mode
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for normal `W` and multi-cursor `W`

## Stage 32 Summary
- Goal: make `W` fall back to the end of the current line when no later spaces remain.
- Implemented scope:
  - changed the shared next-space helper so both normal `W` and multi-cursor `W` move to `line-end-position` when no later space is available on that line
  - kept repeated `W` advancing through later spaces first, then falling back to line end once the final word is reached
  - updated the manual smoke notes and docs so the line-end fallback is part of the documented behavior
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for normal `W` line-end fallback and multi-cursor `W` line-end fallback

## Stage 33 Summary
- Goal: make multi-cursor normal mode mirror the normal and visual command set closely enough for selection entry and nested-input commands like `f<char>1` and `vi(`.
- Implemented scope:
  - replaced the old dedicated multi-cursor `f` / `W` override model with mirrored multi-cursor normal and visual states that inherit the regular normal and visual keymaps
  - added a per-cursor snapshot model so secondary cursors can preserve their own normal or visual state, active region, and visual metadata across replayed commands
  - extended multi-cursor replay to capture nested `read-key`, `read-char`, and `read-from-minibuffer` inputs and reuse them across secondary cursors for supported commands
  - added explicit replay support for normal visible `f<char>…` jumps and visual text-object selection commands such as `vi(` and `va"`
  - fixed multi-cursor visual actions so finishing a visual command returns to multi-cursor normal instead of dropping out of the multi-cursor state
  - kept replay-backed insert handoff working by fully disabling the multi-cursor command-capture hooks before entering insert replay
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for multi-cursor visual entry, nested-input `f<char>1`, `vi(`, normal replay, insert replay, and state restoration

## Stage 34 Summary
- Goal: keep real multi-cursor visual-entry and visual-retargeting commands in the multi-cursor visual state so live keypress flows do not silently fall back to the primary cursor only.
- Implemented scope:
  - added a shared visual-target helper so visual-entry commands such as `v`, `V`, `C-v`, visible `w`, and visual text-object retargeting commands choose `multicursor-visual` whenever a multi-cursor session is active
  - fixed the specific live-command bug where commands like `vi(` switched through plain `visual`, which triggered the multi-cursor visual teardown path and cleared the primary selection before replay
  - converted the multicursor regression coverage for `v` and `vi(` to real key-sequence tests so the suite exercises the actual command-loop replay path instead of only the helper path
  - hardened the test harness around unread events and keyboard-macro state so command-loop state from one test does not leak into later tests
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with live key-sequence coverage for multi-cursor `v`, `vi(`, and nested-input `f<char>1`

## Stage 35 Summary
- Goal: make `W` advance correctly when a normal or multicursor cursor is sitting on the `w`-style end-of-word boundary immediately before a space.
- Implemented scope:
  - changed the shared `W` motion helper so a non-repeated `W` skips the immediate separator when point is already on the end-of-word boundary before that separator
  - kept repeated `W` behavior and the existing line-end fallback intact
  - added regression coverage for the normal boundary case and for the `w -> m -> n -> W` multicursor path
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for normal `W`, multicursor `W`, and the `w`-seeded spawn boundary case

## Stage 28 Summary
- Goal: make the first destructive multi-edit commands actually operate across the whole target set instead of only the active visual region.
- Implemented scope:
  - made multi-edit visual `d` delete every selected target in one command while leaving point at the primary target start
  - added replay-backed multi-edit visual `c` so all selected targets are deleted and the primary insert session is replayed to the other targets on `ESC`
  - kept the replay path Meow-owned, with a direct text insertion fallback when no keyboard macro was recorded
  - preserved the existing charwise visual workflow by clearing the multi-edit session once the action completes
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for multi-edit delete and replay-backed change

## Stage 27 Summary
- Goal: make the multi-edit target set manageable before destructive actions.
- Implemented scope:
  - added visual `,` to remove the most recently added multi-edit target and restore the previous primary target
  - kept target ordering and overlap handling predictable so later actions apply to a stable target set
  - kept the existing immutable seed text for later `m` / `s` matching
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `,`

## Stage 26 Summary
- Goal: add the first user-facing multi-edit builder so a charwise visual selection can grow into a set of exact-match targets with `m`, `;`, and `s`.
- Implemented scope:
  - added visual `m` to start or extend a buffer-local multi-edit session from the current charwise visual selection
  - froze the original seed text when the session starts and used it for exact, case-sensitive, non-overlapping current-buffer matching
  - made repeated `m` add the next unselected match in the active direction and move the primary visual selection to that newest target
  - added visual `;` to reverse the multi-edit builder direction persistently for later `m` and `s`
  - added visual `s` to skip one unselected match in the current direction without adding it to the session
  - prevented duplicate and overlapping targets and kept previously added matches visible through Meow selection overlays
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for forward growth, repeated forward growth, reverse growth, skip behavior, and `w`-started seeds

## Stage 25 Summary
- Goal: introduce a first-class multi-edit session lifecycle that integrates with the existing visual workflow without yet implementing full multi-target editing.
- Implemented scope:
  - added buffer-local multi-edit session state for the immutable seed text, active direction, primary target, secondary targets, and search head
  - added secondary-target overlay rendering using Meow's existing fake-selection face so extra matches stay visible without creating live cursors
  - restricted v1 multi-edit startup to active charwise visual selections, including selections created by normal `w`
  - made `ESC` clear the full multi-edit session, remove overlays, cancel the active selection, and return to normal mode
  - added a post-command guard that clears extra multi-edit targets when unsupported commands leave the builder flow, instead of carrying stale session state through arbitrary visual commands
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for visual-exit cleanup and charwise session startup

## Stage 16 Summary
- Goal: replace the useful visible-jump parts of the user-provided `avy.el` with Meow-native commands so the fork no longer needs that file for `f` and `w`.
- Implemented scope:
  - added a Meow-owned visible jump loop that scans only the current window's visible text
  - added normal-mode `f` as a numbered visible-char jump using digits `1` through `9`
  - added normal-mode `w` as a numbered visible word-occurrence jump that selects the current word and each jumped-to occurrence
  - added `;` as an in-loop direction toggle for both commands
  - reused Meow's overlay infrastructure and jump-history helpers instead of depending on `avy.el` at runtime
  - removed the default jumplist references to external `avy-*` commands from the shipped defaults and docs
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `f`, `w`, numeric hint selection, `;` direction reversal, and overlay cleanup

## Stage 17 Summary
- Goal: make `w` behave like a real active selection after jumping, add `ESC` exit behavior, and lock down `f` jumplist behavior with regression coverage.
- Implemented scope:
  - changed `w` to promote its current-word and occurrence targets into Meow's charwise VISUAL state instead of leaving a normal-state visit selection behind
  - kept `w` compatible with movement extension and visual `d` / `c` / `y` actions by reusing the visual-state selection machinery
  - made `ESC` inside the visible-jump loop exit the `w` selection cleanly instead of leaving visual state active
  - fixed visible-jump control-key handling so `ESC` and `C-g` are recognized reliably
  - added explicit ERT coverage that `f` participates in `C-o` / `C-i` jumplist round trips
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `w` entering visual mode, `ESC` exit, visual movement and delete after `w`, and `f` jumplist round trips

## Stage 18 Summary
- Goal: keep the `w` selection behavior from Stage 17, but place point at the end of the selected word instead of the beginning.
- Implemented scope:
  - flipped the final `w` selection activation so the selected word range stays unchanged while point lands on the word end
  - kept `w` in charwise VISUAL state with the same `ESC`, movement, and action behavior from Stage 17
  - updated regression coverage to assert both the selected word bounds and the new point location
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for the `w` selection bounds and end-of-word point placement

## Stage 19 Summary
- Goal: make sure the currently selected `w` occurrence is never assigned a numbered hint, especially after `;` reverses direction.
- Implemented scope:
  - taught the visible regex candidate collector to exclude an exact active range when requested
  - updated `w` to exclude the currently selected occurrence from its numbered hints on every jump-loop pass
  - fixed the `w ; 1` case so it targets the previous visible occurrence instead of staying on the current word
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `w ; 1` skipping the current word

## Stage 20 Summary
- Goal: make `f` extend an active visual selection, including selections that were started by `w`.
- Implemented scope:
  - added a dedicated visual-state `f` command that reuses the numbered visible-char jump loop
  - made visual `f` extend the current selection to include the chosen target character instead of replacing the selection
  - bound `f` in the visual-state keymap so `w`-started selections can continue extending with visible-char jumps
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for visual `f` on a plain visual selection and on a `w`-started selection

## Stage 21 Summary
- Goal: make reverse visual `f` skip the character currently under the visual cursor, matching the normal-mode behavior.
- Implemented scope:
  - added a helper that identifies the actual visible cursor character in an active visual selection
  - taught visual `f` to exclude that current cursor character from its numbered candidates
  - fixed `v`-started and `w`-started selections so `f<char> ; 1` targets the previous matching character instead of staying on the current one
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for reverse visual `f` on both plain visual and `w`-started selections

## Stage 22 Summary
- Goal: make reverse visual `f` refresh its numbered candidates correctly after each jump within the same hint loop.
- Implemented scope:
  - changed visual `f` to recompute its current-cursor exclusion range on every jump-loop pass instead of capturing it once at command start
  - fixed the stale-numbering case where `f<char> ; 1` showed updated overlays but still required the old numeric choice
  - kept the fix working for both plain visual selections and selections started by `w`
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for same-loop reverse visual `f` on both plain visual and `w`-started selections

## Stage 23 Summary
- Goal: make `V` show an avy-style visible line jump UI without losing the existing anchored linewise visual behavior.
- Implemented scope:
  - kept the plain linewise visual entry path as an internal helper and layered the visible-jump loop on top for interactive `V`
  - added visible visual-line candidates so `V` can number nearby lines, jump to them with digits `1` through `9`, and reverse direction with `;`
  - kept the current line out of the numbered candidates and let `ESC` inside the hint loop exit the linewise visual selection cleanly
  - preserved the anchor-based linewise selection model after each chosen line so normal linewise visual movement and actions still work
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `V` line jumps, reverse direction updates, and `ESC` exit

## Stage 24 Summary
- Goal: keep `V` showing a full 9 line hints when the buffer still has more lines in the active direction but the current window does not.
- Implemented scope:
  - taught the line-hint collector to detect when it ran out of visible forward or backward lines before the real buffer boundary
  - recentered the window on demand for `V` line hints so forward jumps can expose more lines below and reverse jumps can expose more lines above
  - kept the old behavior at real buffer boundaries and when the window is simply too short to display 9 targets
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with dedicated short-window coverage for forward and reverse `V` line hints filling out 9 targets when the buffer still has more lines

## Stage 10 Summary
- Goal: close the first round of user-reported regressions after the Stage 9 feature work and add a manual smoke-test buffer.
- Implemented scope:
  - bound normal-mode `u` to `meow-undo`
  - switched `meow-undo` and `meow-undo-in-selection` to Emacs-native undo commands instead of keyboard macros
  - fixed linewise visual startup so `V` selects the current line instead of collapsing to an empty range at buffer edges
  - fixed blockwise vertical movement so `C-v` followed by `j` / `k` preserves the active column instead of snapping to column 0
  - added an interactive demo file under `tests/meow-interactive-demo.el`
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `u`, linewise visual startup, and blockwise column preservation

## Stage 11 Summary
- Goal: fix the remaining linewise visual regressions reported after Stage 10.
- Implemented scope:
  - replaced the direction-sensitive `V` movement path with an anchor-based linewise selection model
  - ensured `V` always starts on exactly the current line
  - ensured `V j k` and `V k j` return to the original anchor line instead of collapsing or inverting
  - kept blockwise `C-v` vertical movement column-stable from Stage 10
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with dedicated coverage for linewise anchor preservation and `j` / `k` directionality

## Stage 12 Summary
- Goal: make the shipped visual-navigation keys actually extend the active selection and remove spurious expand overlays from doubled line operators.
- Implemented scope:
  - fixed visual `gg` and `G` so they extend charwise, linewise, and blockwise selections instead of leaving linewise visual anchored on the old line
  - kept visual `/`, `?`, `n`, and `N` extending the active selection and aligned their tests with the current charwise visual semantics
  - made charwise visual `G` target `point-max` so end-of-buffer extension reaches the real buffer end
  - prevented `dd`, `yy`, and `cc` linewise operator forms from triggering Meow's numeric expand overlays
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for visual `gg` / `G`, visual search extension, and no-overlay `dd` / `yy`

## Stage 13 Summary
- Goal: close two more Vim-parity regressions by keeping yank cursor position stable and adding `%` matching-delimiter jumps.
- Implemented scope:
  - restored the original cursor position after Vim-style yank operators such as `yy`, `yw`, and `ya"`
  - added `%` in normal mode to jump between matching `(`/`)`, `[`/`]`, `{`/`}`, `"` and `'`
  - added `%` in visual mode to extend the active selection to the matching delimiter
  - reused the fork's existing Vim text-object delimiter mapping so `%` stays aligned with `i` / `a` text objects
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for `yy` cursor preservation, normal `%`, and visual `%`

## Stage 14 Summary
- Goal: make `%` reliable across nested delimiters and common end-of-line / end-of-buffer cursor positions.
- Implemented scope:
  - replaced the fragile opener lookup that depended on recovering text-object bounds from the next character
  - switched paren-like `%` matching to delimiter-aware `scan-sexps` logic so nested `(` `[` and `{` work consistently
  - kept quote matching on the existing text-object bounds path
  - taught `%` to treat a closing delimiter before newline or at `point-max` as the current target when point sits after the visible delimiter
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for nested openers plus end-of-line and end-of-buffer `%` jumps

## Stage 15 Summary
- Goal: stop horizontal motions from wrapping across lines and add `$` as a real line-end motion in normal and visual mode.
- Implemented scope:
  - made normal `h` and `l` clamp at line boundaries instead of crossing to the previous or next line
  - made visual `h` and `l` clamp at line boundaries for charwise and blockwise visual movement
  - added normal `$` to move to the end of the current line
  - added visual `$` to extend the active visual selection to the end of the current line
- Verification:
  - batch load smoke test passes
  - ERT suite in `tests/meow-vim-tests.el` passes with coverage for clamped `h` / `l`, normal `$`, and visual `$`

## Stage 9 Summary
- Goal: finish the remaining jumplist gaps by making jump history window-local, adding Vim-style search jumps, and automatically capturing registered third-party navigation commands.
- Implemented scope:
  - moved jump back and forward stacks to per-window storage while preserving `C-o` / `C-i`
  - added `/`, `?`, `n`, and `N` style search commands backed by Emacs regex search primitives and Meow's search ring
  - added automatic jump recording for registered non-Meow navigation commands through command advice and a public `meow-register-jump-command` helper
  - shipped a default tracked-command list for core Emacs jump commands and common third-party navigation packages
- Explicitly out of Stage 9:
  - search motions as operator targets
  - full Vim search options such as `*`, `#`, and search offset syntax
  - cross-session persistence of jump history

## Stage 8 Summary
- Goal: broaden `C-o` / `C-i` coverage beyond the initial hardcoded buffer and definition jumps while keeping the jumplist predictable.
- Implemented scope:
  - introduced a reusable jump-recording helper that only records successful relocations
  - extended jump recording to `meow-goto-line`, `meow-goto-buffer-start`, `meow-goto-buffer-end`, and `meow-goto-definition`
  - extended jump recording to `meow-pop-to-mark`, `meow-unpop-to-mark`, and `meow-pop-to-global-mark`
  - preserved duplicate suppression, dead-marker pruning, cross-buffer round trips, and forward-stack clearing on new jumps
  - kept ordinary motions and operator targets out of jump history
- Explicitly out of Stage 8:
  - search-driven jump entries until `/`, `n`, and `N` style motions exist in the fork
  - automatic capture of arbitrary third-party navigation commands outside Meow-owned wrappers
  - window-local jumplist semantics

## Stage 7 Summary
- Goal: extend the operator-pending engine so `d`, `c`, and `y` can consume motion targets instead of only doubled operators and `i`/`a` text objects.
- Implemented scope:
  - `dw`, `cw`, `yw`
  - `dW`, `cW`, `yW`
  - `db`, `cb`, `yb`
  - `dB`, `cB`, `yB`
  - `dh`, `dl`, `ch`, `cl`, `yh`, `yl`
  - `d0`, `c0`, `y0`
  - `d$`, `c$`, `y$`
  - `df<char>`, `cf<char>`, `yf<char>`
  - `dt<char>`, `ct<char>`, `yt<char>`
- Explicitly out of Stage 7:
  - `2dw` / `d2w` style counts
  - search-based motions like `dn`, `dN`
  - sentence/paragraph/function motions
  - full text-object aliases like `iw` and `aw`
