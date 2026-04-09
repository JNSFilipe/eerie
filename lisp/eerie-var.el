;;; eerie-var.el --- Eerie variables  -*- lexical-binding: t; -*-

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; Internal variables and customizable variables.

;;; Code:

(defgroup eerie nil
  "Custom group for eerie."
  :group 'eerie-module)

;; Behaviors

(defcustom eerie-use-cursor-position-hack t
  "Whether to use cursor position hack."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-use-enhanced-selection-effect nil
  "Whether to use enhanced cursor effect.

This will affect how selection is displayed."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-expand-exclude-mode-list
  '(markdown-mode org-mode)
  "A list of major modes where after command expand should be disabled."
  :group 'eerie
  :type '(repeat sexp))

(defcustom eerie-selection-command-fallback
  '((eerie-change . eerie-change-char)
    (eerie-kill . eerie-C-k)
    (eerie-save . kill-ring-save)
    (eerie-cancel-selection . keyboard-quit)
    (eerie-pop-selection . eerie-pop-grab)
    (eerie-beacon-change . eerie-beacon-change-char)
    (eerie-expand . eerie-digit-argument))
  "Fallback commands for selection commands when there is no available selection."
  :group 'eerie
  :type '(alist :key-type (function :tag "Command")
                :value-type (function :tag "Fallback")))

(defcustom eerie-replace-state-name-list
  '((normal . "NORMAL")
    (visual . "VISUAL")
    (motion . "MOTION")
    (insert . "INSERT")
    (multicursor . "MULTI")
    (multicursor-visual . "MULTI-V")
    (beacon . "BEACON"))
  "A list of mappings for how to display state in indicator."
  :group 'eerie
  :type '(alist :key-type (symbol :tag "Eerie state")
                :value-type (string :tag "Indicator")))

(defvar eerie-indicator-face-alist
  '((normal . eerie-normal-indicator)
    (visual . eerie-visual-indicator)
    (motion . eerie-motion-indicator)
    (insert . eerie-insert-indicator)
    (multicursor . eerie-beacon-indicator)
    (multicursor-visual . eerie-beacon-indicator)
    (beacon . eerie-beacon-indicator))
  "Alist of eerie states -> faces")

(defcustom eerie-select-on-change nil
  "Whether to activate region when exiting INSERT mode
 after `eerie-change', `eerie-change-char' and `eerie-change-save'."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-select-on-append nil
  "Whether to activate region when exiting INSERT mode after `eerie-append'."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-select-on-insert nil
  "Whether to activate region when exiting INSERT mode after `eerie-insert'."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-expand-hint-remove-delay 1.0
  "The delay before the position hint disappears."
  :group 'eerie
  :type 'number)

(defcustom eerie-next-thing-include-syntax
  '((word " _w" " _w")
    (symbol " _w" " _w"))
  "The syntax to include selecting with eerie-next-THING.

Each item is a (THING FORWARD_SYNTAX_TO_INCLUDE BACKWARD-SYNTAX_TO_INCLUDE)."
  :group 'eerie
  :type '(repeat (list (symbol :tag "Thing")
                       (string :tag "Forward Syntax")
                       (string :tag "Backward Syntax"))))

(defcustom eerie-expand-hint-counts
  '((word . 30)
    (line . 30)
    (block . 30)
    (find . 30)
    (till . 30)
    (symbol . 30))
  "The maximum numbers for expand hints of each type."
  :group 'eerie
  :type '(alist :key-type (symbol :tag "Hint type")
                :value-type (integer :tag "Value")))

(defcustom eerie-char-thing-table
  '((?r . round)
    (?s . square)
    (?c . curly)
    (?g . string)
    (?e . symbol)
    (?w . window)
    (?b . buffer)
    (?p . paragraph)
    (?l . line)
    (?v . visual-line)
    (?d . defun)
    (?. . sentence))
  "Mapping from char to thing."
  :group 'eerie
  :type '(alist :key-type (character :tag "Char")
                :value-type (symbol :tag "Thing")))

(defcustom eerie-thing-selection-directions
  '((inner . forward)
    (bounds . backward)
    (beginning . backward)
    (end . forward))
  "Selection directions for each thing command."
  :group 'eerie
  :type '(alist :key-type (symbol :tag "Command")
                :value-type (symbol :tag "Direction")))

