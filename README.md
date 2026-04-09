# Eerie

<p align="center">
  <img src="eerie.png" alt="Eerie logo" width="420">
</p>

Eerie is a hard fork of [Meow](https://github.com/meow-edit/meow) and
ships a Vim-style modal experience by default under the `eerie-*` Lisp
surface.

## Installation

On Emacs 30+, `use-package` can install Eerie directly through the
built-in `:vc` support:

```emacs-lisp
(use-package eerie
  :vc (:url "https://github.com/JNSFilipe/eerie.git"
       :rev :newest)
  :config
  (eerie-global-mode 1))
```

## Quick Start

```emacs-lisp
(require 'eerie)
(eerie-global-mode 1)
```

No setup function is required for the default layout.

## Implemented Defaults

### Normal mode

- `h j k l` move
- `h` and `l` stay on the current line instead of wrapping across lines
- `g g` jumps to the start of the buffer
- `G` jumps to the end of the buffer
- `$` jumps to the end of the current line
- `g d` uses `xref` to jump to definition
- `%` jumps to the matching delimiter for `(`/`)`, `[`/`]`, `{`/`}`, `"` and `'`
- `x` deletes the current character
- `f` jumps to a visible character with numbered hints; press `;` during the hint loop to reverse direction, and `C-o` / `C-i` can jump back and forward through it
- `W` moves to the next space on the current line, or to line end when no later space remains
- `u` undoes with Emacs's native undo command
- `w` selects the current word and jumps between its visible occurrences with numbered hints; when you stop jumping, the result stays in charwise visual selection with point at the word end so movement keys, `d`, `c`, and `y` work on it
- `m` enters the canonical multicursor session and keeps a persistent multicursor help popup visible until you leave it
- `y y`, `d d`, and `c c` are linewise operator forms
- motion-based operators support `w`, `W`, `b`, `B`, `h`, `l`, `0`, `$`, `f<char>`, and `t<char>`
- `/` and `?` search forward and backward with Emacs regexes
- `n` and `N` repeat the last search in the same or opposite direction
- `d i …`, `d a …`, `c i …`, `c a …`, `y i …`, and `y a …` work for `(` `[` `{` `"` and `'`
- `p` pastes
- `i`, `I`, `a`, and `A` enter insert mode at Vim-like positions
- `C-o` and `C-i` move backward and forward through the fork's window-local jumplist
- `SPC` opens the leader/keypad menu

### Visual mode

- `v` starts charwise visual mode
- `V` starts linewise visual mode anchored on the current line and shows numbered visible-line hints; `;` reverses direction during the hint loop
- Linewise visual `V` follows logical buffer lines even when display wrapping is active, so repeated line hints advance by real lines instead of wrapped screen rows
- `C-v` starts block selection with `rectangle-mark-mode` and immediately selects the current character column so block actions like `C-v j d` operate on a real rectangle instead of a zero-width region
- In block visual mode, `I` enters insert at the left edge of the selected block on every selected line, and `A` appends at the right edge of the selected block on every selected line
- `h` and `l` stay on the current line while extending the selection
- `f` extends the active visual selection to a visible character with numbered hints; `;` reverses direction during the hint loop
- `g g`, `G`, `/`, `?`, `n`, and `N` keep extending the active visual selection
- `$` extends the active visual selection to the end of the current line
- `%` extends the active visual selection to the matching delimiter
- `d`, `c`, and `y` operate on the active visual selection
- `i` and `a` retarget the visual selection to inner/around text objects
- `m` enters the canonical multicursor session from the current charwise visual selection and uses that selection as the frozen exact-match seed
- `ESC` exits visual mode

### Multi-cursor mode

- Normal `m` starts the canonical multicursor session and shows a persistent keypad-style cheat sheet while the session is active
- Visual `m` starts that same canonical multicursor session from the current charwise visual selection instead of making you restart from normal mode
- Inside multicursor visual mode, the first charwise selection becomes the immutable exact-match seed for the builder
- Multicursor visual `.` adds the next exact match of that seed
- Multicursor visual `,` removes the newest marked match
- Multicursor visual `-` skips the next exact match without adding it
- The same builder state survives the real `m w .` key sequence, so `w` can seed the builder, both matches stay highlighted, and a follow-up `d` or `c` still acts on the full marked set
- Multicursor visual `v` promotes the current marked target set into multicursor normal mode instead of clearing the session
- After that promotion, the marked targets stay highlighted until you consume them with a direct marked-target edit or replace them with another multicursor action
- Multi-cursor normal mode inherits the normal keymap and applies the same deterministic command flow across all secondary cursors
- While those marked targets are still active in multicursor normal mode, bare `d`, `c`, `i`, and `a` consume the whole marked set instead of falling back to operator-pending on only the primary cursor
- Multi-cursor visual mode inherits the visual keymap, so selections and visual actions can keep extending and acting across the full cursor set
- Commands that enter or retarget visual selections now stay in the multi-cursor visual state, so live keypress flows such as `v`, `V`, `C-v`, `vi(`, and `va"` keep applying across the whole cursor set instead of dropping back to the primary cursor
- Nested-input commands such as normal `f<char>1`, `d i (`, `c a "`, and visual `v i (` reuse the same recorded follow-up inputs across all cursors
- `W` keeps the same next-space and line-end fallback semantics as normal mode, but applies to every cursor
- When a normal or multicursor cursor is sitting on the `w`-style end-of-word boundary just before a space, `W` now skips that immediate separator and advances to the following space or line end instead of appearing stuck
- Insert-like commands such as `i`, `a`, `I`, `A`, and `c` replay the primary insert session to the secondary cursors when you press `ESC`
- `ESC` cancels the full multi-cursor session and returns to normal mode

### Insert mode

- Insert mode keeps standard Emacs bindings
- `ESC` returns to normal mode

## Customization Helpers

- `eerie-normal-define-key`
- `eerie-visual-define-key`
- `eerie-leader-define-key`
- `eerie-register-jump-command`

## Notes

- Operator-pending currently covers doubled linewise operators, motion targets `w`/`W`/`b`/`B`/`h`/`l`/`0`/`$`/`f`/`t`, and the requested `i`/`a` text objects.
- Doubled linewise operators like `dd`, `yy`, and `cc` do not trigger Eerie's numeric expand hints.
- Vim-style yank operators restore the original cursor position after copying.
- `%` handles nested delimiters and still works when point is sitting after a closing delimiter at end of line or end of buffer.
- `f` and `w` use an Eerie-native visible-jump loop with digits `1` through `9`; no external `avy.el` runtime dependency is required.
- `w` now promotes its target into Eerie's actual visual state, keeps point at the end of the selected word, never numbers the current occurrence as a jump target, and lets `ESC` and visual movement/action keys keep working normally.
- Because `w` ends in real visual state, visual `f` can keep extending that selection instead of replacing it.
- Charwise selections created inside multicursor mode, including selections created by `w`, become exact, case-sensitive, current-buffer match seeds for the multicursor builder.
- Multicursor visual `.` / `,` / `-` replace the old visual `m` / `;` / `s` builder flow.
- The marked target set still uses the original selected text as an immutable seed, matches non-overlapping current-buffer occurrences, and stays highlighted through the initial multicursor-normal promotion with `v`.
- Multicursor visual `d` deletes all current targets, and multicursor visual `c` deletes all current targets then replays the primary insert session to the rest on `ESC`.
- Multicursor visual `i` enters INSERT at the beginning of every current target, and multicursor visual `a` enters INSERT after every current target.
- In multicursor normal mode, direct marked-target `y` still yanks only the primary active target; full multi-target yank is still deferred.
- Multi-edit `y` still yanks only the primary active target; full multi-target yank is still deferred.
- Multi-edit text-object retargeting is deferred until it gets a dedicated binding that does not conflict with Vim-style insert/append.
- Plain visual `n` is back to plain visual search repeat.
- Multi-cursor mode now mirrors the normal and visual keymaps, including selection entry and visual text-object flows like `vi(`.
- Multi-cursor commands that switch into visual-like behavior now stay in the multi-cursor visual state instead of temporarily falling back to plain visual mode, so destructive follow-up keys still apply across every active cursor.
- Multi-cursor replay records nested `read-key`, `read-char`, and `read-from-minibuffer` inputs so follow-up prompts can be replayed across secondary cursors for supported commands.
- Multi-cursor replay still focuses on deterministic command flows; broader arbitrary interactive sessions beyond the covered normal/visual command set may still need follow-up work.
- Normal `W` shares the same next-space and line-end fallback semantics as multi-cursor `W`, but applies only to the primary cursor.
- `W` now also skips the immediate separator when point comes from a `w`-style end-of-word boundary, so `w -> m -> n -> W` visibly advances instead of looking inert.
- `V` reuses the same visible-jump loop for lines, so digits jump the active linewise selection to visible lines, `;` reverses direction, and `ESC` exits the selection.
- When `V` has fewer than 9 visible line hints in the active direction but the buffer still has more lines there, it recenters the window to expose up to 9 numbered line targets.
- `C-v` now starts from a one-character-wide rectangle at point, so blockwise `d` and `c` act on the visible column immediately instead of needing an extra horizontal motion first.
- Block visual `I` and `A` replay the primary insert session to every selected line at the rectangle's left or right edge.
- Reverse visual `f` skips the character currently under the visual cursor, so `f<char> ; 1` goes to the previous match instead of staying on the current one.
- Reverse visual `f` also refreshes its numbered candidates after each jump inside the same hint loop, so the overlay labels and numeric choices stay in sync after `;`.
- Jump history is window-local and records explicit relocations such as `gg`, `G`, `gd`, `eerie-goto-line`, `/?nN`, Eerie's mark/global-mark jump helpers, and registered third-party navigation commands.
- Registered command capture ships with a default list for built-in jumps like `beginning-of-buffer`, `end-of-buffer`, `goto-line`, `imenu`, and `xref`, plus common third-party commands such as `consult-*` when those symbols are present.
- Counts like `2dw`, search-repeat operator targets, and word text-object aliases like `iw` / `aw` are still deferred.
- Block `c` still uses Emacs rectangle deletion and then enters insert mode at point; it is not full Vim-style block-change semantics yet.
- The living implementation tracker is in `.plan/PLAN.md`.
- `tests/eerie-interactive-demo.el` is the manual smoke buffer for interactive testing, including `f`, `w`, and the normal-`m` multicursor flow.
