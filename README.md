# Meow Vim Fork

This repository is a hard fork of Meow that ships a Vim-style modal
experience by default while keeping the existing `meow-*` Lisp surface for now.

## Quick Start

```emacs-lisp
(require 'meow)
(meow-global-mode 1)
```

No setup function is required for the default layout.

## Implemented Defaults

### Normal mode

- `h j k l` move
- `g g` jumps to the start of the buffer
- `G` jumps to the end of the buffer
- `g d` uses `xref` to jump to definition
- `%` jumps to the matching delimiter for `(`/`)`, `[`/`]`, `{`/`}`, `"` and `'`
- `x` deletes the current character
- `u` undoes with Emacs's native undo command
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
- `V` starts linewise visual mode anchored on the current line
- `C-v` starts block selection with `rectangle-mark-mode`
- `g g`, `G`, `/`, `?`, `n`, and `N` keep extending the active visual selection
- `%` extends the active visual selection to the matching delimiter
- `d`, `c`, and `y` operate on the active visual selection
- `i` and `a` retarget the visual selection to inner/around text objects

### Insert mode

- Insert mode keeps standard Emacs bindings
- `ESC` returns to normal mode

## Customization Helpers

- `meow-normal-define-key`
- `meow-visual-define-key`
- `meow-leader-define-key`
- `meow-register-jump-command`

## Notes

- Operator-pending currently covers doubled linewise operators, motion targets `w`/`W`/`b`/`B`/`h`/`l`/`0`/`$`/`f`/`t`, and the requested `i`/`a` text objects.
- Doubled linewise operators like `dd`, `yy`, and `cc` do not trigger Meow's numeric expand hints.
- Vim-style yank operators restore the original cursor position after copying.
- Jump history is window-local and records explicit relocations such as `gg`, `G`, `gd`, `meow-goto-line`, `/?nN`, Meow's mark/global-mark jump helpers, and registered third-party navigation commands.
- Registered command capture ships with a default list for built-in jumps like `beginning-of-buffer`, `end-of-buffer`, `goto-line`, `imenu`, and `xref`, plus common third-party commands such as `consult-*` and `avy-*` when those symbols are present.
- Counts like `2dw`, search-repeat operator targets, and word text-object aliases like `iw` / `aw` are still deferred.
- Block `c` uses Emacs rectangle deletion and then enters insert mode at point; it is not a full Vim-style block-insert implementation yet.
- The `.org` documentation from upstream is still present as legacy reference material and does not yet fully describe this fork.
- The living implementation tracker is in `.plan/PLAN.md`.
- `tests/meow-interactive-demo.el` is the manual smoke buffer for interactive testing.