(defvar eerie-word-thing 'word
  "The \\='thing\\=' used for marking and movement by words.

The values is a \\='thing\\=' as understood by `thingatpt' - a symbol that will
be passed to `forward-thing' and `bounds-of-thing-at-point', which see.

This means that they must, at minimum, have a function as the value of their
`forward-op' symbol property (or the function should be defined as
`forward-SYMBOLNAME'). This function should accept a single argument, a number
N, and should move over the next N things, in either the forward or backward
direction depending on the sign of N. Examples of such functions include
`forward-word', `forward-symbol' and `forward-sexp', which `thingatpt' uses for
the `word', `symbol' and `sexp' things, respectively.")

(defvar eerie-symbol-thing 'symbol
  "The \\='thing\\=' used for marking and movement by symbols.

The values is a \\='thing\\=' as understood by `thingatpt' - a symbol that will
be passed to `forward-thing' and `bounds-of-thing-at-point', which see.

This means that they must, at minimum, have a function as the value of their
`forward-op' symbol property (or the function should be defined as
`forward-SYMBOLNAME'). This function should accept a single argument, a number
N, and should move over the next N things, in either the forward or backward
direction depending on the sign of N. Examples of such functions include
`forward-word', `forward-symbol' and `forward-sexp', which `thingatpt' uses for
the `word', `symbol' and `sexp' things, respectively.")

(defcustom eerie-display-thing-help t
  "Whether to display the help prompt for eerie-inner/bounds/begin/end-of-thing."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-pop-or-unpop-to-mark-repeat-unpop nil
  "Non-nil means that calling `eerie-pop-or-unpop-to-mark'
after calling it with a negative argument unpops the mark again.

This variable is meant to be similar to `set-mark-command-repeat-pop'."
  :group 'eerie
  :type 'boolean)


(defcustom eerie-grab-fill-commands
  '(eerie-query-replace eerie-query-replace-regexp)
  "A list of commands that eerie will auto fill with grabbed content."
  :group 'eerie
  :type '(repeat function))

(defcustom eerie-visit-collect-min-length 1
  "Minimal length when collecting symbols for `eerie-visit'."
  :group 'eerie
  :type 'integer)

(defcustom eerie-visit-sanitize-completion t
  "Whether let `eerie-visit' display symbol regexps in a sanitized format."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-use-clipboard nil
  "Whether to use system clipboard."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-use-dynamic-face-color t
  "Whether to use dynamic calculated face color.

This option will affect the color of position hint and fake region cursor."
  :group 'eerie
  :type 'boolean)

(defcustom eerie-mode-state-list
  '((conf-mode . normal)
    (fundamental-mode . normal)
    (help-mode . motion)
    (prog-mode . normal)
    (text-mode . normal))
  "A list of rules, each is (major-mode . init-state).

The init-state can be any state, including custom ones."
  :group 'eerie
  :type '(alist :key-type (sexp :tag "Major-mode")
                :value-type (symbol :tag "Initial state")))

(defcustom eerie-update-display-in-macro 'except-last-macro
  "Whether update cursor and mode-line when executing kbd macro.

Set to `nil' for no update in macro,
may not work well with some packages. (e.g. key-chord).

Set to `except-last-macro'
for no update only when executing last macro.

Set to `t' to always update.
"
  :group 'eerie
  :type '(choice boolean
                 (const except-last-macro)))

(defcustom eerie-expand-selection-type 'select
  "Whether to create transient selection for expand commands."
  :group 'eerie
  :type '(choice (const select)
                 (const expand)))

(defcustom eerie-goto-line-function nil
  "Function to use in `eerie-goto-line'.

Nil means find the command by key binding."
  :group 'eerie
  :type '(choice function (const nil)))

(defvar eerie-state-mode-alist
  '((normal . eerie-normal-mode)
    (visual . eerie-visual-mode)
    (insert . eerie-insert-mode)
    (motion . eerie-motion-mode)
    (multicursor . eerie-multicursor-mode)
    (multicursor-visual . eerie-multicursor-visual-mode)
    (beacon . eerie-beacon-mode))
  "Alist of eerie states -> modes")

