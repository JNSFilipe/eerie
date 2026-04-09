;;; eerie-interactive-demo.el --- Manual smoke buffer for Eerie Vim fork -*- lexical-binding: t; -*-

;; Open this file with:
;;   emacs -Q -L . tests/eerie-interactive-demo.el --eval "(require 'eerie)" --eval "(eerie-global-mode 1)"
;;
;; Suggested checks:
;; - `u`: delete or change text below, then undo it.
;; - `W`: from the beginning of `targetword` or the operator lines below, move to the next space on the current line; repeated `W` should continue to the following space, and once no later space remains it should fall back to the end of the line. After `w`, `m`, `.`, and `v`, the first `W` should also skip the immediate separator after the selected word instead of looking stuck on it.
;; - `f`: jump to visible `A` or `x` below with `1`-`9`, and press `;` to reverse direction. In visual mode, `f` should extend the current selection to include the chosen char, `f<char> ; 1` should skip the current cursor char and go to the previous match, and the visible labels should still match the number keys after each same-loop jump.
;; - `V`: start on the first, middle, and last lines of each section. It should begin with the current line selected, show visible-line hints immediately, let `1`-`9` jump the active linewise selection to another visible line, let `;` reverse that line-hint direction, and recenter when needed so you still get up to 9 hints before the real buffer edge.
;; - `C-v`: start on the aligned columns below, then move with `j` / `k`. It should immediately select the current character column, `C-v j d` should delete that column across the selected lines, `C-v j I` should insert on each selected line, and `C-v j A` should append on each selected line.
;; - `/`, `?`, `n`, `N`: search for "target" and walk the jumplist with `C-o` / `C-i`.
;; - `gd`: place point on `eerie-demo-helper` inside `eerie-demo-call-site`.
;; - `w`: start on any `targetword` below, then jump between visible occurrences with `1`-`9` and `;`; `w ; 1` from a middle occurrence should go to the previous one, not stay on the current word. After that, `f`, `ESC`, movement keys, and `d` should behave like a normal visual selection.
;; - `m`: from normal mode, enter multicursor mode. Then select one `targetword` with `v` or `w`, press `.`, `.`, `,`, `-`, `.`, and `ESC`. The original selected text should stay frozen as the match seed, older matches should remain highlighted as secondary overlays, `,` should remove the newest target, `-` should skip one hidden candidate without selecting it, and `ESC` should clear the whole multicursor session.
;; - Visual `m`: start with a plain visual selection on one `targetword`, press `m`, then `.`. That should enter the same canonical multicursor session directly from visual mode, keep the original selection as the exact-match seed, and leave both matches highlighted.
;; - Multicursor visual actions: on the `targetword` line below, enter multicursor mode with `m`, select one `targetword`, grow with `.`, then try `i` and `a` with some inserted text before `ESC`, and then repeat with `d` and `c`. Multicursor visual `i` should insert at the beginning of every selected target, multicursor visual `a` should append after every selected target, `d` should delete them all, and `c` should change them all to the same inserted text.
;; - Multicursor normal: after growing a multicursor selection with `.`, press `v` to promote it into multi-cursor normal mode. Then try normal commands like `h`, `l`, `x`, `%`, `gg`, `G`, `W`, and visible `f<char>1`, plus selection entry with `v`, `V`, `C-v`, and text objects like `vi(` on the parallel lines below. Those visual-entry keys should stay multi-cursor-aware instead of dropping back to a single primary cursor. Insert-like commands such as `i`, `a`, `I`, `A`, or `c` should still replay on `ESC`. `ESC` from the multi-cursor state itself should cancel the full cursor set.
;; - `di(`, `da[`, `ci"`, `dw`, `dd`, `yy`: use the marked sections below.

(defun eerie-demo-helper (value)
  "Return VALUE with a visible prefix."
  (format "helper:%s" value))

(defun eerie-demo-call-site ()
  "Call `eerie-demo-helper' for `gd' testing."
  (eerie-demo-helper "target"))

(setq eerie-demo-undo-text
      "Undo target: delete, change, paste, and then press u to revert.")

(setq eerie-demo-search-lines
      '("search target alpha target beta target gamma"
        "search target delta target epsilon target zeta"
        "search target eta target theta target iota"))

(setq eerie-demo-text-objects
      '("(inner round target)"
        "[around square target]"
        "{around curly target}"
        "\"quoted target\""
        "'single quoted target'"))

(setq eerie-demo-wrap-lines
      '("This line is intentionally long so V can be tested near the beginning while the window is narrow enough to wrap the line into multiple visual segments without needing any extra setup."
        "This second long line is also intentionally long so V can be tested near the middle and the end of the buffer after repeated j and k motions."))

;; Block selection target:
;; Place point on the same digit/letter column and use C-v, j, k, h, l.
;;
;; 0123456789ABCDEF
;; abcdefghijklmnop
;; uvwxyzABCDEFGHIJ
;; 0123456789KLMNOP

;; Operator target lines:
;; dw should remove the next word.
;; dd should remove the whole line.
;; yy should yank the whole line.
;;
;; target one two three
;; target four five six
;; target seven eight nine

;; Visible jump targets:
;; - `f` on `A` should show numbered hints on the visible `A` characters.
;; - `w` on `targetword` should select the current word and its visible occurrences, then leave a normal visual selection behind.
;;
;; A x A y A z A
;; targetword alpha targetword beta targetword gamma targetword

;;; eerie-interactive-demo.el ends here