(defvar eerie-update-cursor-functions-alist
  '((eerie--cursor-null-p . eerie--update-cursor-default)
    (minibufferp         . eerie--update-cursor-default)
    (eerie-insert-mode-p  . eerie--update-cursor-insert)
    (eerie-visual-mode-p  . eerie--update-cursor-visual)
    (eerie-normal-mode-p  . eerie--update-cursor-normal)
    (eerie-motion-mode-p  . eerie--update-cursor-motion)
    (eerie-multicursor-mode-p . eerie--update-cursor-beacon)
    (eerie-multicursor-visual-mode-p . eerie--update-cursor-beacon)
    (eerie-beacon-mode-p  . eerie--update-cursor-beacon)
    ((lambda () t)       . eerie--update-cursor-default))
  "Alist of predicates to functions that set cursor type and color.")

;; Cursor types

(defvar eerie-cursor-type-default 'box)
(defvar eerie-cursor-type-normal 'box)
(defvar eerie-cursor-type-visual 'box)
(defvar eerie-cursor-type-motion 'box)
(defvar eerie-cursor-type-beacon 'box)
(defvar eerie-cursor-type-region-cursor '(bar . 2))
(defvar eerie-cursor-type-insert '(bar . 2))

(defvar eerie--prefix-arg nil)

;;; KBD Macros
;; We use kbd macro instead of direct command/function invocation,
;; this allows us to avoid hard coding the command/function name.
;;
;; The benefit is an out-of-box integration support for other plugins, like: paredit.
;;
;; NOTE: eerie assumes that the user does not modify vanilla Emacs keybindings, otherwise extra complexity will be introduced.

(defvar eerie--kbd-undo "C-/"
  "KBD macro for command `undo'.")

(defvar eerie--kbd-backward-char "C-b"
  "KBD macro for command `backward-char'.")

(defvar eerie--kbd-forward-char "C-f"
  "KBD macro for command `forward-char'.")

(defvar eerie--kbd-keyboard-quit "C-g"
  "KBD macro for command `keyboard-quit'.")

(defvar eerie--kbd-find-ref "M-."
  "KBD macro for command `xref-find-definitions'.")

(defvar eerie--kbd-pop-marker "M-,"
  "KBD macro for command `xref-pop-marker-stack'.")

(defvar eerie--kbd-comment "M-;"
  "KBD macro for comment command.")

(defvar eerie--kbd-kill-line "C-k"
  "KBD macro for command `kill-line'.")

(defvar eerie--kbd-kill-whole-line "<C-S-backspace>"
  "KBD macro for command `kill-whole-line'.")

(defvar eerie--kbd-delete-char "C-d"
  "KBD macro for command `delete-char'.")

(defvar eerie--kbd-yank "C-y"
  "KBD macro for command `yank'.")

(defvar eerie--kbd-yank-pop "M-y"
  "KBD macro for command `yank-pop'.")

(defvar eerie--kbd-kill-ring-save "M-w"
  "KBD macro for command `kill-ring-save'.")

(defvar eerie--kbd-kill-region "C-w"
  "KBD macro for command `kill-region'.")

(defvar eerie--kbd-exchange-point-and-mark "C-x C-x"
  "KBD macro for command `exchange-point-and-mark'.")

(defvar eerie--kbd-back-to-indentation "M-m"
  "KBD macro for command `back-to-indentation'.")

(defvar eerie--kbd-indent-region "C-M-\\"
  "KBD macro for command `indent-region'.")

(defvar eerie--kbd-delete-indentation "M-^"
  "KBD macro for command `delete-indentation'.")

(defvar eerie--kbd-forward-slurp "C-)"
  "KBD macro for command forward slurp.")

(defvar eerie--kbd-backward-slurp "C-("
  "KBD macro for command backward slurp.")

(defvar eerie--kbd-forward-barf "C-}"
  "KBD macro for command forward barf.")

(defvar eerie--kbd-backward-barf "C-{"
  "KBD macro for command backward barf.")

(defvar eerie--kbd-scoll-up "C-v"
  "KBD macro for command `scroll-up'.")

(defvar eerie--kbd-scoll-down "M-v"
  "KBD macro for command `scroll-down'.")

(defvar eerie--kbd-just-one-space "M-SPC"
  "KBD macro for command `just-one-space.")

(defvar eerie--kbd-wrap-round "M-("
  "KBD macro for command wrap round.")

(defvar eerie--kbd-wrap-square "M-["
  "KBD macro for command wrap square.")

(defvar eerie--kbd-wrap-curly "M-{"
  "KBD macro for command wrap curly.")

(defvar eerie--kbd-wrap-string "M-\""
  "KBD macro for command wrap string.")

(defvar eerie--kbd-excute-extended-command "M-x"
  "KBD macro for command `execute-extended-command'.")

(defvar eerie--kbd-transpose-sexp "C-M-t"
  "KBD macro for command transpose sexp.")

(defvar eerie--kbd-split-sexp "M-S"
  "KBD macro for command split sexp.")

(defvar eerie--kbd-splice-sexp "M-s"
  "KBD macro for command splice sexp.")

(defvar eerie--kbd-raise-sexp "M-r"
  "KBD macro for command raise sexp.")

(defvar eerie--kbd-join-sexp "M-J"
  "KBD macro for command join sexp.")

(defvar eerie--kbd-eval-last-exp "C-x C-e"
  "KBD macro for command eval last exp.")

(defvar eerie--kbd-query-replace-regexp "C-M-%"
  "KBD macro for command `query-replace-regexp'.")

(defvar eerie--kbd-query-replace "M-%"
  "KBD macro for command `query-replace'.")

(defvar eerie--kbd-forward-line "C-n"
  "KBD macro for command `forward-line'.")

(defvar eerie--kbd-backward-line "C-p"
  "KBD macro for command `backward-line'.")

(defvar eerie--kbd-search-forward-regexp "C-M-s"
  "KBD macro for command `search-forward-regexp'.")

(defvar eerie--kbd-search-backward-regexp "C-M-r"
  "KBD macro for command `search-backward-regexp'.")

(defvar eerie--kbd-goto-line "M-g g"
  "KBD macro for command `goto-line'.")

(defvar eerie--delete-region-function #'delete-region
  "The function used to delete the selection.

Allows support of modes that define their own equivalent of
`delete-region'.")

(defvar eerie--insert-function #'insert
  "The function used to insert text in Normal state.

Allows support of modes that define their own equivalent of `insert'.")

(defvar-local eerie--indicator nil
  "Indicator for current buffer.")

(defvar-local eerie--selection nil
  "Current selection.

Has a structure of (sel-type point mark).")

(defvar eerie--kbd-pop-global-mark "C-x C-@"
  "KBD macro for command `pop-global-mark'.")

;;; Hooks

(defvar eerie-switch-state-hook nil
  "Hooks run when switching state.")

(defvar eerie-insert-enter-hook nil
  "Hooks run when enter insert state.")

(defvar eerie-insert-exit-hook nil
  "Hooks run when exit insert state.")

;;; Internal variables

(defvar-local eerie--current-state 'normal
  "A symbol represent current state.")

(defvar-local eerie--visual-type nil
  "Current visual selection flavor.

The value is nil, `char', `line', or `block'.")

(defvar-local eerie--end-kmacro-on-exit nil
  "Whether we end kmacro recording when exit insert state.")

(defvar-local eerie--temp-normal nil
  "Whether we are in temporary normal state. ")

(defvar eerie--selection-history nil
  "The history of selections.")

(defvar eerie--expand-nav-function nil
  "Current expand nav function.")

(defvar eerie--last-find nil
  "The char for last find command.")

(defvar eerie--last-till nil
  "The char for last till command.")

(defvar eerie--visual-command nil
  "Current command to highlight.")

(defvar eerie--expanding-p nil
  "Whether we are expanding.")

(defvar eerie--beacon-backup-hl-line
  nil
  "Whether hl-line is enabled by user.")

(defvar eerie--beacon-defining-kbd-macro nil
  "Whether we are defining kbd macro at BEACON state.

The value can be nil, quick or record.")

(defvar-local eerie--insert-pos nil
  "The position where we enter INSERT state.")

(defvar-local eerie--insert-activate-mark nil
  "Whether we should activate the selection after exiting INSERT state.")

(defvar-local eerie--multiedit-seed nil
  "Original text used to grow the current multi-edit session.")

(defvar-local eerie--multiedit-direction 'forward
  "Direction used by the current multi-edit builder.")

(defvar-local eerie--multiedit-targets nil
  "List of selected ranges in the current multi-edit session.")

(defvar-local eerie--multiedit-primary nil
  "Currently active range in the current multi-edit session.")

(defvar-local eerie--multiedit-search-head nil
  "Range used as the next search origin in the current multi-edit session.")

(defvar-local eerie--multiedit-overlays nil
  "Overlays used to render secondary multi-edit targets.")

(defvar-local eerie--multiedit-backward nil
  "Whether the active multi-edit selection is backward.")

(defvar-local eerie--multiedit-replay-markers nil
  "Replay targets for the current multi-edit or block insert session.

Each target is either a marker or a cons cell of the form
\(MARKER . COLUMN), where COLUMN is the target insertion column on the
line identified by MARKER.")

(defvar-local eerie--multiedit-replay-command nil
  "Command symbol used to replay the current multi-edit insert or change.")

(defvar-local eerie--multicursor-active nil
  "Whether a Eerie multi-cursor session is active in the current buffer.")

(defvar-local eerie--multicursor-replaying nil
  "Whether Eerie is currently replaying a multi-cursor command.")

(defvar-local eerie--multicursor-last-command nil
  "Most recent primary command executed in the current multi-cursor session.")

(defvar-local eerie--multicursor-command-keys nil
  "Top-level key sequence for the current multi-cursor primary command.")

(defvar-local eerie--multicursor-read-events nil
  "Extra events read by the current multi-cursor primary command.")

(defvar-local eerie--multicursor-command nil
  "Primary command being replayed in the current multi-cursor session.")

(defvar-local eerie--multicursor-prefix-arg nil
  "Primary prefix argument being replayed in the current multi-cursor session.")

(defvar-local eerie--multicursor-replay-inputs nil
  "Remaining interactive inputs for the current replayed multi-cursor command.")

(defvar eerie-full-width-number-position-chars
  '((0 . "０")
    (1 . "１")
    (2 . "２")
    (3 . "３")
    (4 . "４")
    (5 . "５")
    (6 . "６")
    (7 . "７")
    (8 . "８")
    (9 . "９"))
  "Map number to full-width character.")

(defvar eerie-cheatsheet-ellipsis "…"
  "Ellipsis character used in cheatsheet.")

(defvar eerie-command-to-short-name-list
  '((eerie-expand-0 . "ex →0")
    (eerie-expand-1 . "ex →1")
    (eerie-expand-2 . "ex →2")
    (eerie-expand-3 . "ex →3")
    (eerie-expand-4 . "ex →4")
    (eerie-expand-5 . "ex →5")
    (eerie-expand-6 . "ex →6")
    (eerie-expand-7 . "ex →7")
    (eerie-expand-8 . "ex →8")
    (eerie-expand-9 . "ex →9")
    (digit-argument . "num-arg")
    (eerie-inner-of-thing . "←thing→")
    (eerie-bounds-of-thing . "[thing]")
    (eerie-beginning-of-thing . "←thing")
    (eerie-end-of-thing . "thing→")
    (eerie-reverse . "reverse")
    (eerie-prev . "↑")
    (eerie-prev-expand . "ex ↑")
    (eerie-next . "↓")
    (eerie-next-expand . "ex ↓")
    (eerie-head . "←")
    (eerie-head-expand . "ex ←")
    (eerie-tail . "→")
    (eerie-tail-expand . "ex →")
    (eerie-left . "←")
    (eerie-left-expand . "ex ←")
    (eerie-right . "→")
    (eerie-right-expand . "ex →")
    (eerie-yank . "yank")
    (eerie-find . "find")
    (eerie-find-expand . "ex find")
    (eerie-till . "till")
    (eerie-till-expand . "ex till")
    (eerie-keyboard-quit . "C-g")
    (eerie-cancel-selection . "quit sel")
    (eerie-change . "chg")
    (eerie-change-save . "chg-save")
    (eerie-visual-change . "v-chg")
    (eerie-replace . "rep")
    (eerie-replace-save . "rep-save")
    (eerie-append . "append")
    (eerie-insert . "insert")
    (eerie-visual-start . "visual")
    (eerie-visual-line-start . "visual-ln")
    (eerie-visual-block-start . "visual-blk")
    (eerie-multicursor-start . "mc-start")
    (eerie-multicursor-match-next . "mc+")
    (eerie-multicursor-unmatch-last . "mc-")
    (eerie-multicursor-skip-match . "mc-skip")
    (eerie-multicursor-visual-exit . "mc-ready")
    (eerie-multiedit-match-next . "multi+")
    (eerie-multiedit-unmatch-last . "multi-")
    (eerie-multiedit-skip-match . "multi-skip")
    (eerie-multiedit-reverse-direction . "multi-dir")
    (eerie-multicursor-spawn . "mc-spawn")
    (eerie-multicursor-cancel . "mc-cancel")
    (eerie-multicursor-jump-char . "mc-find")
    (eerie-multicursor-next-space . "mc-W")
    (eerie-block . "block")
    (eerie-to-block "→block")
    (eerie-line . "line")
    (eerie-delete . "del")
    (eerie-search . "search")
    (eerie-search-forward . "/")
    (eerie-search-backward . "?")
    (eerie-search-next . "search->")
    (eerie-search-prev . "<-search")
    (eerie-jump-char . "jump-char")
    (eerie-jump-word-occurrence . "jump-word")
    (eerie-next-space . "W")
    (eerie-undo . "undo")
    (eerie-undo-in-selection . "undo-sel")
    (eerie-pop-search . "popsearch")
    (negative-argument . "neg-arg")
    (eerie-quit . "quit")
    (eerie-join . "join")
    (eerie-kill . "kill")
    (eerie-save . "save")
    (eerie-next-word . "word→")
    (eerie-next-symbol . "sym→")
    (eerie-back-word . "←word")
    (eerie-back-symbol . "←sym")
    (eerie-pop-all-selection . "pop-sels")
    (eerie-pop-selection . "pop-sel")
    (eerie-mark-word . "←word→")
    (eerie-mark-symbol . "←sym→")
    (eerie-visit . "visit")
    (eerie-kmacro-lines . "macro-ln")
    (eerie-kmacro-matches . "macro-re")
    (eerie-end-or-call-kmacro . "callmacro")
    (eerie-cheatsheet . "help")
    (eerie-describe-key . "desc-key")
    (eerie-backspace . "backspace")
    (eerie-jump-back . "<-jump")
    (eerie-jump-forward . "jump->")
    (eerie-pop-to-mark . "<-mark")
    (eerie-unpop-to-mark . "mark->"))
  "A list of (command . short-name)")

(defvar eerie--jump-back-stack nil
  "Fallback stack of markers for backward jump history.

Active jump stacks are stored per window.")

(defvar eerie--jump-forward-stack nil
  "Fallback stack of markers for forward jump history.

Active jump stacks are stored per window.")

(defcustom eerie-jump-auto-record-commands
  '(beginning-of-buffer
    end-of-buffer
    goto-line
    bookmark-jump
    imenu
    pop-global-mark
    pop-to-mark-command
    xref-find-definitions
    xref-find-references
    xref-find-apropos
    xref-go-back
    xref-go-forward
    xref-pop-marker-stack
    consult-grep
    consult-git-grep
    consult-global-mark
    consult-imenu
    consult-line
    consult-line-multi
    consult-mark
    consult-ripgrep)
  "Commands that should create jumplist entries when they relocate point."
  :group 'eerie
  :type '(repeat symbol))

(defvar eerie--last-search-direction 'forward
  "Direction used by the most recent Vim-style Eerie search.")

(defvar eerie--jump-tracking-refcount 0
  "Number of live Eerie buffers that require jump tracking hooks.")

(defvar eerie--which-key-enabled-by-eerie nil
  "Whether Eerie enabled `which-key-mode' for the current global session.")

(defvar-local eerie--visual-line-anchor nil
  "Anchor range for the current linewise VISUAL selection.")

(defcustom eerie-replace-pop-command-start-indexes
  '((eerie-replace . 1)
    (eerie-replace-char . 1)
    (eerie-replace-save . 2))
  "Alist of commands and their starting indices for use by `eerie-replace-pop'.

If `eerie-replace-pop' is run and the previous command is not
`eerie-replace-pop' or a command which is present in this alist,
`eerie-replace-pop' signals an error."
  :type '(alist :key-type function :value-type natnum))

(defvar eerie--replace-pop-index nil
  "The index of the previous replacement in the `kill-ring'.
See also the command `eerie-replace-pop'.")

(defvar eerie--replace-start-marker (make-marker)
  "The beginning of the replaced text.

This marker stays before any text inserted at the location, to
account for any automatic formatting that happens after inserting
the replacement text.")

;;; Backup variables

(defvar eerie--backup-var-delete-activae-region nil
  "The backup for `delete-active-region'.

It is used to restore its value when disable `eerie'.")

(defvar eerie--backup-redisplay-highlight-region-function
  redisplay-highlight-region-function)

(defvar eerie--backup-redisplay-unhighlight-region-function
  redisplay-unhighlight-region-function)

(defvar eerie--backup-var-delete-activate-region
  delete-active-region)

(provide 'eerie-var)
;;; eerie-var.el ends here
