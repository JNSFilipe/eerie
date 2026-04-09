;;; eerie-commands.el --- Commands in Eerie -*- lexical-binding: t -*-

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
;; Implementation for all commands in Eerie.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'seq)

(require 'eerie-var)
(require 'eerie-util)
(require 'eerie-visual)
(require 'eerie-thing)
(require 'eerie-beacon)
(require 'array)
(require 'which-key)

(defun eerie--selection-fallback ()
  "Run selection fallback commands."
  (if-let* ((fallback (alist-get this-command eerie-selection-command-fallback)))
      (call-interactively fallback)
    (error "No selection")))

(defun eerie--pop-selection ()
  "Pop a selection from variable `eerie--selection-history' and activate."
  (when eerie--selection-history
    (let ((sel (pop eerie--selection-history)))
      (eerie--select-without-history sel))))

(defun eerie--make-selection (type mark pos &optional expand)
  "Make a selection with TYPE, MARK and POS.

The direction of selection is MARK -> POS."
  (if (and (region-active-p) expand)
      (let ((orig-mark (mark))
            (orig-pos (point)))
        (if (< mark pos)
            (list type (min orig-mark orig-pos) pos)
          (list type (max orig-mark orig-pos) pos)))
    (list type mark pos)))

(defun eerie--set-mark (&optional location nomsg activate)
  "As `push-mark', but don't push old mark to mark ring."
  (setq location (or location (point)))
  (if (or activate (not transient-mark-mode))
      (set-mark location)
    (set-marker (mark-marker) location))
  (or nomsg executing-kbd-macro (> (minibuffer-depth) 0)
      (message "Mark set"))
  nil)

(defun eerie--select (selection &optional activate backward)
  "Mark the SELECTION."
  (let* ((old-sel-type (eerie--selection-type))
        (sel-type (car selection))
        (beg (cadr selection))
        (end (caddr selection))
        (to-go (if backward beg end))
        (to-mark (if backward end beg)))
    (when sel-type
      (if eerie--selection
          (unless (equal eerie--selection (car eerie--selection-history))
            (push eerie--selection eerie--selection-history))
        (push (eerie--make-selection nil (point) (point)) eerie--selection-history))
      (cond
       ((null old-sel-type)
        (goto-char to-go)
        (push-mark to-mark t activate))
       (t
        (goto-char to-go)
        (set-mark to-mark)))
      (setq eerie--selection selection))))

(defun eerie--select-without-history (selection)
  "Mark the SELECTION without recording it in `eerie--selection-history'."
  (let ((sel-type (car selection))
        (mark (cadr selection))
        (pos (caddr selection)))
    (goto-char pos)
    (if (not sel-type)
        (progn
          (deactivate-mark)
          (message "No previous selection.")
          (eerie--cancel-selection))
      (push-mark mark t t)
      (setq eerie--selection selection))))

(defun eerie--cancel-selection ()
  "Cancel current selection, clear selection history and deactivate the mark.

If there's a selection history, move the mark to the beginning position
in the history before deactivation."
  (when eerie--selection-history
    (let ((orig-pos (cadar (last eerie--selection-history))))
      (set-marker (mark-marker) orig-pos)))
  (setq eerie--selection-history nil
        eerie--selection nil)
  (deactivate-mark t))

(defun eerie-undo ()
  "Cancel current selection then undo."
  (interactive)
  (when (region-active-p)
    (eerie--cancel-selection))
  (if (fboundp 'undo-only)
      (undo-only 1)
    (undo 1)))

(defun eerie-undo-in-selection ()
  "Cancel undo in current region."
  (interactive)
  (when (region-active-p)
    (undo-in-region (region-beginning) (region-end))))

(defun eerie-pop-selection ()
  (interactive)
  (eerie--with-selection-fallback
   (eerie--pop-selection)
   (when (and (region-active-p) eerie--expand-nav-function)
     (eerie--maybe-highlight-num-positions))))

(defun eerie-pop-all-selection ()
  (interactive)
  (while (eerie--pop-selection)))

;;; exchange mark and point

(defun eerie-reverse ()
  "Just exchange point and mark.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (eerie--with-selection-fallback
   (eerie--execute-kbd-macro eerie--kbd-exchange-point-and-mark)
   (if (member last-command
               '(eerie-visit eerie-search eerie-mark-symbol eerie-mark-word))
       (eerie--highlight-regexp-in-buffer (car regexp-search-ring))
     (eerie--maybe-highlight-num-positions))))

;;; Buffer

(defun eerie-find-ref ()
  "Xref find."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-find-ref))

(defun eerie-pop-marker ()
  "Pop marker."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-pop-marker))

(defun eerie--jump-marker-live-p (marker)
  "Whether MARKER still points to a live buffer position."
  (and (markerp marker)
       (marker-buffer marker)
       (buffer-live-p (marker-buffer marker))))

(defconst eerie--jump-back-stack-window-parameter 'eerie-jump-back-stack
  "Window parameter used to store backward jump history.")

(defconst eerie--jump-forward-stack-window-parameter 'eerie-jump-forward-stack
  "Window parameter used to store forward jump history.")

(defconst eerie--explicit-jump-commands
  '(eerie-goto-buffer-start
    eerie-goto-buffer-end
    eerie-goto-definition
    eerie-goto-line
    eerie-jump-char
    eerie-jump-word-occurrence
    eerie-pop-to-mark
    eerie-unpop-to-mark
    eerie-pop-to-global-mark
    eerie-search-forward
    eerie-search-backward
    eerie-search-next
    eerie-search-prev)
  "Commands that manage jump recording explicitly.")

(defun eerie--jump-stack-parameter (direction)
  "Return the window parameter symbol for jump stack DIRECTION."
  (pcase direction
    ('back eerie--jump-back-stack-window-parameter)
    ('forward eerie--jump-forward-stack-window-parameter)
    (_ (error "Unknown jump direction: %S" direction))))

(defun eerie--jump-stack-variable (direction)
  "Return the compatibility variable symbol for jump stack DIRECTION."
  (pcase direction
    ('back 'eerie--jump-back-stack)
    ('forward 'eerie--jump-forward-stack)
    (_ (error "Unknown jump direction: %S" direction))))

(defun eerie--get-jump-stack (direction &optional window)
  "Return the jump stack for DIRECTION in WINDOW."
  (window-parameter (or window (selected-window))
                    (eerie--jump-stack-parameter direction)))

(defun eerie--set-jump-stack (direction stack &optional window)
  "Set the jump STACK for DIRECTION in WINDOW."
  (let ((window (or window (selected-window))))
    (set-window-parameter window (eerie--jump-stack-parameter direction) stack)
    (when (eq window (selected-window))
      (set (eerie--jump-stack-variable direction) stack))
    stack))

(defun eerie--jump-marker-equal-p (left right)
  "Whether LEFT and RIGHT point to the same location."
  (and (eerie--jump-marker-live-p left)
       (eerie--jump-marker-live-p right)
       (eq (marker-buffer left) (marker-buffer right))
       (= (marker-position left) (marker-position right))))

(defun eerie--jump-marker-at-point-p (marker)
  "Whether MARKER points to the current location."
  (and (eerie--jump-marker-live-p marker)
       (eq (marker-buffer marker) (current-buffer))
       (= (marker-position marker) (point))))

(defun eerie--jump-marker-at-window-point-p (marker window)
  "Whether MARKER points to WINDOW's current point."
  (and (eerie--jump-marker-live-p marker)
       (window-live-p window)
       (eq (marker-buffer marker) (window-buffer window))
       (= (marker-position marker) (window-point window))))

(defun eerie--push-jump-on-stack (direction marker &optional window)
  "Push MARKER onto jump stack DIRECTION in WINDOW."
  (let* ((window (or window (selected-window)))
         (stack (eerie--get-jump-stack direction window))
         (top (car stack)))
    (unless (or (not (eerie--jump-marker-live-p marker))
                (eerie--jump-marker-equal-p top marker))
      (eerie--set-jump-stack direction (cons marker stack) window))))

(defun eerie--pop-jump (direction &optional window)
  "Pop and return the next live marker from jump stack DIRECTION in WINDOW."
  (let* ((window (or window (selected-window)))
         (stack (eerie--get-jump-stack direction window)))
    (while (and stack
                (not (eerie--jump-marker-live-p (car stack))))
      (setq stack (cdr stack)))
    (eerie--set-jump-stack direction stack window)
    (when stack
      (prog1 (car stack)
        (eerie--set-jump-stack direction (cdr stack) window)))))

(defun eerie--push-jump (&optional marker window)
  "Record MARKER in backward jump history for WINDOW and clear forward history."
  (let ((window (or window (selected-window))))
    (eerie--push-jump-on-stack 'back (or marker (point-marker)) window)
    (eerie--set-jump-stack 'forward nil window)))

(defun eerie--auto-record-jump-command-p (command)
  "Whether COMMAND should be tracked automatically for jump history."
  (and command
       (not (memq command eerie--explicit-jump-commands))
       (memq command eerie-jump-auto-record-commands)))

(defun eerie--auto-record-jump-advice (fn &rest args)
  "Around advice that records successful relocations for jump-aware commands."
  (if (not (bound-and-true-p eerie-mode))
      (apply fn args)
    (let ((start (point-marker))
          (origin-window (selected-window)))
      (prog1
          (apply fn args)
        (let ((destination-window (if (window-minibuffer-p (selected-window))
                                      origin-window
                                    (selected-window))))
          (when (and (window-live-p destination-window)
                     (not (eerie--jump-marker-at-window-point-p start destination-window)))
            (eerie--push-jump start destination-window)))))))

(defun eerie--set-jump-command-advice (command enabled)
  "Enable or disable jump-recording advice for COMMAND."
  (when (fboundp command)
    (if enabled
        (unless (advice-member-p #'eerie--auto-record-jump-advice command)
          (advice-add command :around #'eerie--auto-record-jump-advice))
      (when (advice-member-p #'eerie--auto-record-jump-advice command)
        (advice-remove command #'eerie--auto-record-jump-advice)))))

(defun eerie--refresh-jump-command-advice (&rest _)
  "Refresh advice for auto-recorded jump commands."
  (when (> eerie--jump-tracking-refcount 0)
    (dolist (command eerie-jump-auto-record-commands)
      (when (eerie--auto-record-jump-command-p command)
        (eerie--set-jump-command-advice command t)))))

(defun eerie--enable-jump-tracking ()
  "Enable jump-tracking advice when Eerie becomes active."
  (cl-incf eerie--jump-tracking-refcount)
  (when (= eerie--jump-tracking-refcount 1)
    (add-hook 'after-load-functions #'eerie--refresh-jump-command-advice)
    (eerie--refresh-jump-command-advice)))

(defun eerie--disable-jump-tracking ()
  "Disable jump-tracking advice when no Eerie buffers remain."
  (when (> eerie--jump-tracking-refcount 0)
    (cl-decf eerie--jump-tracking-refcount))
  (when (= eerie--jump-tracking-refcount 0)
    (remove-hook 'after-load-functions #'eerie--refresh-jump-command-advice)
    (dolist (command eerie-jump-auto-record-commands)
      (when (eerie--auto-record-jump-command-p command)
        (eerie--set-jump-command-advice command nil)))))

(defmacro eerie--with-recorded-jump (&rest body)
  "Run BODY and record the starting location if point relocates."
  (declare (debug t) (indent 0))
  `(let ((start (point-marker)))
     (prog1
         (progn ,@body)
       (unless (eerie--jump-marker-at-point-p start)
         (eerie--push-jump start)))))

(defun eerie--goto-jump-marker (marker)
  "Jump to MARKER in the current window."
  (let ((buffer (marker-buffer marker)))
    (unless (buffer-live-p buffer)
      (user-error "Jump target is no longer available"))
    (switch-to-buffer buffer)
    (goto-char (marker-position marker))
    (recenter)))

(defun eerie-jump-back ()
  "Jump backward through Eerie jump history."
  (interactive)
  (eerie--cancel-selection)
  (if-let ((marker (eerie--pop-jump 'back)))
      (progn
        (eerie--push-jump-on-stack 'forward (point-marker))
        (eerie--goto-jump-marker marker))
    (user-error "Jump history is empty")))

(defun eerie-jump-forward ()
  "Jump forward through Eerie jump history."
  (interactive)
  (eerie--cancel-selection)
  (if-let ((marker (eerie--pop-jump 'forward)))
      (progn
        (eerie--push-jump-on-stack 'back (point-marker))
        (eerie--goto-jump-marker marker))
    (user-error "Forward jump history is empty")))

(defun eerie-register-jump-command (command)
  "Register COMMAND for automatic jumplist recording."
  (interactive
   (list
    (intern
     (completing-read "Jump command: " obarray #'commandp t))))
  (add-to-list 'eerie-jump-auto-record-commands command)
  (when (> eerie--jump-tracking-refcount 0)
    (eerie--set-jump-command-advice command t)))

(defun eerie-goto-buffer-start ()
  "Jump to the start of the current buffer."
  (interactive)
  (eerie--with-recorded-jump
    (eerie--cancel-selection)
    (goto-char (point-min))))

(defun eerie-goto-buffer-end ()
  "Jump to the end of the current buffer."
  (interactive)
  (eerie--with-recorded-jump
    (eerie--cancel-selection)
    (goto-char (point-max))))

(defun eerie-goto-definition ()
  "Jump to definition using xref and record jump history."
  (interactive)
  (eerie--with-recorded-jump
    (eerie-find-ref)))

;;; Clipboards

(defun eerie-clipboard-yank ()
  "Yank system clipboard."
  (interactive)
  (call-interactively #'clipboard-yank))

(defun eerie-clipboard-kill ()
  "Kill to system clipboard."
  (interactive)
  (call-interactively #'clipboard-kill-region))

(defun eerie-clipboard-save ()
  "Save to system clipboard."
  (interactive)
  (call-interactively #'clipboard-kill-ring-save))

(defun eerie-save ()
  "Copy, like command `kill-ring-save'.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (eerie--with-selection-fallback
   (let ((select-enable-clipboard eerie-use-clipboard))
     (eerie--prepare-region-for-kill)
     (eerie--execute-kbd-macro eerie--kbd-kill-ring-save))))

(defun eerie-save-append ()
  "Copy, like command `kill-ring-save' but append to latest kill.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (eerie--prepare-region-for-kill)
    (let ((s (buffer-substring-no-properties (region-beginning) (region-end))))
      (kill-append (eerie--prepare-string-for-kill-append s) nil)
      (deactivate-mark t))))

(defun eerie-save-empty ()
  "Copy an empty string, can be used with `eerie-save-append' or `eerie-kill-append'."
  (interactive)
  (kill-new ""))

(defun eerie-save-char ()
  "Copy current char."
  (interactive)
  (when (< (point) (point-max))
    (save-mark-and-excursion
      (goto-char (point))
      (push-mark (1+ (point)) t t)
      (eerie--execute-kbd-macro eerie--kbd-kill-ring-save))))

(defun eerie-yank ()
  "Yank."
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (eerie--execute-kbd-macro eerie--kbd-yank)))

(defun eerie-yank-pop ()
  "Pop yank."
  (interactive)
  (when (eerie--allow-modify-p)
    (eerie--execute-kbd-macro eerie--kbd-yank-pop)))

;;; Quit

(defun eerie-cancel-selection ()
  "Cancel selection.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (eerie--with-selection-fallback
   (eerie--cancel-selection)))

(defun eerie-keyboard-quit ()
  "Keyboard quit."
  (interactive)
  (if (region-active-p)
      (deactivate-mark t)
    (eerie--execute-kbd-macro eerie--kbd-keyboard-quit)))

(defun eerie-quit ()
  "Quit current window or buffer."
  (interactive)
  (if (> (seq-length (window-list (selected-frame))) 1)
      (quit-window)
    (previous-buffer)))

;;; Comment

(defun eerie-comment ()
  "Comment region or comment line."
  (interactive)
  (when (eerie--allow-modify-p)
    (eerie--execute-kbd-macro eerie--kbd-comment)))

;;; Delete Operations

(defun eerie-kill ()
  "Kill region.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (when (eerie--allow-modify-p)
      (eerie--with-selection-fallback
       (cond
        ((equal '(expand . join) (eerie--selection-type))
         (delete-indentation nil (region-beginning) (region-end)))
        (t
         (eerie--prepare-region-for-kill)
         (eerie--execute-kbd-macro eerie--kbd-kill-region)))))))

(defun eerie-kill-append ()
  "Kill region and append to latest kill.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (when (eerie--allow-modify-p)
      (eerie--with-selection-fallback
       (cond
        ((equal '(expand . join) (eerie--selection-type))
         (delete-indentation nil (region-beginning) (region-end)))
        (t
         (eerie--prepare-region-for-kill)
         (let ((s (buffer-substring-no-properties (region-beginning) (region-end))))
           (eerie--delete-region (region-beginning) (region-end))
           (kill-append (eerie--prepare-string-for-kill-append s) nil))))))))

(defun eerie-C-k ()
  "Run command on C-k."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-kill-line))

(defun eerie-kill-whole-line ()
  (interactive)
  (when (eerie--allow-modify-p)
    (eerie--execute-kbd-macro eerie--kbd-kill-whole-line)))

(defun eerie-backspace ()
  "Backward delete one char."
  (interactive)
  (when (eerie--allow-modify-p)
    (call-interactively #'backward-delete-char)))

(defun eerie-C-d ()
  "Run command on C-d."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-delete-char))

(defun eerie-backward-kill-word (arg)
  "Kill characters backward until the beginning of a `eerie-word-thing'.
With argument ARG, do this that many times."
  (interactive "p")
  (eerie-kill-word (- arg)))

(defun eerie-kill-word (arg)
  "Kill characters forward until the end of a `eerie-word-thing'.
With argument ARG, do this that many times."
  (interactive "p")
  (eerie-kill-thing eerie-word-thing arg))

(defun eerie-backward-kill-symbol (arg)
  "Kill characters backward until the beginning of a `eerie-symbol-thing'.
With argument ARG, do this that many times."
  (interactive "p")
  (eerie-kill-symbol (- arg)))

(defun eerie-kill-symbol (arg)
  "Kill characters forward until the end of a `eerie-symbol-thing'.
With argument ARG, do this that many times."
  (interactive "p")
  (eerie-kill-thing eerie-symbol-thing arg))


(defun eerie-kill-thing (thing arg)
  "Kill characters forward until the end of a THING.
With argument ARG, do this that many times."
  (let ((start (point))
        (end (progn (forward-thing thing arg) (point))))
    (condition-case _
        (kill-region start end)
      ((text-read-only buffer-read-only)
       (condition-case err
           (eerie--delete-region start end)
         (t (signal (car err) (cdr err))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PAGE UP&DOWN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-page-up ()
  "Page up."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-scoll-down))

(defun eerie-page-down ()
  "Page down."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-scoll-up))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; PARENTHESIS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-forward-slurp ()
  "Forward slurp sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-forward-slurp))

(defun eerie-backward-slurp ()
  "Backward slurp sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-backward-slurp))

(defun eerie-forward-barf ()
  "Forward barf sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-forward-barf))

(defun eerie-backward-barf ()
  "Backward barf sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-backward-barf))

(defun eerie-raise-sexp ()
  "Raise sexp."
  (interactive)
  (eerie--cancel-selection)
  (let ((bounds (bounds-of-thing-at-point 'sexp)))
    (when bounds
      (goto-char (car bounds))))
  (eerie--execute-kbd-macro eerie--kbd-raise-sexp))

(defun eerie-transpose-sexp ()
  "Transpose sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-transpose-sexp))

(defun eerie-split-sexp ()
  "Split sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-split-sexp))

(defun eerie-join-sexp ()
  "Split sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-join-sexp))

(defun eerie-splice-sexp ()
  "Splice sexp."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-splice-sexp))

(defun eerie-wrap-round ()
  "Wrap round paren."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-wrap-round))

(defun eerie-wrap-square ()
  "Wrap square paren."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-wrap-square))

(defun eerie-wrap-curly ()
  "Wrap curly paren."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-wrap-curly))

(defun eerie-wrap-string ()
  "Wrap string."
  (interactive)
  (eerie--cancel-selection)
  (eerie--execute-kbd-macro eerie--kbd-wrap-string))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; STATE TOGGLE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-insert-exit ()
  "Switch to NORMAL state."
  (interactive)
  (cond
   ((and (eerie-insert-mode-p)
         eerie--multiedit-replay-command)
    (eerie--multiedit-apply-replay))
   ((and (eerie-insert-mode-p)
         (eq eerie--beacon-defining-kbd-macro 'quick))
    (setq eerie--beacon-defining-kbd-macro nil)
    (eerie-beacon-insert-exit))
   ((eerie-insert-mode-p)
    (eerie--switch-state 'normal))))

(defun eerie-temp-normal ()
  "Switch to navigation-only NORMAL state."
  (interactive)
  (when (eerie-motion-mode-p)
    (message "Enter temporary normal mode")
    (setq eerie--temp-normal t)
    (eerie--switch-state 'normal)))

(defun eerie--enter-insert-state ()
  "Switch to INSERT and remember the entry position."
  (eerie--switch-state 'insert)
  (setq-local eerie--insert-pos (point)))

(defun eerie-insert ()
  "Move to the start of selection, switch to INSERT state."
  (interactive)
  (if eerie--temp-normal
      (progn
        (message "Quit temporary normal mode")
        (eerie--switch-state 'motion))
    (if (and eerie--multicursor-active
             (eerie--multiedit-active-p))
        (eerie--multiedit-start-insert-or-append 'insert)
      (eerie--direction-backward)
      (eerie--cancel-selection)
      (eerie--enter-insert-state)
      (when eerie-select-on-insert
        (setq-local eerie--insert-activate-mark t)))))

(defun eerie-append ()
  "Move to the end of selection, switch to INSERT state."
  (interactive)
  (if eerie--temp-normal
      (progn
        (message "Quit temporary normal mode")
        (eerie--switch-state 'motion))
    (if (and eerie--multicursor-active
             (eerie--multiedit-active-p))
        (eerie--multiedit-start-insert-or-append 'append)
      (if (not (region-active-p))
          (when (and eerie-use-cursor-position-hack
                     (< (point) (point-max)))
            (forward-char 1))
        (eerie--direction-forward)
        (eerie--cancel-selection))
      (eerie--enter-insert-state)
      (when eerie-select-on-append
        (setq-local eerie--insert-activate-mark t)))))

(defun eerie-insert-beginning-of-line ()
  "Move to the start of the current line and enter INSERT state."
  (interactive)
  (eerie--cancel-selection)
  (goto-char (line-beginning-position))
  (eerie--enter-insert-state))

(defun eerie-append-end-of-line ()
  "Move to the end of the current line and enter INSERT state."
  (interactive)
  (eerie--cancel-selection)
  (goto-char (line-end-position))
  (eerie--enter-insert-state))

(defun eerie-change ()
  "Kill current selection and switch to INSERT state.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (when (eerie--allow-modify-p)
    (setq this-command #'eerie-change)
    (eerie--with-selection-fallback
     (eerie--delete-region (region-beginning) (region-end))
     (eerie--enter-insert-state)
     (when eerie-select-on-change
       (setq-local eerie--insert-activate-mark t)))))

(defun eerie-change-char ()
  "Delete current char and switch to INSERT state."
  (interactive)
  (when (< (point) (point-max))
    (eerie--execute-kbd-macro eerie--kbd-delete-char)
    (eerie--enter-insert-state)
    (when eerie-select-on-change
      (setq-local eerie--insert-activate-mark t))))

(defun eerie-change-save ()
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (when (and (eerie--allow-modify-p) (region-active-p))
      (kill-region (region-beginning) (region-end))
      (eerie--enter-insert-state)
      (when eerie-select-on-change
        (setq-local eerie--insert-activate-mark t)))))

(defun eerie-replace ()
  "Replace current selection with yank.

This command supports `eerie-selection-command-fallback'."
  (interactive)
  (eerie--with-selection-fallback
   (let ((select-enable-clipboard eerie-use-clipboard))
     (when (eerie--allow-modify-p)
       (when-let* ((s (string-trim-right (current-kill 0 t) "\n")))
         (eerie--delete-region (region-beginning) (region-end))
         (set-marker eerie--replace-start-marker (point))
         (eerie--insert s))))))

(defun eerie-replace-char ()
  "Replace current char with selection."
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (when (< (point) (point-max))
      (when-let* ((s (string-trim-right (current-kill 0 t) "\n")))
        (eerie--delete-region (point) (1+ (point)))
        (set-marker eerie--replace-start-marker (point))
        (eerie--insert s)))))

(defun eerie-replace-save ()
  (interactive)
  (let ((select-enable-clipboard eerie-use-clipboard))
    (when (eerie--allow-modify-p)
      (when-let* ((curr (pop kill-ring-yank-pointer)))
        (let ((s (string-trim-right curr "\n")))
          (setq kill-ring kill-ring-yank-pointer)
          (if (region-active-p)
              (let ((old (save-mark-and-excursion
                           (eerie--prepare-region-for-kill)
                           (buffer-substring-no-properties (region-beginning) (region-end)))))
                (progn
                  (eerie--delete-region (region-beginning) (region-end))
                  (set-marker eerie--replace-start-marker (point))
                  (eerie--insert s)
                  (kill-new old)))
            (set-marker eerie--replace-start-marker (point))
            (eerie--insert s)))))))

(defun eerie-replace-pop ()
  "Like `yank-pop', but for `eerie-replace'.

If this command is called after `eerie-replace',
`eerie-replace-char', `eerie-replace-save', or itself, replace the
previous replacement with the next item in the `kill-ring'.

Unlike `yank-pop', this command does not rotate the `kill-ring'.
For that, see the command `rotate-yank-pointer'.

For custom commands, see also the user option
`eerie-replace-pop-command-start-indexes'."
  (interactive "*")
  (unless kill-ring (user-error "Can't replace; kill ring is empty"))
  (let ((select-enable-clipboard eerie-use-clipboard))
    (when (eerie--allow-modify-p)
      (setq eerie--replace-pop-index
            (cond
             ((eq last-command 'eerie-replace-pop) (1+ eerie--replace-pop-index))
             ((alist-get last-command eerie-replace-pop-command-start-indexes))
             (t (user-error "Can only run `eerie-replace-pop' after itself or a command in `eerie-replace-pop-command-start-indexes'"))))
      (when (>= eerie--replace-pop-index (length kill-ring))
        (setq eerie--replace-pop-index 0)
        (message "`eerie-replace-pop': Reached end of kill ring"))
      (let ((txt (string-trim-right (current-kill eerie--replace-pop-index t)
                                    "\n")))
        (eerie--delete-region eerie--replace-start-marker (point))
        (set-marker eerie--replace-start-marker (point))
        (eerie--insert txt))))
  (setq this-command 'eerie-replace-pop))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; CHAR MOVEMENT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-left ()
  "Move to left.

Will cancel all other selection, except char selection. "
  (interactive)
  (when (and (region-active-p)
             (not (equal '(expand . char) (eerie--selection-type))))
    (eerie-cancel-selection))
  (when (> (point) (line-beginning-position))
    (backward-char 1)))

(defun eerie-right ()
  "Move to right.

Will cancel all other selection, except char selection. "
  (interactive)
  (let ((ra (region-active-p)))
    (when (and ra
           (not (equal '(expand . char) (eerie--selection-type))))
      (eerie-cancel-selection))
    (when (or (not eerie-use-cursor-position-hack)
              (not ra)
              (equal '(expand . char) (eerie--selection-type)))
      (when (< (point) (line-end-position))
        (forward-char 1)))))

(defun eerie-left-expand ()
  "Activate char selection, then move left."
  (interactive)
  (if (region-active-p)
      (thread-first
        (eerie--make-selection '(expand . char) (mark) (point))
        (eerie--select t))
    (when eerie-use-cursor-position-hack
      (forward-char 1))
    (thread-first
      (eerie--make-selection '(expand . char) (point) (point))
      (eerie--select t)))
  (when (> (point) (line-beginning-position))
    (backward-char 1)))

(defun eerie-right-expand ()
  "Activate char selection, then move right."
  (interactive)
  (if (region-active-p)
      (thread-first
        (eerie--make-selection '(expand . char) (mark) (point))
        (eerie--select t))
    (thread-first
      (eerie--make-selection '(expand . char) (point) (point))
      (eerie--select t)))
  (when (< (point) (line-end-position))
    (forward-char 1)))

(defun eerie-goto-line-end ()
  "Move to the end of the current line."
  (interactive)
  (eerie--cancel-selection)
  (goto-char (line-end-position)))

(defun eerie--move-lines (count)
  "Move COUNT wrapped screen lines without routing back through key bindings."
  (let ((origin-screen-column
         (- (current-column)
            (save-excursion
              (beginning-of-visual-line)
              (current-column)))))
    (vertical-motion count)
    (move-to-column
     (+ origin-screen-column
        (save-excursion
          (beginning-of-visual-line)
          (current-column))))))

(defun eerie-prev (arg)
  "Move to the previous line.

Will cancel all other selection, except char selection.

Use with universal argument to move to the first line of buffer.
Use with numeric argument to move multiple lines at once."
  (interactive "P")
  (unless (equal (eerie--selection-type) '(expand . char))
    (eerie--cancel-selection))
  (cond
   ((eerie--with-universal-argument-p arg)
    (goto-char (point-min)))
   (t
    (eerie--move-lines (- (prefix-numeric-value arg))))))

(defun eerie-next (arg)
  "Move to the next line.

Will cancel all other selection, except char selection.

Use with universal argument to move to the last line of buffer.
Use with numeric argument to move multiple lines at once."
  (interactive "P")
  (unless (equal (eerie--selection-type) '(expand . char))
    (eerie--cancel-selection))
  (cond
   ((eerie--with-universal-argument-p arg)
    (goto-char (point-max)))
   (t
    (eerie--move-lines (prefix-numeric-value arg)))))

(defun eerie-prev-expand (arg)
  "Activate char selection, then move to the previous line.

See `eerie-prev-line' for how prefix arguments work."
  (interactive "P")
  (if (region-active-p)
      (thread-first
        (eerie--make-selection '(expand . char) (mark) (point))
        (eerie--select t))
    (thread-first
      (eerie--make-selection '(expand . char) (point) (point))
      (eerie--select t)))
  (cond
   ((eerie--with-universal-argument-p arg)
    (goto-char (point-min)))
   (t
    (eerie--move-lines (- (prefix-numeric-value arg))))))

(defun eerie-next-expand (arg)
  "Activate char selection, then move to the next line.

See `eerie-next-line' for how prefix arguments work."
  (interactive "P")
  (if (region-active-p)
      (thread-first
        (eerie--make-selection '(expand . char) (mark) (point))
        (eerie--select t))
    (thread-first
      (eerie--make-selection '(expand . char) (point) (point))
      (eerie--select t)))
  (cond
   ((eerie--with-universal-argument-p arg)
    (goto-char (point-max)))
   (t
    (eerie--move-lines (prefix-numeric-value arg)))))

(defun eerie-mark-thing (thing type &optional backward regexp-format)
  "Make expandable selection of THING, with TYPE and forward/BACKWARD direction.

THING is a symbol usable by `forward-thing', which see.

TYPE is a symbol. Usual values are `word' or `line'.

The selection will be made in the \\='forward\\=' direction unless BACKWARD is
non-nil.

When REGEXP-FORMAT is non-nil and a string, the content of the selection will be
quoted to regexp, then pushed into `regexp-search-ring' which will be read by
`eerie-search' and other commands. In this case, REGEXP-FORMAT is used as a
format-string to format the regexp-quoted selection content (which is passed as
a string to `format'). Further matches of this formatted search will be
highlighted in the buffer."
  (let* ((bounds (bounds-of-thing-at-point thing))
         (beg (car bounds))
         (end (cdr bounds)))
    (when beg
      (thread-first
        (eerie--make-selection (cons 'expand type) beg end)
        (eerie--select t backward))
      (when (stringp regexp-format)
        (let ((search (format regexp-format (regexp-quote (buffer-substring-no-properties beg end)))))
          (eerie--push-search search)
          (eerie--highlight-regexp-in-buffer search))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; WORD/SYMBOL MOVEMENT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-mark-word (n)
  "Mark current word under cursor.

A expandable word selection will be created. `eerie-next-word' and
`eerie-back-word' can be used for expanding.

The content of selection will be quoted to regexp, then pushed into
`regexp-search-ring' which be read by `eerie-search' and other commands.

This command will also provide highlighting for same occurs.

Use negative argument to create a backward selection."
  (interactive "p")
  (eerie-mark-thing eerie-word-thing 'word (< n 0) "\\<%s\\>"))

(defun eerie-mark-symbol (n)
  "Mark current symbol under cursor.

This command works similar to `eerie-mark-word'."
  (interactive "p")
  (eerie-mark-thing eerie-symbol-thing 'symbol (< n 0) "\\_<%s\\_>"))

(defun eerie--forward-thing-1 (thing)
  (let ((pos (point)))
    (forward-thing thing 1)
    (when (not (= pos (point)))
      (eerie--hack-cursor-pos (point)))))

(defun eerie--backward-thing-1 (thing)
  (let ((pos (point)))
    (forward-thing thing -1)
    (when (not (= pos (point)))
      (point))))

(defun eerie--fix-thing-selection-mark (thing pos mark include-syntax)
  "Return new mark for a selection of THING.
This will shrink the word selection only contains
those in INCLUDE-SYNTAX."
  (let ((backward (> mark pos)))
    (save-mark-and-excursion
      (goto-char
       (if backward pos
         ;; Point must be before the end of the word to get the bounds correctly
         (1- pos)))
      (let* ((bounds (or (bounds-of-thing-at-point thing) (cons mark mark)))
             (m (if backward
                    (min mark (cdr bounds))
                  (max mark (car bounds)))))
        (save-mark-and-excursion
          (goto-char m)
          (if backward
              (skip-syntax-forward include-syntax mark)
            (skip-syntax-backward include-syntax mark))
          (point))))))

(defun eerie-next-thing (thing type n &optional include-syntax)
  "Create non-expandable selection of TYPE to the end of the next Nth THING.

If N is negative, select to the beginning of the previous Nth thing instead."
  (unless (equal type (cdr (eerie--selection-type)))
    (eerie--cancel-selection))
  (unless include-syntax
    (setq include-syntax
          (let ((thing-include-syntax
                 (or (alist-get thing eerie-next-thing-include-syntax)
                     '("" ""))))
            (if (> n 0)
                (car thing-include-syntax)
              (cadr thing-include-syntax)))))
  (let* ((expand (equal (cons 'expand type) (eerie--selection-type)))
         (_ (when expand
              (if (< n 0) (eerie--direction-backward)
                (eerie--direction-forward))))
         (new-type (if expand (cons 'expand type) (cons 'select type)))
         (m (point))
         (p (save-mark-and-excursion
              (forward-thing thing n)
              (unless (= (point) m)
                (point)))))
    (when p
      (thread-first
        (eerie--make-selection
         new-type
         (eerie--fix-thing-selection-mark thing p m include-syntax)
         p
         expand)
        (eerie--select t))
      (eerie--maybe-highlight-num-positions
       (cons (apply-partially #'eerie--backward-thing-1 thing)
             (apply-partially #'eerie--forward-thing-1 thing))))))

(defun eerie-next-word (n)
  "Select to the end of the next Nth word.

A non-expandable, word selection will be created.

To select continuous words, use following approaches:

1. start the selection with `eerie-mark-word'.

2. use prefix digit arguments.

3. use `eerie-expand' after this command.
"
  (interactive "p")
  (eerie-next-thing eerie-word-thing 'word n))

(defun eerie-next-symbol (n)
  "Select to the end of the next Nth symbol.

A non-expandable, word selection will be created.
There's no symbol selection type in Eerie.

To select continuous symbols, use following approaches:

1. start the selection with `eerie-mark-symbol'.

2. use prefix digit arguments.

3. use `eerie-expand' after this command."
  (interactive "p")
  (eerie-next-thing eerie-symbol-thing 'symbol n))

(defun eerie-back-word (n)
  "Select to the beginning the previous Nth word.

A non-expandable word selection will be created.
This command works similar to `eerie-next-word'."
  (interactive "p")
  (eerie-next-thing eerie-word-thing 'word (- n)))

(defun eerie-back-symbol (n)
  "Select to the beginning the previous Nth symbol.

A non-expandable word selection will be created.
This command works similar to `eerie-next-symbol'."
  (interactive "p")
  (eerie-next-thing eerie-symbol-thing 'symbol (- n)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; LINE SELECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--forward-line-1 ()
  (let ((orig (point)))
    (forward-line 1)
    (if eerie--expanding-p
        (progn
          (goto-char (line-end-position))
          (line-end-position))
      (when (< orig (line-beginning-position))
        (line-beginning-position)))))

(defun eerie--backward-line-1 ()
  (forward-line -1)
  (line-beginning-position))

(defun eerie-line (n &optional expand)
  "Select the current line, eol is not included.

Create selection with type (expand . line).
For the selection with type (expand . line), expand it by line.
For the selection with other types, cancel it.

Prefix:
numeric, repeat times.
"
  (interactive "p")
  (let* ((cancel-sel (not (or expand (equal '(expand . line) (eerie--selection-type)))))
         (backward (unless cancel-sel (eerie--direction-backward-p)))
         (orig (if cancel-sel (point) (mark t)))
         (n (if backward
                (- n)
              n))
         (forward (> n 0)))
    (cond
     ((not cancel-sel)
      (let (p)
        (save-mark-and-excursion
          (forward-line n)
          (goto-char
           (if forward
               (setq p (line-end-position))
             (setq p (line-beginning-position)))))
        (thread-first
          (eerie--make-selection '(expand . line) orig p expand)
          (eerie--select t))
        (eerie--maybe-highlight-num-positions '(eerie--backward-line-1 . eerie--forward-line-1))))
     (t
      (let ((m (if forward
                   (line-beginning-position)
                 (line-end-position)))
            (p (save-mark-and-excursion
                 (if forward
                     (progn
                       (unless (= n 1)
                         (forward-line (1- n)))
                       (line-end-position))
                   (progn
                     (forward-line (1+ n))
                     (when (eerie--empty-line-p)
                       (backward-char 1))
                     (line-beginning-position))))))
        (thread-first
          (eerie--make-selection '(expand . line) m p expand)
          (eerie--select t))
        (eerie--maybe-highlight-num-positions '(eerie--backward-line-1 . eerie--forward-line-1)))))))

(defun eerie-line-expand (n)
  "Like `eerie-line', but always expand."
  (interactive "p")
  (eerie-line n t))

(defun eerie-goto-line ()
  "Goto line, recenter and select that line.

This command will expand line selection."
  (interactive)
  (eerie--with-recorded-jump
    (let* ((rbeg (when (use-region-p) (region-beginning)))
           (rend (when (use-region-p) (region-end)))
           (expand (equal '(expand . line) (eerie--selection-type)))
           (orig-p (point))
           (beg-end (save-mark-and-excursion
                      (if eerie-goto-line-function
                          (call-interactively eerie-goto-line-function)
                        (eerie--execute-kbd-macro eerie--kbd-goto-line))
                      (cons (line-beginning-position)
                            (line-end-position))))
           (beg (car beg-end))
           (end (cdr beg-end)))
      (thread-first
        (eerie--make-selection '(expand . line)
                              (if (and expand rbeg) (min rbeg beg) beg)
                              (if (and expand rend) (max rend end) end))
        (eerie--select t (> orig-p beg)))
      (recenter))))

;; visual line versions
(defun eerie--visual-block-move-lines (n)
  "Move rectangle point by N lines without dropping the goal column."
  (let ((column (current-column)))
    (forward-line n)
    (move-to-column column)))

(defun eerie--visual-line-range ()
  "Return the current logical line range as a cons cell."
  (cons (line-beginning-position)
        (line-end-position)))

(defun eerie--visual-line-beginning-position ()
  (car (eerie--visual-line-range)))

(defun eerie--visual-line-end-position ()
  (cdr (eerie--visual-line-range)))

(defun eerie--visual-line-apply-selection (current-range)
  "Apply linewise VISUAL selection from the anchor to CURRENT-RANGE."
  (let* ((anchor (or eerie--visual-line-anchor current-range))
         (anchor-beg (car anchor))
         (anchor-end (cdr anchor))
         (current-beg (car current-range))
         (current-end (cdr current-range))
         (beg (min anchor-beg current-beg))
         (end (max anchor-end current-end))
         (backward (< current-beg anchor-beg)))
    (thread-first
      (eerie--make-selection '(expand . line) beg end)
      (eerie--select t backward))
    (eerie--maybe-highlight-num-positions
     '(eerie--backward-visual-line-1 . eerie--forward-visual-line-1))))

(defun eerie--forward-visual-line-1 ()
  (let ((orig (point)))
    (forward-line 1)
    (if eerie--expanding-p
        (progn
          (goto-char (eerie--visual-line-end-position))
          (eerie--visual-line-end-position))
      (when (< orig (eerie--visual-line-beginning-position))
        (eerie--visual-line-beginning-position)))))

(defun eerie--backward-visual-line-1 ()
  (forward-line -1)
  (eerie--visual-line-beginning-position))

(defun eerie-visual-line (n &optional expand)
  "Select the current visual line, eol is not included.

Create selection with type (expand . line).
For the selection with type (expand . line), expand it by line.
For the selection with other types, cancel it.

Prefix:
numeric, repeat times.
"
  (interactive "p")
  (let* ((active-line-visual
          (and (equal '(expand . line) (eerie--selection-type))
               (eq eerie--visual-type 'line)
               eerie--visual-line-anchor
               (region-active-p)))
         (offset (if active-line-visual
                     n
                   (if (> n 0)
                       (1- n)
                     (1+ n)))))
    (unless active-line-visual
      (setq-local eerie--visual-line-anchor (eerie--visual-line-range)))
    (let ((target-range
           (save-mark-and-excursion
             (forward-line offset)
             (eerie--visual-line-range))))
      (eerie--visual-line-apply-selection target-range))))

(defun eerie-visual-line-expand (n)
  "Like `eerie-line', but always expand."
  (interactive "p")
  (eerie-visual-line n t))

(defun eerie--visual-select-char ()
  "Create a charwise selection anchored at point."
  (thread-first
    (eerie--make-selection '(expand . char) (point) (point))
    (eerie--select t)))

(defun eerie--visual-target-state ()
  "Return the visual-like state for the current session."
  (if eerie--multicursor-active
      'multicursor-visual
    'visual))

(defun eerie--multicursor-help-keymap ()
  "Return the persistent help keymap for the current multicursor state."
  (let ((keymap (make-sparse-keymap))
        (visual-like (memq (eerie--current-state) '(visual multicursor-visual))))
    (dolist (binding
             (append
              '((?v . eerie-visual-start)
                (?V . eerie-visual-line-start)
                ([?\C-v] . eerie-visual-block-start)
                (?f . eerie-jump-char)
                (?w . eerie-jump-word-occurrence)
                ([escape] . eerie-multicursor-cancel))
              (when visual-like
                '((?. . eerie-multicursor-match-next)
                  (?, . eerie-multicursor-unmatch-last)
                  (?- . eerie-multicursor-skip-match)
                  (?d . eerie-visual-delete)
                  (?c . eerie-visual-change)
                  (?i . eerie-visual-inner-of-thing)
                  (?a . eerie-visual-bounds-of-thing)
                  (?y . eerie-visual-yank)))))
      (define-key keymap
                  (if (vectorp (car binding))
                      (car binding)
                    (vector (car binding)))
                  (cdr binding)))
    keymap))

(defun eerie--which-key-show-keymap (title keymap)
  "Show KEYMAP with TITLE through native `which-key'."
  (when (and (featurep 'which-key)
             (fboundp 'which-key--show-keymap)
             (keymapp keymap)
             (not noninteractive))
    (which-key--show-keymap title keymap nil nil t)))

(defun eerie--which-key-hide-popup ()
  "Hide the native `which-key' popup."
  (when (and (featurep 'which-key)
             (fboundp 'which-key--hide-popup)
             (not noninteractive))
    (which-key--hide-popup)))

(defun eerie--multicursor-display-menu ()
  "Refresh the persistent multicursor help popup."
  (when eerie--multicursor-active
    (eerie--which-key-show-keymap
     "Eerie multicursor"
     (eerie--multicursor-help-keymap))))

(defun eerie--multicursor-activate ()
  "Activate multicursor replay plumbing in the current buffer."
  (setq-local eerie--multicursor-active t
              eerie--multicursor-replaying nil)
  (add-hook 'pre-command-hook #'eerie--multicursor-pre-command nil t)
  (add-hook 'post-command-hook #'eerie--multicursor-post-command nil t)
  (advice-add 'read-key :around #'eerie--multicursor-around-read-key)
  (advice-add 'read-char :around #'eerie--multicursor-around-read-char)
  (advice-add 'read-from-minibuffer :around
              #'eerie--multicursor-around-read-from-minibuffer))

(defun eerie-multicursor-start ()
  "Enter the canonical multicursor mode from NORMAL."
  (interactive)
  (eerie--multiedit-reset-state)
  (eerie--multicursor-reset-state)
  (when (region-active-p)
    (eerie--cancel-selection))
  (eerie--multicursor-activate)
  (eerie--switch-state 'multicursor)
  (eerie--multicursor-display-menu))

(defun eerie-visual-enter-multicursor ()
  "Enter the canonical multicursor session from the current VISUAL selection."
  (interactive)
  (unless (eerie--multiedit-valid-seed-p)
    (user-error "Multicursor from visual requires an active charwise visual selection"))
  (let ((range (eerie--multiedit-current-range))
        (backward (eerie--direction-backward-p)))
    (eerie--multiedit-reset-state)
    (eerie--multicursor-reset-state)
    (eerie--multicursor-activate)
    (eerie--switch-state 'multicursor-visual)
    (thread-first
      (eerie--make-selection '(expand . char) (car range) (cdr range))
      (eerie--select t backward))
    (setq-local eerie--visual-type 'char
                eerie--visual-line-anchor nil)
    (eerie--multiedit-start-session)
    (eerie--multicursor-display-menu)))

(defun eerie-visual-start ()
  "Enter charwise VISUAL state."
  (interactive)
  (unless (region-active-p)
    (eerie--visual-select-char))
  (setq-local eerie--visual-type 'char
              eerie--visual-line-anchor nil)
  (eerie--switch-state (eerie--visual-target-state)))

(defun eerie--visual-line-start-basic ()
  "Enter linewise VISUAL state without reading visible-line hints."
  (setq-local eerie--visual-type 'line
              eerie--visual-line-anchor (eerie--visual-line-range))
  (eerie--switch-state (eerie--visual-target-state))
  (eerie-visual-line 1))

(defun eerie-visual-line-start ()
  "Enter linewise VISUAL state and offer visible line hints."
  (interactive)
  (eerie--visual-line-start-basic)
  (when (eq (eerie--jump-loop
             (lambda (dir)
               (eerie--jump-line-candidates
                dir
                (eerie--visual-line-range)))
             #'eerie--visual-line-jump-action
             "line")
            'escape)
    (eerie-visual-exit)))

(defun eerie-visual-block-start ()
  "Enter block VISUAL state using `rectangle-mark-mode'."
  (interactive)
  (unless (region-active-p)
    (push-mark (min (1+ (point)) (point-max)) t t))
  (rectangle-mark-mode 1)
  (setq-local eerie--visual-type 'block
              eerie--visual-line-anchor nil)
  (eerie--switch-state (eerie--visual-target-state)))

(defun eerie--multiedit-active-p ()
  "Return non-nil when a multi-edit session is active."
  (and eerie--multiedit-seed
       eerie--multiedit-primary))

(defun eerie--multiedit-valid-seed-p ()
  "Return non-nil when the current region can seed multi-edit."
  (and (memq (eerie--current-state) '(visual multicursor-visual))
       (eq eerie--visual-type 'char)
       (region-active-p)
       (< (region-beginning) (region-end))))

(defun eerie--multiedit-current-range ()
  "Return the current active region range."
  (cons (region-beginning) (region-end)))

(defun eerie--multiedit-range-equal-p (left right)
  "Return non-nil when LEFT and RIGHT have the same bounds."
  (and left
       right
       (= (car left) (car right))
       (= (cdr left) (cdr right))))

(defun eerie--multiedit-target-member-p (range)
  "Return non-nil when RANGE already belongs to the multi-edit session."
  (seq-some (lambda (target)
              (eerie--multiedit-range-equal-p target range))
            eerie--multiedit-targets))

(defun eerie--multiedit-overlap-p (left right)
  "Return non-nil when LEFT and RIGHT overlap."
  (and (< (car left) (cdr right))
       (< (car right) (cdr left))))

(defun eerie--multiedit-normalize-targets (targets)
  "Return TARGETS without duplicates, erroring on partial overlaps."
  (let (result)
    (dolist (target targets)
      (unless (seq-some (lambda (existing)
                          (eerie--multiedit-range-equal-p existing target))
                        result)
        (when (seq-some (lambda (existing)
                          (eerie--multiedit-overlap-p existing target))
                        result)
          (user-error "Multi-edit targets cannot overlap"))
        (push target result)))
    (nreverse result)))

(defun eerie--multiedit-sorted-targets (&optional reverse)
  "Return the current multi-edit targets sorted by start position.

When REVERSE is non-nil, return them in reverse order."
  (let ((targets
         (sort (copy-sequence eerie--multiedit-targets)
               (lambda (left right)
                 (< (car left) (car right))))))
    (if reverse
        (nreverse targets)
      targets)))

(defun eerie--multiedit-remove-overlays ()
  "Remove all secondary multi-edit overlays."
  (mapc #'delete-overlay eerie--multiedit-overlays)
  (setq-local eerie--multiedit-overlays nil))

(defun eerie--multiedit-reset-state ()
  "Reset all multi-edit session state in the current buffer."
  (eerie--multiedit-remove-overlays)
  (remove-hook 'post-command-hook #'eerie--multiedit-post-command t)
  (setq-local eerie--multiedit-seed nil
              eerie--multiedit-direction 'forward
              eerie--multiedit-targets nil
              eerie--multiedit-primary nil
              eerie--multiedit-search-head nil
              eerie--multiedit-backward nil
              eerie--multiedit-replay-markers nil
              eerie--multiedit-replay-command nil))

(defun eerie--multiedit-deactivate ()
  "Deactivate multi-edit while keeping the current selection intact."
  (when (eerie--multiedit-active-p)
    (eerie--multiedit-reset-state)))

(defun eerie--multiedit-render-overlays ()
  "Render secondary multi-edit targets."
  (eerie--multiedit-remove-overlays)
  (dolist (range eerie--multiedit-targets)
    (unless (and (eerie--multiedit-range-equal-p range eerie--multiedit-primary)
                 (region-active-p))
      (let ((ov (make-overlay (car range) (cdr range) nil t t)))
        (overlay-put ov 'face 'eerie-beacon-fake-selection)
        (overlay-put ov 'priority 1)
        (overlay-put ov 'eerie-multiedit t)
        (push ov eerie--multiedit-overlays))))
  (setq-local eerie--multiedit-overlays (nreverse eerie--multiedit-overlays)))

(defun eerie--multiedit-set-targets (targets primary)
  "Replace the current multi-edit TARGETS and select PRIMARY."
  (setq-local eerie--multiedit-targets (eerie--multiedit-normalize-targets targets))
  (unless (seq-some (lambda (target)
                      (eerie--multiedit-range-equal-p target primary))
                    eerie--multiedit-targets)
    (user-error "Primary multi-edit target disappeared"))
  (eerie--multiedit-apply-target primary))

(defun eerie--multiedit-primary-text ()
  "Return the current primary multi-edit text."
  (buffer-substring-no-properties (car eerie--multiedit-primary)
                                  (cdr eerie--multiedit-primary)))

(defun eerie--multiedit-enter-insert-state-at-point (command)
  "Enter INSERT at point for multi-edit COMMAND."
  (when (region-active-p)
    (eerie--cancel-selection))
  (eerie--enter-insert-state)
  (when (if (eq command 'append)
            eerie-select-on-append
          eerie-select-on-insert)
    (setq-local eerie--insert-activate-mark t)))

(defun eerie--multiedit-start-replay (command markers)
  "Start a multi-edit replay session for COMMAND using MARKERS."
  (setq-local eerie--multiedit-replay-markers markers
              eerie--multiedit-replay-command command)
  (eerie--multiedit-enter-insert-state-at-point command)
  (setq last-kbd-macro nil)
  (call-interactively #'kmacro-start-macro))

(defun eerie--multiedit-position-for-target (target command)
  "Return the insert position for TARGET under multi-edit COMMAND."
  (funcall (if (eq command 'append) #'cdr #'car) target))

(defun eerie--replay-target-goto (target)
  "Move point to replay TARGET.

TARGET is either a marker or a cons cell of the form
\(MARKER . COLUMN).  Return non-nil when TARGET is valid."
  (pcase target
    ((pred markerp)
     (when (marker-buffer target)
       (goto-char target)
       t))
    (`(,marker . ,column)
     (when (and (markerp marker)
                (marker-buffer marker))
       (goto-char marker)
       (move-to-column column t)
       t))
    (_ nil)))

(defun eerie--multiedit-delete-all-targets ()
  "Delete every current multi-edit target."
  (let ((primary-marker (copy-marker (car eerie--multiedit-primary)))
        (primary-text (eerie--multiedit-primary-text))
        (targets (eerie--multiedit-sorted-targets t)))
    (eerie--multiedit-reset-state)
    (eerie--wrap-collapse-undo
      (dolist (target targets)
        (eerie--delete-region (car target) (cdr target))))
    (kill-new primary-text)
    (when (region-active-p)
      (eerie--cancel-selection))
    (when eerie--multicursor-active
      (eerie--multicursor-reset-state))
    (goto-char primary-marker)
    (eerie--switch-state 'normal)))

(defun eerie--multiedit-start-change ()
  "Delete every current multi-edit target and start replay-backed INSERT."
  (let* ((sorted-targets (eerie--multiedit-sorted-targets))
         (primary-range eerie--multiedit-primary)
         (primary-marker (copy-marker (car primary-range)))
         (secondary-markers
          (delq nil
                (mapcar (lambda (target)
                          (unless (eerie--multiedit-range-equal-p target primary-range)
                            (copy-marker (car target))))
                        sorted-targets)))
         (primary-text (eerie--multiedit-primary-text)))
    (eerie--multiedit-reset-state)
    (eerie--wrap-collapse-undo
      (dolist (target (reverse sorted-targets))
        (eerie--delete-region (car target) (cdr target))))
    (kill-new primary-text)
    (goto-char primary-marker)
    (eerie--multiedit-start-replay 'insert secondary-markers)))

(defun eerie--multiedit-start-insert-or-append (command)
  "Start multi-edit replay for COMMAND without deleting the targets."
  (let* ((sorted-targets (eerie--multiedit-sorted-targets))
         (primary-range eerie--multiedit-primary)
         (primary-position
          (eerie--multiedit-position-for-target primary-range command))
         (secondary-markers
          (delq nil
                (mapcar (lambda (target)
                          (unless (eerie--multiedit-range-equal-p target primary-range)
                            (copy-marker
                             (eerie--multiedit-position-for-target target command))))
                        sorted-targets))))
    (eerie--multiedit-reset-state)
    (goto-char primary-position)
    (eerie--multiedit-start-replay command secondary-markers)))

(defun eerie--multiedit-apply-replay ()
  "Replay the last multi-edit insert or change at all secondary markers."
  (let* ((markers eerie--multiedit-replay-markers)
         (command eerie--multiedit-replay-command)
         (inserted-text (buffer-substring-no-properties eerie--insert-pos (point))))
    (setq-local eerie--multiedit-replay-markers nil
                eerie--multiedit-replay-command nil)
    (when defining-kbd-macro
      (end-kbd-macro))
    (let ((use-macro (and last-kbd-macro
                          (> (length last-kbd-macro) 0))))
      (eerie--switch-state 'normal)
      (eerie--wrap-collapse-undo
        (save-mark-and-excursion
          (dolist (marker markers)
            (when (eerie--replay-target-goto marker)
              (if use-macro
                  (progn
                    (eerie--multiedit-enter-insert-state-at-point command)
                    (call-interactively #'kmacro-call-macro)
                    (eerie-escape-or-normal-modal))
                (eerie--insert inserted-text)))))))
    (when eerie--multicursor-active
      (eerie--multicursor-reset-state))
    (eerie--switch-state 'normal)))

(defun eerie--multiedit-apply-target (range)
  "Select RANGE as the current active multi-edit target."
  (setq-local eerie--multiedit-primary range
              eerie--multiedit-search-head range)
  (thread-first
    (eerie--make-selection '(expand . char) (car range) (cdr range))
    (eerie--select t eerie--multiedit-backward))
  (setq-local eerie--visual-type 'char)
  (eerie--multiedit-render-overlays)
  (eerie--ensure-visible))

(defun eerie--multiedit-start-session ()
  "Start a multi-edit session from the current charwise VISUAL selection."
  (unless (eerie--multiedit-valid-seed-p)
    (user-error "Multi-edit requires an active charwise visual selection"))
  (let ((range (eerie--multiedit-current-range)))
    (setq-local eerie--multiedit-seed
                (buffer-substring-no-properties (car range) (cdr range))
                eerie--multiedit-direction 'forward
                eerie--multiedit-targets (list range)
                eerie--multiedit-primary range
                eerie--multiedit-search-head range
                eerie--multiedit-backward (eerie--direction-backward-p))
    (add-hook 'post-command-hook #'eerie--multiedit-post-command nil t)
    (eerie--multiedit-render-overlays)))

(defun eerie--multiedit-ensure-session ()
  "Ensure there is an active multi-edit session."
  (unless (eerie--multiedit-active-p)
    (eerie--multiedit-start-session)))

(defun eerie--multiedit-find-next-match (&optional direction)
  "Return the next unselected match in DIRECTION.

When DIRECTION is nil, use the current multi-edit direction."
  (let ((case-fold-search nil)
        (direction (or direction eerie--multiedit-direction))
        (regexp (regexp-quote eerie--multiedit-seed)))
    (save-excursion
      (goto-char (if (eq direction 'backward)
                     (car eerie--multiedit-search-head)
                   (cdr eerie--multiedit-search-head)))
      (catch 'match
        (while (if (eq direction 'backward)
                   (re-search-backward regexp nil t)
                 (re-search-forward regexp nil t))
          (let ((range (cons (match-beginning 0) (match-end 0))))
            (unless (eerie--multiedit-target-member-p range)
              (throw 'match range))))
        nil))))

(defun eerie--visual-block-column-bounds ()
  "Return the ordered column bounds of the active block selection."
  (let ((point-column (current-column))
        (mark-column (save-excursion
                       (goto-char (mark t))
                       (current-column))))
    (cons (min point-column mark-column)
          (max point-column mark-column))))

(defun eerie--visual-block-replay-targets (command)
  "Return replay targets for the active block selection under COMMAND.

COMMAND is either `insert' or `append'.  The return value is a cons
cell of the form \(PRIMARY . SECONDARY), where PRIMARY is the target
for the current line and SECONDARY is the list of other line targets."
  (let* ((column-bounds (eerie--visual-block-column-bounds))
         (target-column (if (eq command 'append)
                            (cdr column-bounds)
                          (car column-bounds)))
         (primary-line (line-number-at-pos (point)))
         primary
         secondary)
    (save-excursion
      (apply-on-rectangle
       (lambda (_startcol _endcol)
         (let ((target (cons (copy-marker (line-beginning-position))
                             target-column)))
           (if (= (line-number-at-pos (point)) primary-line)
               (setq primary target)
             (push target secondary))))
       (region-beginning)
       (region-end)))
    (unless primary
      (user-error "Block insert target disappeared"))
    (cons primary (nreverse secondary))))

(defun eerie--clear-visual-region ()
  "Clear the active VISUAL region and rectangle state."
  (when (bound-and-true-p rectangle-mark-mode)
    (rectangle-mark-mode -1))
  (when (region-active-p)
    (eerie--cancel-selection)))

(defun eerie--finish-visual-exit (state)
  "Clear the active VISUAL state and switch to STATE."
  (eerie--clear-visual-region)
  (eerie--switch-state state))

(defun eerie--visual-block-start-replay (command)
  "Start block VISUAL replay-backed insert for COMMAND.

COMMAND is either `insert' or `append'."
  (pcase-let ((`(,primary . ,secondary)
               (eerie--visual-block-replay-targets command)))
    (eerie--clear-visual-region)
    (unless (eerie--replay-target-goto primary)
      (user-error "Block insert target disappeared"))
    (eerie--multiedit-start-replay command secondary)))

(defun eerie--multiedit-post-command ()
  "Deactivate multi-edit after unsupported commands."
  (unless (or (not (eerie--multiedit-active-p))
              (memq this-command
                    '(eerie-multiedit-match-next
                      eerie-multiedit-unmatch-last
                      eerie-multiedit-skip-match
                      eerie-multiedit-reverse-direction
                      eerie-visual-enter-multicursor
                      eerie-multicursor-match-next
                      eerie-multicursor-unmatch-last
                      eerie-multicursor-skip-match
                      eerie-multiedit-clear
                      eerie-visual-inner-of-thing
                      eerie-visual-bounds-of-thing
                      eerie-multicursor-spawn
                      eerie-multicursor-visual-exit
                      eerie-visual-exit)))
    (eerie--multiedit-deactivate)))

(defun eerie--multicursor-copy-marker (pos)
  "Return a new marker at POS."
  (when pos
    (copy-marker pos)))

(defun eerie--multicursor-marker-position (marker)
  "Return the current buffer position for MARKER."
  (cond
   ((markerp marker) (marker-position marker))
   ((integerp marker) marker)
   (t nil)))

(defun eerie--multicursor-release-marker (marker)
  "Release MARKER when it is live."
  (when (markerp marker)
    (set-marker marker nil)))

(defun eerie--multicursor-release-anchor (anchor)
  "Release the markers stored in linewise visual ANCHOR."
  (when anchor
    (eerie--multicursor-release-marker (car anchor))
    (eerie--multicursor-release-marker (cdr anchor))))

(defun eerie--multicursor-release-snapshot (snapshot)
  "Release the markers held by multicursor SNAPSHOT."
  (when snapshot
    (eerie--multicursor-release-marker (plist-get snapshot :point))
    (eerie--multicursor-release-marker (plist-get snapshot :mark))
    (eerie--multicursor-release-anchor (plist-get snapshot :visual-line-anchor))))

(defun eerie--multicursor-pre-command ()
  "Capture the primary command key sequence for multi-cursor replay."
  (when (and eerie--multicursor-active
             (not eerie--multicursor-replaying))
    (setq-local eerie--multicursor-command-keys
                (condition-case nil
                    (this-command-keys-vector)
                  (error []))
                eerie--multicursor-command this-command
                eerie--multicursor-prefix-arg current-prefix-arg
                eerie--multicursor-read-events nil)))

(defun eerie--multicursor-record-read-event (event)
  "Record EVENT as extra multi-cursor command input."
  (when (and eerie--multicursor-active
             (not eerie--multicursor-replaying))
    (push event eerie--multicursor-read-events))
  event)

(defun eerie--multicursor-consume-replay-input ()
  "Return the next queued replay input for the current multi-cursor command."
  (if eerie--multicursor-replay-inputs
      (prog1 (car eerie--multicursor-replay-inputs)
        (setq eerie--multicursor-replay-inputs
              (cdr eerie--multicursor-replay-inputs)))
    (user-error "Missing multi-cursor replay input")))

(defun eerie--multicursor-around-read-key (orig &rest args)
  "Record read-key input via ORIG with ARGS for multi-cursor replay."
  (if eerie--multicursor-replaying
      (eerie--multicursor-consume-replay-input)
    (eerie--multicursor-record-read-event (apply orig args))))

(defun eerie--multicursor-around-read-char (orig &rest args)
  "Record read-char input via ORIG with ARGS for multi-cursor replay."
  (if eerie--multicursor-replaying
      (eerie--multicursor-consume-replay-input)
    (eerie--multicursor-record-read-event (apply orig args))))

(defun eerie--multicursor-around-read-from-minibuffer (orig &rest args)
  "Record minibuffer input via ORIG with ARGS for multi-cursor replay."
  (if eerie--multicursor-replaying
      (eerie--multicursor-consume-replay-input)
    (eerie--multicursor-record-read-event (apply orig args))))

(defun eerie--multicursor-normalize-state (state)
  "Return the multicursor-aware version of STATE."
  (pcase state
    ((or 'normal 'multicursor) 'multicursor)
    ((or 'visual 'multicursor-visual) 'multicursor-visual)
    (_ state)))

(defun eerie--multicursor-current-snapshot ()
  "Return the current multicursor primary snapshot."
  (list :state (eerie--multicursor-normalize-state (eerie--current-state))
        :point (eerie--multicursor-copy-marker (point))
        :mark (when (region-active-p)
                (eerie--multicursor-copy-marker (mark t)))
        :selection-type (when (region-active-p)
                          (eerie--selection-type))
        :visual-type eerie--visual-type
        :visual-line-anchor (when eerie--visual-line-anchor
                              (cons
                               (eerie--multicursor-copy-marker
                                (car eerie--visual-line-anchor))
                               (eerie--multicursor-copy-marker
                                (cdr eerie--visual-line-anchor))))
        :rectangle (bound-and-true-p rectangle-mark-mode)))

(defun eerie--multicursor-snapshot-point (snapshot)
  "Return the point position stored in SNAPSHOT."
  (eerie--multicursor-marker-position (plist-get snapshot :point)))

(defun eerie--multicursor-snapshot-mark (snapshot)
  "Return the mark position stored in SNAPSHOT."
  (eerie--multicursor-marker-position (plist-get snapshot :mark)))

(defun eerie--multicursor-snapshot-range (snapshot)
  "Return the active region range stored in SNAPSHOT, or nil."
  (let ((point-pos (eerie--multicursor-snapshot-point snapshot))
        (mark-pos (eerie--multicursor-snapshot-mark snapshot)))
    (when (and point-pos mark-pos (/= point-pos mark-pos))
      (cons (min point-pos mark-pos)
            (max point-pos mark-pos)))))

(defun eerie--multicursor-clear-live-selection ()
  "Clear the current live selection before restoring another cursor snapshot."
  (when (bound-and-true-p rectangle-mark-mode)
    (rectangle-mark-mode -1))
  (setq-local eerie--selection nil
              eerie--selection-history nil
              eerie--visual-type nil
              eerie--visual-line-anchor nil)
  (deactivate-mark t))

(defun eerie--multicursor-apply-snapshot (snapshot)
  "Restore multicursor SNAPSHOT into the current buffer state."
  (let ((state (plist-get snapshot :state))
        (point-pos (eerie--multicursor-snapshot-point snapshot))
        (mark-pos (eerie--multicursor-snapshot-mark snapshot))
        (selection-type (plist-get snapshot :selection-type))
        (visual-type (plist-get snapshot :visual-type))
        (anchor (plist-get snapshot :visual-line-anchor)))
    (eerie--multicursor-clear-live-selection)
    (when point-pos
      (goto-char point-pos))
    (when state
      (eerie--switch-state state))
    (when (and selection-type mark-pos point-pos
               (not (plist-get snapshot :rectangle)))
      (eerie--select-without-history
       (list selection-type mark-pos point-pos)))
    (when (plist-get snapshot :rectangle)
      (when mark-pos
        (push-mark mark-pos t t)
        (rectangle-mark-mode 1)))
    (setq-local eerie--visual-type visual-type
                eerie--visual-line-anchor
                (when anchor
                  (cons (eerie--multicursor-marker-position (car anchor))
                        (eerie--multicursor-marker-position (cdr anchor)))))))

(defun eerie--multicursor-overlay-start (pos)
  "Return the display start position for a fake cursor at POS."
  (cond
   ((<= (point-max) (point-min))
    (point-min))
   ((>= pos (point-max))
    (1- (point-max)))
   ((and eerie-use-cursor-position-hack
         (> pos (point-min)))
    (1- pos))
   (t pos)))

(defun eerie--multicursor-overlay-end (start)
  "Return the display end position for a fake cursor starting at START."
  (if (< start (point-max))
      (1+ start)
    start))

(defun eerie--multicursor-overlay-snapshot (ov)
  "Return the multicursor snapshot stored on OV."
  (overlay-get ov 'eerie-multicursor-snapshot))

(defun eerie--multicursor-overlay-point (ov)
  "Return the current fake-cursor point stored on OV."
  (eerie--multicursor-snapshot-point
   (eerie--multicursor-overlay-snapshot ov)))

(defun eerie--multicursor-overlay-range (snapshot)
  "Return the display range for SNAPSHOT."
  (or (eerie--multicursor-snapshot-range snapshot)
      (when-let ((pos (eerie--multicursor-snapshot-point snapshot)))
        (let ((start (eerie--multicursor-overlay-start pos)))
          (cons start (eerie--multicursor-overlay-end start))))))

(defun eerie--multicursor-render-overlay (ov snapshot)
  "Render OV using multicursor SNAPSHOT."
  (when-let ((range (eerie--multicursor-overlay-range snapshot)))
    (move-overlay ov (car range) (cdr range))
    (overlay-put ov 'face
                 (if (eerie--multicursor-snapshot-range snapshot)
                     'eerie-beacon-fake-selection
                   'eerie-beacon-fake-cursor))
    (overlay-put ov 'priority 1)
    (overlay-put ov 'eerie-multicursor-snapshot snapshot)
    (overlay-put ov 'eerie-multicursor-point (plist-get snapshot :point))))

(defun eerie--multicursor-set-overlay-snapshot (ov snapshot)
  "Replace OV with multicursor SNAPSHOT and rerender it."
  (when-let ((old (eerie--multicursor-overlay-snapshot ov)))
    (eerie--multicursor-release-snapshot old))
  (eerie--multicursor-render-overlay ov snapshot))

(defun eerie--multicursor-cursor-snapshot (pos)
  "Return a normal multicursor cursor snapshot at POS."
  (list :state 'multicursor
        :point (eerie--multicursor-copy-marker pos)
        :mark nil
        :selection-type nil
        :visual-type nil
        :visual-line-anchor nil
        :rectangle nil))

(defun eerie--multicursor-add-overlay (pos)
  "Add a fake cursor overlay for actual point POS."
  (let ((ov (make-overlay (point-min) (point-min) nil t t)))
    (eerie--multicursor-set-overlay-snapshot
     ov
     (eerie--multicursor-cursor-snapshot pos))
    (push ov eerie--beacon-overlays)))

(defun eerie--multicursor-secondary-overlays ()
  "Return multi-cursor overlays sorted from buffer end to start."
  (sort (copy-sequence eerie--beacon-overlays)
        (lambda (left right)
          (> (or (eerie--multicursor-overlay-point left) (point-min))
             (or (eerie--multicursor-overlay-point right) (point-min))))))

(defun eerie--multicursor-reset-state ()
  "Reset the current multi-cursor state."
  (let ((was-active eerie--multicursor-active))
  (advice-remove 'read-key #'eerie--multicursor-around-read-key)
  (advice-remove 'read-char #'eerie--multicursor-around-read-char)
  (advice-remove 'read-from-minibuffer
                 #'eerie--multicursor-around-read-from-minibuffer)
  (remove-hook 'pre-command-hook #'eerie--multicursor-pre-command t)
  (remove-hook 'post-command-hook #'eerie--multicursor-post-command t)
  (setq-local eerie--multicursor-active nil
              eerie--multicursor-replaying nil
              eerie--multicursor-last-command nil
              eerie--multicursor-command-keys nil
              eerie--multicursor-read-events nil
              eerie--multicursor-command nil
              eerie--multicursor-prefix-arg nil
              eerie--multicursor-replay-inputs nil)
  (when was-active
    (eerie--which-key-hide-popup))
  (mapc (lambda (ov)
          (when (overlayp ov)
            (eerie--multicursor-release-snapshot
             (eerie--multicursor-overlay-snapshot ov))))
        eerie--beacon-overlays)
  (eerie--beacon-remove-overlays)))

(defun eerie-multicursor-cancel ()
  "Cancel the current multi-cursor session and return to NORMAL."
  (interactive)
  (eerie--multiedit-reset-state)
  (eerie--multicursor-reset-state)
  (eerie--finish-visual-exit 'normal))

(defun eerie--multicursor-primary-offset ()
  "Return the current point offset inside the primary multi-edit target."
  (let* ((range eerie--multiedit-primary)
         (offset (- (point) (car range))))
    (max 0 (min offset (- (cdr range) (car range))))))

(defun eerie--multicursor-position-for-target (target offset)
  "Return the multi-cursor point for TARGET using OFFSET."
  (max (car target)
       (min (cdr target)
            (+ (car target) offset))))

(defun eerie--multicursor-insert-kind (command)
  "Return the current multi-cursor insert COMMAND kind, or nil."
  (pcase command
    ('eerie-insert 'insert)
    ('eerie-append 'append)
    ('eerie-insert-beginning-of-line 'insert-bol)
    ('eerie-append-end-of-line 'append-eol)
    (_ nil)))

(defun eerie--multicursor-marker-for-overlay (ov kind)
  "Return a replay marker for cursor overlay OV under KIND."
  (save-excursion
    (goto-char (eerie--multicursor-overlay-point ov))
    (copy-marker
     (pcase kind
       ('insert (point))
       ('append (if (< (point) (point-max))
                    (1+ (point))
                  (point)))
       ('insert-bol (line-beginning-position))
       ('append-eol (line-end-position))))))

(defun eerie--multicursor-prepare-insert-replay (kind)
  "Prepare replay markers for multi-cursor insert KIND."
  (advice-remove 'read-key #'eerie--multicursor-around-read-key)
  (advice-remove 'read-char #'eerie--multicursor-around-read-char)
  (advice-remove 'read-from-minibuffer
                 #'eerie--multicursor-around-read-from-minibuffer)
  (remove-hook 'pre-command-hook #'eerie--multicursor-pre-command t)
  (remove-hook 'post-command-hook #'eerie--multicursor-post-command t)
  (setq-local eerie--multiedit-replay-markers
              (mapcar (lambda (ov)
                        (eerie--multicursor-marker-for-overlay ov kind))
                      (eerie--multicursor-secondary-overlays))
              eerie--multiedit-replay-command
              (if (memq kind '(append append-eol))
                  'append
                'insert)
              eerie--multicursor-command nil
              eerie--multicursor-prefix-arg nil
              eerie--multicursor-command-keys nil
              eerie--multicursor-read-events nil
              eerie--multicursor-replay-inputs nil)
  (setq last-kbd-macro nil)
  (call-interactively #'kmacro-start-macro))

(defun eerie--multicursor-replay-jump-char (inputs)
  "Replay `eerie-jump-char' using INPUTS for the current cursor."
  (let ((char (car inputs))
        (events (cdr inputs))
        (direction 'forward))
    (unless char
      (user-error "Missing jump char input"))
    (eerie--cancel-selection)
    (catch 'done
      (dolist (event events)
        (let ((key (if (integerp event)
                       event
                     (event-basic-type event))))
          (cond
           ((eq key ?\;)
            (setq direction (if (eq direction 'forward)
                                'backward
                              'forward)))
           ((and (integerp key) (>= key ?1) (<= key ?9))
            (let* ((regex (regexp-quote (string (if (eq char 13) ?\n char))))
                   (candidate (nth (1- (- key ?0))
                                   (seq-take
                                    (eerie--jump-regexp-candidates regex direction)
                                    9))))
              (when candidate
                (eerie--jump-char-action candidate))
              (throw 'done t)))
           (t
            (throw 'done t))))))))

(defun eerie--multicursor-replay-visual-text-object (kind inputs)
  "Replay a visual text object of KIND using INPUTS for the current cursor."
  (let* ((ch (car inputs))
         (thing (and ch (eerie--vim-text-object-for-char ch))))
    (unless thing
      (user-error "Missing visual text object input"))
    (eerie--select-vim-text-object kind thing)
    (setq-local eerie--visual-type 'char)))

(defun eerie--multicursor-replay-special-command (command inputs)
  "Replay COMMAND with INPUTS when it needs custom multi-cursor handling."
  (pcase command
    ('eerie-jump-char
     (eerie--multicursor-replay-jump-char inputs)
     t)
    ('eerie-visual-inner-of-thing
     (eerie--multicursor-replay-visual-text-object 'inner inputs)
     t)
    ('eerie-visual-bounds-of-thing
     (eerie--multicursor-replay-visual-text-object 'bounds inputs)
     t)
    (_ nil)))

(defun eerie--multicursor-replay-command (command mc-prefix-arg inputs)
  "Replay COMMAND with MC-PREFIX-ARG and INPUTS across secondary cursors."
  (setq-local eerie--multicursor-replaying t)
  (let ((primary-snapshot (eerie--multicursor-current-snapshot)))
    (unwind-protect
        (eerie--wrap-collapse-undo
          (dolist (ov (eerie--multicursor-secondary-overlays))
            (when (and (overlayp ov)
                       (overlay-buffer ov))
              (eerie--multicursor-apply-snapshot
               (eerie--multicursor-overlay-snapshot ov))
              (or (eerie--multicursor-replay-special-command command inputs)
                  (let ((current-prefix-arg mc-prefix-arg)
                        (eerie--multicursor-replay-inputs (copy-sequence inputs)))
                    (call-interactively command)))
              (eerie--multicursor-set-overlay-snapshot
               ov
               (eerie--multicursor-current-snapshot)))))
      (setq-local eerie--multicursor-replaying nil)
      (when primary-snapshot
        (eerie--multicursor-apply-snapshot primary-snapshot)
        (eerie--multicursor-release-snapshot primary-snapshot))))
  (when eerie--multicursor-active
    (eerie--ensure-visible)))

(defun eerie--multicursor-move-secondary-cursors (mover)
  "Apply cursor MOVER to every secondary multi-cursor overlay."
  (save-mark-and-excursion
    (dolist (ov (eerie--multicursor-secondary-overlays))
      (when (and (overlayp ov)
                 (overlay-buffer ov))
        (goto-char (eerie--multicursor-overlay-point ov))
        (funcall mover)
        (eerie--multicursor-set-overlay-snapshot
         ov
         (eerie--multicursor-current-snapshot))))))

(defun eerie--multicursor-find-char-on-line (char)
  "Move point to the next CHAR on the current line.

If no later CHAR exists on the current line, leave point unchanged."
  (let ((origin (point))
        (limit (line-end-position))
        (target (char-to-string (if (eq char 13) ?\n char))))
    (goto-char (min (1+ origin) (point-max)))
    (unless (and (<= (point) limit)
                 (search-forward target limit t 1))
      (goto-char origin))
    (when (> (point) origin)
      (backward-char 1))))

(defun eerie--goto-next-space-on-line (&optional repeat-p)
  "Move point to the next space on the current line.

When REPEAT-P is non-nil, skip the current point before searching so a
repeated command advances to the following space. If no later space
exists on the current line, move to the end of the line."
  (let* ((origin (point))
         (limit (line-end-position))
         (skip-current-space
          (and (not repeat-p)
               (< origin limit)
               (eq (char-after origin) ?\s)
               (not (eq (char-before origin) ?\s))))
         (start (if (or repeat-p skip-current-space)
                    (min (1+ origin) (point-max))
                  origin))
         found)
    (goto-char start)
    (unless (setq found
                  (and (<= (point) limit)
                       (search-forward " " limit t 1)))
      (goto-char limit))
    (when (and found
               (> (point) start))
      (backward-char 1))))

(defun eerie--multicursor-find-next-space-on-line ()
  "Move point to the next space on the current line for multi-cursor `W'."
  (eerie--goto-next-space-on-line
   (eq eerie--multicursor-last-command 'eerie-multicursor-next-space)))

(defun eerie-next-space ()
  "Move point to the next space on the current line."
  (interactive)
  (eerie--goto-next-space-on-line (eq last-command 'eerie-next-space))
  (eerie--ensure-visible))

(defun eerie-multicursor-jump-char (char)
  "Move every multi-cursor to the next CHAR on its current line."
  (interactive (list (read-char "Multi-cursor find char: " t)))
  (eerie--multicursor-move-secondary-cursors
   (lambda ()
     (eerie--multicursor-find-char-on-line char)))
  (eerie--multicursor-find-char-on-line char)
  (setq-local eerie--multicursor-last-command 'eerie-multicursor-jump-char)
  (eerie--ensure-visible)
  (eerie--switch-state 'multicursor))

(defun eerie-multicursor-next-space ()
  "Move every multi-cursor to the next space on its current line."
  (interactive)
  (eerie--multicursor-move-secondary-cursors
   #'eerie--multicursor-find-next-space-on-line)
  (eerie--multicursor-find-next-space-on-line)
  (setq-local eerie--multicursor-last-command 'eerie-multicursor-next-space)
  (eerie--ensure-visible)
  (eerie--switch-state 'multicursor))

(defun eerie--multicursor-post-command ()
  "Replay supported normal-mode commands across all secondary cursors."
  (when (and eerie--multicursor-active
             (not eerie--multicursor-replaying))
    (let* ((command (or eerie--multicursor-command this-command))
           (insert-kind (eerie--multicursor-insert-kind command))
           (inputs (nreverse eerie--multicursor-read-events)))
      (setq-local eerie--multicursor-last-command command)
      (cond
       ((memq command
              '(eerie-multicursor-start
                eerie-multicursor-spawn
                eerie-multicursor-visual-exit
                eerie-multicursor-cancel
                eerie-multicursor-jump-char
                eerie-multicursor-next-space
                ignore))
        nil)
       ((and insert-kind (eerie-insert-mode-p))
        (eerie--multicursor-prepare-insert-replay insert-kind))
       ((eerie-insert-mode-p)
        (eerie--multicursor-reset-state))
       ((not (memq (eerie--current-state)
                   '(multicursor multicursor-visual normal visual)))
        (eerie--multicursor-reset-state))
       (t
        (when command
          (eerie--multicursor-replay-command
           command
           eerie--multicursor-prefix-arg
           inputs))))
      (when (and eerie--multicursor-active
                 (eerie--multiedit-active-p)
                 (not (memq command
                            '(eerie-multicursor-start
                              eerie-multicursor-spawn
                              eerie-visual-enter-multicursor
                              eerie-multicursor-match-next
                              eerie-multicursor-unmatch-last
                              eerie-multicursor-skip-match
                              eerie-multiedit-match-next
                              eerie-multiedit-unmatch-last
                              eerie-multiedit-skip-match
                              eerie-multiedit-reverse-direction
                              eerie-multicursor-visual-exit
                              eerie-multicursor-cancel
                              eerie-operator-delete
                              eerie-operator-change
                              eerie-operator-yank
                              eerie-insert
                              eerie-append
                              ignore))))
        (eerie--multiedit-reset-state))
      (when eerie--multicursor-active
        (eerie--multicursor-display-menu)))))

(defun eerie-multicursor-spawn ()
  "Promote the current multi-edit targets into a multi-cursor NORMAL state."
  (interactive)
  (eerie--multiedit-ensure-session)
  (let* ((targets eerie--multiedit-targets)
         (primary eerie--multiedit-primary)
         (offset (eerie--multicursor-primary-offset))
         (primary-pos (eerie--multicursor-position-for-target primary offset)))
    (remove-hook 'post-command-hook #'eerie--multiedit-post-command t)
    (when (region-active-p)
      (eerie--cancel-selection))
    (eerie--multiedit-render-overlays)
    (eerie--multicursor-reset-state)
    (goto-char primary-pos)
    (dolist (target targets)
      (unless (eerie--multiedit-range-equal-p target primary)
        (eerie--multicursor-add-overlay
         (eerie--multicursor-position-for-target target offset))))
    (eerie--multicursor-activate)
    (eerie--switch-state 'multicursor)
    (eerie--multicursor-display-menu)))

(defun eerie-multicursor-match-next ()
  "Add the next exact match of the current multicursor seed."
  (interactive)
  (eerie-multiedit-match-next))

(defun eerie-multicursor-unmatch-last ()
  "Remove the newest exact match from the current multicursor seed set."
  (interactive)
  (eerie-multiedit-unmatch-last))

(defun eerie-multicursor-skip-match ()
  "Skip the next exact match in the current multicursor session."
  (interactive)
  (eerie-multiedit-skip-match))

(defun eerie-multicursor-visual-exit ()
  "Leave multicursor VISUAL while keeping the multicursor session alive."
  (interactive)
  (if (eerie--multiedit-active-p)
      (eerie-multicursor-spawn)
    (eerie--finish-visual-exit 'multicursor)))

(defun eerie-multiedit-clear ()
  "Clear the current multi-edit session and return to NORMAL."
  (interactive)
  (eerie--multiedit-reset-state)
  (eerie--finish-visual-exit 'normal))

(defun eerie-multiedit-reverse-direction ()
  "Reverse multi-edit builder direction.

When no multi-edit session is active yet, seed one from the current
charwise VISUAL selection first."
  (interactive)
  (eerie--multiedit-ensure-session)
  (setq-local eerie--multiedit-direction
              (if (eq eerie--multiedit-direction 'forward)
                  'backward
                'forward)
              eerie--multiedit-search-head eerie--multiedit-primary)
  (message "Multi-edit direction: %s" eerie--multiedit-direction))

(defun eerie-multiedit-skip-match ()
  "Skip the next match in the current multi-edit direction."
  (interactive)
  (eerie--multiedit-ensure-session)
  (if-let ((candidate (eerie--multiedit-find-next-match)))
      (progn
        (setq-local eerie--multiedit-search-head candidate)
        (message "Skipped one %s multi-edit match"
                 eerie--multiedit-direction))
    (message "No more %s multi-edit matches" eerie--multiedit-direction)))

(defun eerie-multiedit-unmatch-last ()
  "Remove the most recently added multi-edit target."
  (interactive)
  (eerie--multiedit-ensure-session)
  (if (= (length eerie--multiedit-targets) 1)
      (message "No newer multi-edit match to remove")
    (let ((remaining (butlast eerie--multiedit-targets)))
      (eerie--multiedit-set-targets remaining (car (last remaining))))))

(defun eerie-multiedit-match-next ()
  "Add the next exact match of the current multi-edit seed."
  (interactive)
  (eerie--multiedit-ensure-session)
  (if-let ((candidate (eerie--multiedit-find-next-match)))
      (progn
        (setq-local eerie--multiedit-targets
                    (append eerie--multiedit-targets (list candidate)))
        (eerie--multiedit-apply-target candidate))
    (message "No more %s multi-edit matches" eerie--multiedit-direction)))

(defun eerie-visual-exit ()
  "Leave VISUAL state and return to NORMAL."
  (interactive)
  (if (eerie--multiedit-active-p)
      (if eerie--multicursor-active
          (eerie-multicursor-spawn)
        (eerie-multiedit-clear))
    (eerie--finish-visual-exit
     (if eerie--multicursor-active
         'multicursor
       'normal))))

(defun eerie--visual-move-char (command)
  "Run charwise visual COMMAND, starting VISUAL if necessary."
  (unless (region-active-p)
    (eerie-visual-start))
  (call-interactively command))

(defun eerie--buffer-last-content-position ()
  "Return the last meaningful position in the current buffer."
  (if (and (> (point-max) (point-min))
           (eq (char-before (point-max)) ?\n))
      (1- (point-max))
    (point-max)))

(defun eerie--visual-target-point-for-buffer-edge (edge)
  "Return a VISUAL-mode target point at buffer EDGE."
  (save-excursion
    (pcase eerie--visual-type
      ('block
       (let ((column (current-column)))
         (goto-char (if (eq edge 'start)
                        (point-min)
                      (eerie--buffer-last-content-position)))
         (move-to-column column)
         (point)))
      ('line
       (if (eq edge 'start)
           (point-min)
         (eerie--buffer-last-content-position)))
      (_
       (if (eq edge 'start)
           (point-min)
         (point-max))))))

(defun eerie--visual-extend-to-point (pos)
  "Extend the current VISUAL selection to POS."
  (goto-char pos)
  (pcase eerie--visual-type
    ('line
     (eerie--visual-line-apply-selection (eerie--visual-line-range)))
    ('block nil)
    (_
     (setq-local eerie--selection
                 (eerie--make-selection '(expand . char)
                                       (mark t)
                                       (point))))))

(defun eerie--visual-search-command (direction &optional prompt)
  "Extend VISUAL selection using a search in DIRECTION.

When PROMPT is non-nil, read a new pattern with PROMPT. Otherwise reuse the
latest search pattern."
  (let ((pattern (if prompt
                     (let ((input (eerie--read-search-pattern prompt)))
                       (eerie--push-search input)
                       input)
                   (or (car regexp-search-ring)
                       (user-error "No previous search")))))
    (when (eerie--search-pattern pattern direction)
      (eerie--visual-extend-to-point (point)))))

(defun eerie-visual-left ()
  "Move left while extending the current VISUAL selection."
  (interactive)
  (pcase eerie--visual-type
    ('line (ignore))
    ('block
     (when (> (point) (line-beginning-position))
       (backward-char 1)))
    (_ (eerie--visual-move-char #'eerie-left-expand))))

(defun eerie-visual-right ()
  "Move right while extending the current VISUAL selection."
  (interactive)
  (pcase eerie--visual-type
    ('line (ignore))
    ('block
     (when (< (point) (line-end-position))
       (forward-char 1)))
    (_ (eerie--visual-move-char #'eerie-right-expand))))

(defun eerie-visual-prev ()
  "Move up while extending the current VISUAL selection."
  (interactive)
  (pcase eerie--visual-type
    ('line (eerie-visual-line -1))
    ('block (eerie--visual-block-move-lines -1))
    (_ (eerie--visual-move-char #'eerie-prev-expand))))

(defun eerie-visual-next ()
  "Move down while extending the current VISUAL selection."
  (interactive)
  (pcase eerie--visual-type
    ('line (eerie-visual-line 1))
    ('block (eerie--visual-block-move-lines 1))
    (_ (eerie--visual-move-char #'eerie-next-expand))))

(defun eerie-visual-goto-buffer-start ()
  "Extend the current VISUAL selection to the start of the buffer."
  (interactive)
  (eerie--visual-extend-to-point
   (eerie--visual-target-point-for-buffer-edge 'start)))

(defun eerie-visual-goto-buffer-end ()
  "Extend the current VISUAL selection to the end of the buffer."
  (interactive)
  (eerie--visual-extend-to-point
   (eerie--visual-target-point-for-buffer-edge 'end)))

(defun eerie-visual-goto-line-end ()
  "Extend the current VISUAL selection to the end of the current line."
  (interactive)
  (eerie--visual-extend-to-point (line-end-position)))

(defun eerie--visual-cursor-range ()
  "Return the buffer range for the visible cursor char in VISUAL state."
  (when (region-active-p)
    (let ((pos (cond
                ((and eerie-use-cursor-position-hack
                      (eerie--direction-forward-p)
                      (> (point) (point-min)))
                 (1- (point)))
                ((< (point) (point-max))
                 (point))
                ((> (point) (point-min))
                 (1- (point))))))
      (when (and pos
                 (<= (point-min) pos)
                 (< pos (point-max)))
        (cons pos (1+ pos))))))

(defun eerie--visual-jump-char-action (candidate)
  "Extend the current VISUAL selection to CANDIDATE."
  (eerie--visual-extend-to-point (cdr candidate))
  (eerie--ensure-visible))

(defun eerie--visual-line-jump-action (candidate)
  "Extend the current linewise VISUAL selection to CANDIDATE."
  (setq-local eerie--visual-type 'line)
  (eerie--visual-line-apply-selection candidate)
  (eerie--ensure-visible))

(defun eerie-visual-jump-char (arg char)
  "Extend VISUAL selection to a visible CHAR using numbered hints.

Use digits `1' through `9' to choose the visible candidates nearest point.
Press `;' during the jump session to reverse direction. A negative prefix
argument starts in backward direction."
  (interactive (list current-prefix-arg (read-char "Visual jump char: " t)))
  (let ((regex (regexp-quote (string (if (eq char 13) ?\n char))))
        (direction (if (eerie--with-negative-argument-p arg)
                       'backward
                     'forward)))
    (eerie--jump-loop
     (lambda (dir)
       (eerie--jump-regexp-candidates
        regex
        dir
        (eerie--visual-cursor-range)))
     #'eerie--visual-jump-char-action
     "char"
     direction)))

(defun eerie-visual-search-forward ()
  "Prompt for a regexp and extend VISUAL selection to the next match."
  (interactive)
  (eerie--visual-search-command 'forward "/"))

(defun eerie-visual-search-backward ()
  "Prompt for a regexp and extend VISUAL selection to the previous match."
  (interactive)
  (eerie--visual-search-command 'backward "?"))

(defun eerie-visual-search-next ()
  "Extend VISUAL selection to the next match in the last search direction."
  (interactive)
  (eerie--visual-search-command eerie--last-search-direction))

(defun eerie-visual-search-prev ()
  "Extend VISUAL selection to the next match opposite the last search direction."
  (interactive)
  (eerie--visual-search-command
   (if (eq eerie--last-search-direction 'backward)
       'forward
     'backward)))

(defun eerie--visual-finish-action ()
  "Leave VISUAL after a non-insert action."
  (when (or (eerie-visual-mode-p)
            (bound-and-true-p eerie-multicursor-visual-mode))
    (eerie--switch-state
     (if eerie--multicursor-active
         'multicursor
       'normal))))

(defun eerie-visual-yank ()
  "Yank the active VISUAL selection."
  (interactive)
  (if (eerie--multiedit-active-p)
      (progn
        (eerie-save)
        (eerie--multiedit-deactivate)
        (eerie--visual-finish-action))
    (if (eq eerie--visual-type 'block)
      (progn
        (copy-rectangle-as-kill (region-beginning) (region-end))
        (eerie--visual-finish-action))
      (eerie-save)
      (eerie--visual-finish-action))))

(defun eerie-visual-insert ()
  "Enter INSERT from VISUAL.

In block VISUAL, insert at the left edge of the selected rectangle on
every selected line."
  (interactive)
  (if (eq eerie--visual-type 'block)
      (eerie--visual-block-start-replay 'insert)
    (user-error "Visual I is only supported in block VISUAL mode")))

(defun eerie-visual-append ()
  "Enter APPEND from VISUAL.

In block VISUAL, append at the right edge of the selected rectangle on
every selected line."
  (interactive)
  (if (eq eerie--visual-type 'block)
      (eerie--visual-block-start-replay 'append)
    (user-error "Visual A is only supported in block VISUAL mode")))

(defun eerie-visual-delete ()
  "Delete the active VISUAL selection."
  (interactive)
  (if (eerie--multiedit-active-p)
      (eerie--multiedit-delete-all-targets)
    (if (eq eerie--visual-type 'block)
      (progn
        (kill-rectangle (region-beginning) (region-end))
        (eerie--visual-finish-action))
      (eerie-kill)
      (eerie--visual-finish-action))))

(defun eerie-visual-change ()
  "Change the active VISUAL selection."
  (interactive)
  (if (eerie--multiedit-active-p)
      (eerie--multiedit-start-change)
    (if (eq eerie--visual-type 'block)
      (progn
        (kill-rectangle (region-beginning) (region-end))
        (eerie--enter-insert-state))
      (eerie-change))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BLOCK
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--backward-block ()
  (let ((orig-pos (point))
        (pos (save-mark-and-excursion
               (let ((depth (car (syntax-ppss))))
                 (while (and (re-search-backward "\\s(" nil t)
                             (> (car (syntax-ppss)) depth)))
                 (when (= (car (syntax-ppss)) depth)
                   (point))))))
    (when (and pos (not (= orig-pos pos)))
      (goto-char pos))))

(defun eerie--forward-block ()
  (let ((orig-pos (point))
        (pos (save-mark-and-excursion
               (let ((depth (car (syntax-ppss))))
                 (while (and (re-search-forward "\\s)" nil t)
                             (> (car (syntax-ppss)) depth)))
                 (when (= (car (syntax-ppss)) depth)
                   (point))))))
    (when (and pos (not (= orig-pos pos)))
      (goto-char pos)
      (eerie--hack-cursor-pos (point)))))

(defun eerie-block (arg)
  "Mark the block or expand to parent block."
  (interactive "P")
  (let ((ra (region-active-p))
        (back (xor (eerie--direction-backward-p) (< (prefix-numeric-value arg) 0)))
        (depth (car (syntax-ppss)))
        (orig-pos (point))
        p m)
    (save-mark-and-excursion
      (while (and (if back (re-search-backward "\\s(" nil t) (re-search-forward "\\s)" nil t))
                  (or (eerie--in-string-p)
                      (if ra (>= (car (syntax-ppss)) depth) (> (car (syntax-ppss)) depth)))))
      (when (and (if ra (< (car (syntax-ppss)) depth) (<= (car (syntax-ppss)) depth))
                 (not (= (point) orig-pos)))
        (setq p (point))
        (when (ignore-errors (forward-list (if back 1 -1)) t)
          (setq m (point)))))
    (when (and p m)
      (thread-first
        (eerie--make-selection '(expand . block) m p)
        (eerie--select t))
      (eerie--maybe-highlight-num-positions '(eerie--backward-block . eerie--forward-block)))))

(defun eerie-to-block (arg)
  "Expand to next block.

Will create selection with type (expand . block)."
  (interactive "P")
  ;; We respect the direction of block selection.
  (let ((back (or (when (equal 'block (cdr (eerie--selection-type)))
                     (eerie--direction-backward-p))
                  (< (prefix-numeric-value arg) 0)))
        (depth (car (syntax-ppss)))
        (orig-pos (point))
        p m)
    (save-mark-and-excursion
      (while (and (if back (re-search-backward "\\s(" nil t) (re-search-forward "\\s)" nil t))
                  (or (eerie--in-string-p)
                      (> (car (syntax-ppss)) depth))))
      (when (and (= (car (syntax-ppss)) depth)
                 (not (= (point) orig-pos)))
        (setq p (point))
        (when (ignore-errors (forward-list (if back 1 -1)) t)
          (setq m (point)))))
    (when (and p m)
      (thread-first
        (eerie--make-selection '(expand . block) orig-pos p t)
        (eerie--select t))
      (eerie--maybe-highlight-num-positions '(eerie--backward-block . eerie--forward-block)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; JOIN
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--join-forward ()
  (let (mark pos)
    (save-mark-and-excursion
      (goto-char (line-end-position))
      (setq pos (point))
      (when (re-search-forward "[[:space:]\n\r]*" nil t)
        (setq mark (point))))
    (when pos
      (thread-first
        (eerie--make-selection '(expand . join) pos mark)
        (eerie--select t)))))

(defun eerie--join-backward ()
  (let* (mark
         pos)
    (save-mark-and-excursion
      (back-to-indentation)
      (setq pos (point))
      (goto-char (line-beginning-position))
      (while (looking-back "[[:space:]\n\r]" 1 t)
        (forward-char -1))
      (setq mark (point)))
    (thread-first
      (eerie--make-selection '(expand . join) mark pos)
      (eerie--select t))))

(defun eerie--join-both ()
  (let* (mark
         pos)
    (save-mark-and-excursion
      (while (looking-back "[[:space:]\n\r]" 1 t)
        (forward-char -1))
      (setq mark (point)))
    (save-mark-and-excursion
      (while (looking-at "[[:space:]\n\r]")
        (forward-char 1))
      (setq pos (point)))
    (thread-first
      (eerie--make-selection '(expand . join) mark pos)
      (eerie--select t))))

(defun eerie-join (arg)
  "Select the indentation between this line to the non empty previous line.

Will create selection with type (select . join)

Prefix:
with NEGATIVE ARGUMENT, forward search indentation to select.
with UNIVERSAL ARGUMENT, search both side."
  (interactive "P")
  (cond
   ((or (equal '(expand . join) (eerie--selection-type))
        (eerie--with-universal-argument-p arg))
    (eerie--join-both))
   ((eerie--with-negative-argument-p arg)
    (eerie--join-forward))
   (t
    (eerie--join-backward))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; FIND & TILL
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--find-continue-forward ()
  (when eerie--last-find
    (let ((case-fold-search nil)
          (ch-str (char-to-string eerie--last-find)))
      (when (search-forward ch-str nil t 1)
        (eerie--hack-cursor-pos (point))))))

(defun eerie--find-continue-backward ()
  (when eerie--last-find
    (let ((case-fold-search nil)
          (ch-str (char-to-string eerie--last-find)))
      (search-backward ch-str nil t 1))))

(defun eerie--till-continue-forward ()
  (when eerie--last-till
    (let ((case-fold-search nil)
          (ch-str (char-to-string eerie--last-till)))
      (when (< (point) (point-max))
        (forward-char 1)
        (when (search-forward ch-str nil t 1)
          (backward-char 1)
          (eerie--hack-cursor-pos (point)))))))

(defun eerie--till-continue-backward ()
  (when eerie--last-till
    (let ((case-fold-search nil)
          (ch-str (char-to-string eerie--last-till)))
      (when (> (point) (point-min))
        (backward-char 1)
        (when (search-backward ch-str nil t 1)
          (forward-char 1)
          (point))))))

(defun eerie-find (n ch &optional expand)
  "Find the next N char read from minibuffer."
  (interactive "p\ncFind:")
  (let* ((case-fold-search nil)
         (ch-str (if (eq ch 13) "\n" (char-to-string ch)))
         (beg (point))
         end)
    (save-mark-and-excursion
      (setq end (search-forward ch-str nil t n)))
    (if (not end)
        (message "char %s not found" ch-str)
      (thread-first
        (eerie--make-selection '(select . find)
                              beg end expand)
        (eerie--select t))
      (setq eerie--last-find ch)
      (eerie--maybe-highlight-num-positions
       '(eerie--find-continue-backward . eerie--find-continue-forward)))))

(defun eerie-find-expand (n ch)
  (interactive "p\ncExpand find:")
  (eerie-find n ch t))

(defun eerie-till (n ch &optional expand)
  "Forward till the next N char read from minibuffer."
  (interactive "p\ncTill:")
  (let* ((case-fold-search nil)
         (ch-str (if (eq ch 13) "\n" (char-to-string ch)))
         (beg (point))
         (fix-pos (if (< n 0) 1 -1))
         end)
    (save-mark-and-excursion
      (if (> n 0) (forward-char 1) (forward-char -1))
      (setq end (search-forward ch-str nil t n)))
    (if (not end)
        (message "char %s not found" ch-str)
      (thread-first
        (eerie--make-selection '(select . till)
                              beg (+ end fix-pos) expand)
        (eerie--select t))
      (setq eerie--last-till ch)
      (eerie--maybe-highlight-num-positions
       '(eerie--till-continue-backward . eerie--till-continue-forward)))))

(defun eerie-till-expand (n ch)
  (interactive "p\ncExpand till:")
  (eerie-till n ch t))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VISIBLE JUMP
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--jump-visible-p (pos)
  "Return non-nil when POS is visibly rendered."
  (let ((invisible (get-char-property pos 'invisible)))
    (or (null invisible)
        (eq t buffer-invisibility-spec)
        (null (assoc invisible buffer-invisibility-spec)))))

(defun eerie--jump-next-visible-point ()
  "Return the next visible point from point."
  (let ((pos (point)))
    (while (and (not (= (point-max) (setq pos (next-char-property-change pos))))
                (not (eerie--jump-visible-p pos))))
    pos))

(defun eerie--jump-next-invisible-point ()
  "Return the next invisible point from point."
  (let ((pos (point)))
    (while (and (not (= (point-max) (setq pos (next-char-property-change pos))))
                (eerie--jump-visible-p pos)))
    pos))

(defun eerie--jump-visible-regions (beg end)
  "Return visible regions between BEG and END."
  (setq beg (max beg (point-min)))
  (setq end (min end (point-max)))
  (when (< beg end)
    (let (visibles start)
      (save-excursion
        (save-restriction
          (narrow-to-region beg end)
          (setq start (goto-char (point-min)))
          (while (not (= (point) (point-max)))
            (goto-char (eerie--jump-next-invisible-point))
            (push (cons start (point)) visibles)
            (setq start (goto-char (eerie--jump-next-visible-point))))
          (nreverse visibles))))))

(defun eerie--jump-visible-line-ranges ()
  "Return visible logical line ranges in the selected window."
  (let ((window-start-pos (window-start))
        (window-end-pos (window-end (selected-window) t))
        ranges
        previous-beg)
    (save-excursion
      (goto-char window-start-pos)
      (beginning-of-line)
      (while (< (point) window-end-pos)
        (let* ((range (eerie--visual-line-range))
               (beg (car range)))
          (if (equal beg previous-beg)
              (goto-char window-end-pos)
            (when (and (< beg window-end-pos)
                       (> (cdr range) window-start-pos))
              (push range ranges))
            (setq previous-beg beg)
            (forward-line 1)))))
    (nreverse ranges)))

(defun eerie--jump-line-can-move-p (direction origin)
  "Return non-nil when DIRECTION can move beyond ORIGIN."
  (save-excursion
    (goto-char (car origin))
    (forward-line (if (eq direction 'backward) -1 1))
    (not (= (car (eerie--visual-line-range)) (car origin)))))

(defun eerie--jump-line-recenter (direction)
  "Recenter the window for line jumping in DIRECTION."
  (let ((inhibit-message t))
    (condition-case nil
        (recenter (if (eq direction 'backward) -1 0))
      (error nil))))

(defun eerie--jump-line-candidates-in-window (direction exclude-range)
  "Return visible line candidates in DIRECTION for the current window.

When EXCLUDE-RANGE is non-nil, skip the exact line range with the same
bounds."
  (let* ((origin (or exclude-range (eerie--visual-line-range)))
         (origin-beg (car origin))
         candidates)
    (dolist (range (eerie--jump-visible-line-ranges))
      (let ((beg (car range)))
        (when (and (not (and exclude-range
                             (= beg (car exclude-range))
                             (= (cdr range) (cdr exclude-range))))
                   (if (eq direction 'backward)
                       (< beg origin-beg)
                     (> beg origin-beg)))
          (push range candidates))))
    (if (eq direction 'backward)
        (sort candidates (lambda (a b) (> (car a) (car b))))
      (nreverse candidates))))

(defun eerie--jump-regexp-candidates (regex &optional direction exclude-range)
  "Return visible REGEX candidates ordered by DIRECTION.

When EXCLUDE-RANGE is non-nil, skip the exact candidate with the same
bounds."
  (let ((case-fold-search t)
        (current-point (point))
        (direction (or direction 'forward))
        candidates)
    (dolist (pair (eerie--jump-visible-regions
                   (window-start)
                   (window-end (selected-window) t)))
      (save-excursion
        (goto-char (car pair))
        (while (re-search-forward regex (cdr pair) t)
          (let ((beg (match-beginning 0))
                (end (match-end 0)))
            (when (and (not (and exclude-range
                                 (= beg (car exclude-range))
                                 (= end (cdr exclude-range))))
                       (if (eq direction 'backward)
                           (< beg current-point)
                         (> beg current-point)))
              (push (cons beg end) candidates))))))
    (if (eq direction 'backward)
        (sort candidates (lambda (a b) (> (car a) (car b))))
      (nreverse candidates))))

(defun eerie--jump-line-candidates (&optional direction exclude-range)
  "Return visible line candidates ordered by DIRECTION.

When EXCLUDE-RANGE is non-nil, skip the exact line range with the same
bounds."
  (let* ((direction (or direction 'forward))
         (origin (or exclude-range (eerie--visual-line-range)))
         (candidates (eerie--jump-line-candidates-in-window
                      direction
                      exclude-range)))
    (when (and (< (length candidates) 9)
               (eerie--jump-line-can-move-p direction origin))
      (eerie--jump-line-recenter direction)
      (setq candidates (eerie--jump-line-candidates-in-window
                        direction
                        exclude-range)))
    candidates))

(defun eerie--jump-show-candidates (candidates direction)
  "Display numbered hint overlays for CANDIDATES in DIRECTION."
  (eerie--remove-expand-highlights)
  (cl-loop for candidate in (seq-take candidates 9)
           for idx from 1
           do
           (save-excursion
             (goto-char (car candidate))
             (let ((ov (make-overlay (point) (1+ (point))))
                   (before-full-width-char
                    (and (char-after) (= 2 (char-width (char-after)))))
                   (before-newline (equal 10 (char-after)))
                   (before-tab (equal 9 (char-after)))
                   (face (if (eq direction 'backward)
                             'eerie-position-highlight-reverse-number-1
                           'eerie-position-highlight-number-1)))
               (overlay-put ov 'window (selected-window))
               (cond
                (before-newline
                 (overlay-put ov 'display
                              (concat (propertize (format "%s" idx) 'face face) "\n")))
                (before-tab
                 (overlay-put ov 'display
                              (concat (propertize (format "%s" idx) 'face face) "\t")))
                (before-full-width-char
                 (overlay-put ov 'display
                              (propertize
                               (format "%s" (eerie--format-full-width-number idx))
                               'face face)))
                (t
                 (overlay-put ov 'display
                              (propertize (format "%s" idx) 'face face))))
               (push ov eerie--expand-overlays)))))

(defun eerie--jump-read-event (direction noun candidates)
  "Read an event for jump hints in DIRECTION over NOUN and CANDIDATES."
  (read-key
   (if candidates
       (format "Jump %s %s (1-%d, ; reverse, other key exits): "
               noun direction (min 9 (length candidates)))
     (format "No more %s %s (; reverses, other key exits): "
             noun direction))))

(defun eerie--jump-loop (candidate-fn action noun &optional direction)
  "Run a visible jump loop using CANDIDATE-FN and ACTION.

NOUN is used for prompt text. DIRECTION defaults to `forward'.

Return an exit reason symbol when the loop stops."
  (let ((direction (or direction 'forward))
        done
        result)
    (unwind-protect
        (while (not done)
          (let* ((candidates (funcall candidate-fn direction))
                 (active-candidates (seq-take candidates 9)))
            (eerie--jump-show-candidates active-candidates direction)
            (let* ((event (eerie--jump-read-event direction noun active-candidates))
                   (key (if (integerp event)
                            event
                          (event-basic-type event))))
              (cond
               ((eq key ?\e)
                (setq done t
                      result 'escape))
               ((eq key ?\C-g)
                (setq done t
                      result 'keyboard-quit))
               ((eq key ?\;)
                (setq direction (if (eq direction 'forward) 'backward 'forward)))
               ((and (integerp key) (>= key ?1) (<= key ?9))
                (if-let ((candidate (nth (1- (- key ?0)) active-candidates)))
                    (funcall action candidate)
                  (message "No candidate %d" (- key ?0))))
               (t
                (setq unread-command-events (list event)
                      done t
                      result 'replay))))))
      (eerie--remove-expand-highlights))
    result))

(defun eerie--jump-char-action (candidate)
  "Jump to CANDIDATE for char jumping."
  (goto-char (car candidate))
  (eerie--ensure-visible))

(defun eerie--jump-word-action (candidate)
  "Select the word occurrence at CANDIDATE in VISUAL state."
  (thread-first
    (eerie--make-selection '(expand . char) (car candidate) (cdr candidate))
    (eerie--select t))
  (setq-local eerie--visual-type 'char
              eerie--visual-line-anchor nil)
  (eerie--switch-state (eerie--visual-target-state))
  (eerie--ensure-visible))

(defun eerie-jump-char (arg char)
  "Jump to visible CHAR using numbered hints.

Use digits `1' through `9' to choose the visible candidates nearest point.
Press `;' during the jump session to reverse direction. A negative prefix
argument starts in backward direction."
  (interactive (list current-prefix-arg (read-char "Jump char: " t)))
  (let ((regex (regexp-quote (string (if (eq char 13) ?\n char))))
        (direction (if (eerie--with-negative-argument-p arg)
                       'backward
                     'forward)))
    (eerie--with-recorded-jump
      (eerie--cancel-selection)
      (eerie--jump-loop
       (lambda (dir) (eerie--jump-regexp-candidates regex dir))
       #'eerie--jump-char-action
       "char"
       direction))))

(defun eerie-jump-word-occurrence (arg)
  "Jump to visible occurrences of the current word using numbered hints.

The current word is selected before jumping. Use digits `1' through `9'
to choose a visible occurrence. Press `;' during the jump session to
reverse direction. A negative prefix argument starts in backward
direction. The final target is left in charwise VISUAL state so normal
visual movement and action keys continue to work."
  (interactive "P")
  (if-let* ((bounds (bounds-of-thing-at-point eerie-word-thing))
            (word (buffer-substring-no-properties (car bounds) (cdr bounds))))
      (let ((regex (format "\\<%s\\>" (regexp-quote word)))
            (direction (if (eerie--with-negative-argument-p arg)
                           'backward
                         'forward)))
        (eerie--with-recorded-jump
          (eerie--cancel-selection)
          (eerie--jump-word-action bounds)
          (when (eq (eerie--jump-loop
                     (lambda (dir)
                       (eerie--jump-regexp-candidates
                        regex
                        dir
                        (when (region-active-p)
                          (cons (region-beginning) (region-end)))))
                     #'eerie--jump-word-action
                     "word"
                     direction)
                    'escape)
            (eerie-visual-exit))))
    (user-error "No word at point")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; VISIT and SEARCH
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--read-search-pattern (prompt)
  "Read a regexp search pattern with PROMPT."
  (let* ((default (car regexp-search-ring))
         (input (read-from-minibuffer prompt nil nil nil 'regexp-search-ring default)))
    (cond
     ((and (string-empty-p input) default) default)
     ((string-empty-p input) (user-error "No previous search"))
     (t input))))

(defun eerie--search-pattern (pattern direction)
  "Search for PATTERN in DIRECTION and move point to the match start."
  (let* ((reverse (eq direction 'backward))
         (origin (point))
         (case-fold-search nil)
         (search-fn (if reverse #'re-search-backward #'re-search-forward))
         (wrap-point (if reverse (point-max) (point-min)))
         (seed (if reverse
                   (if (> origin (point-min)) (1- origin) (point-max))
                 (if (< origin (point-max)) (1+ origin) (point-min)))))
    (goto-char seed)
    (if (or (funcall search-fn pattern nil t 1)
            (progn
              (goto-char wrap-point)
              (funcall search-fn pattern nil t 1)))
        (progn
          (goto-char (match-beginning 0))
          (setq eerie--last-search-direction direction)
          (eerie--ensure-visible)
          (eerie--highlight-regexp-in-buffer pattern)
          (message "%s search: %s" (if reverse "Reverse" "Search") pattern)
          t)
      (goto-char origin)
      (message "%s search failed: %s" (if reverse "Reverse" "Search") pattern)
      nil)))

(defun eerie-search-forward ()
  "Prompt for a regexp and jump to the next match."
  (interactive)
  (let ((pattern (eerie--read-search-pattern "/")))
    (eerie--push-search pattern)
    (eerie--with-recorded-jump
      (eerie--cancel-selection)
      (eerie--search-pattern pattern 'forward))))

(defun eerie-search-backward ()
  "Prompt for a regexp and jump to the previous match."
  (interactive)
  (let ((pattern (eerie--read-search-pattern "?")))
    (eerie--push-search pattern)
    (eerie--with-recorded-jump
      (eerie--cancel-selection)
      (eerie--search-pattern pattern 'backward))))

(defun eerie-search-next ()
  "Repeat the most recent Eerie search in the same direction."
  (interactive)
  (if-let ((pattern (car regexp-search-ring)))
      (eerie--with-recorded-jump
        (eerie--cancel-selection)
        (eerie--search-pattern pattern eerie--last-search-direction))
    (user-error "No previous search")))

(defun eerie-search-prev ()
  "Repeat the most recent Eerie search in the opposite direction."
  (interactive)
  (if-let ((pattern (car regexp-search-ring)))
      (eerie--with-recorded-jump
        (eerie--cancel-selection)
        (eerie--search-pattern pattern
                              (if (eq eerie--last-search-direction 'backward)
                                  'forward
                                'backward)))
    (user-error "No previous search")))

(defun eerie-search (arg)
  "Search and select with the car of current `regexp-search-ring'.

If the contents of selection doesn't match the regexp, will push
it to `regexp-search-ring' before searching.

To search backward, use \\[negative-argument]."
  (interactive "P")
  ;; Test if we add current region as search target.
  (when (and (region-active-p)
             (let ((search (car regexp-search-ring)))
               (or (not search)
                   (not (string-match-p
                         (format "^%s$" search)
                         (buffer-substring-no-properties (region-beginning) (region-end)))))))
    (eerie--push-search (regexp-quote (buffer-substring-no-properties (region-beginning) (region-end)))))
  (when-let* ((search (car regexp-search-ring)))
    (let ((reverse (xor (eerie--with-negative-argument-p arg) (eerie--direction-backward-p)))
          (case-fold-search nil))
      (if (or (if reverse
                  (re-search-backward search nil t 1)
                (re-search-forward search nil t 1))
              ;; Try research from buffer beginning/end
              ;; if we are already at the last/first matched
              (save-mark-and-excursion
                ;; Recalculate search indicator
                (eerie--clean-search-indicator-state)
                (goto-char (if reverse (point-max) (point-min)))
                (if reverse
                    (re-search-backward search nil t 1)
                  (re-search-forward search nil t 1))))
          (let* ((m (match-data))
                 (marker-beg (car m))
                 (marker-end (cadr m))
                 (beg (if reverse (marker-position marker-end) (marker-position marker-beg)))
                 (end (if reverse (marker-position marker-beg) (marker-position marker-end))))
            (thread-first
              (eerie--make-selection '(select . visit) beg end)
              (eerie--select t))
            (if reverse
                (message "Reverse search: %s" search)
              (message "Search: %s" search))
            (eerie--ensure-visible))
        (message "Searching %s failed" search))
      (eerie--highlight-regexp-in-buffer search))))

(defconst eerie--matching-open-delimiters '(?\( ?\[ ?\{)
  "Opening delimiters supported by `%'.")

(defconst eerie--matching-close-delimiters '(?\) ?\] ?\})
  "Closing delimiters supported by `%'.")

(defconst eerie--matching-quote-delimiters '(?\" ?\')
  "Quote delimiters supported by `%'.")

(defun eerie--matching-delimiter-char-p (ch)
  "Return non-nil when CH is supported by `%'."
  (and ch (alist-get ch eerie--vim-text-object-table)))

(defun eerie--matching-delimiter-position ()
  "Return the buffer position of the delimiter `%` should inspect."
  (cond
   ((eerie--matching-delimiter-char-p (char-after))
    (point))
   ((and (> (point) (point-min))
         (memq (char-after) '(nil ?\n ?\r))
         (eerie--matching-delimiter-char-p (char-before)))
    (1- (point)))))

(defun eerie--matching-quote-target (pos ch)
  "Return the matching quote target for delimiter CH at POS."
  (when-let* ((thing (alist-get ch eerie--vim-text-object-table))
              (bounds (or (save-excursion
                            (goto-char pos)
                            (eerie--parse-range-of-thing thing nil))
                          (when (< pos (point-max))
                            (save-excursion
                              (goto-char (1+ pos))
                              (eerie--parse-range-of-thing thing nil))))))
    (let ((beg (car bounds))
          (end (cdr bounds)))
      (cond
       ((= pos beg) (1- end))
       ((= pos (1- end)) beg)))))

(defun eerie--matching-paren-target (pos ch)
  "Return the matching paren-like target for delimiter CH at POS."
  (save-excursion
    (goto-char pos)
    (cond
     ((memq ch eerie--matching-open-delimiters)
      (when-let ((end (ignore-errors (scan-sexps (point) 1))))
        (1- end)))
     ((memq ch eerie--matching-close-delimiters)
      (ignore-errors (scan-sexps (1+ (point)) -1))))))

(defun eerie--matching-delimiter-target ()
  "Return the matching delimiter position for `%'."
  (when-let* ((pos (eerie--matching-delimiter-position))
              (ch (save-excursion
                    (goto-char pos)
                    (char-after))))
    (if (memq ch eerie--matching-quote-delimiters)
        (eerie--matching-quote-target pos ch)
      (eerie--matching-paren-target pos ch))))

(defun eerie-jump-matching ()
  "Jump to the delimiter matching the delimiter under point."
  (interactive)
  (eerie--with-recorded-jump
    (eerie--cancel-selection)
    (if-let ((target (eerie--matching-delimiter-target)))
        (progn
          (goto-char target)
          (eerie--ensure-visible))
      (user-error "No matching delimiter at point"))))

(defun eerie-visual-jump-matching ()
  "Extend VISUAL selection to the matching delimiter under point."
  (interactive)
  (if-let ((target (eerie--matching-delimiter-target)))
      (eerie--visual-extend-to-point target)
    (user-error "No matching delimiter at point")))

(defun eerie-pop-search ()
  "Searching for the previous target."
  (interactive)
  (when-let* ((search (pop regexp-search-ring)))
    (message "current search is: %s" (car regexp-search-ring))
    (eerie--cancel-selection)))

(defun eerie--visit-point (text reverse)
  "Return the point of text for visit command.
Argument TEXT current search text.
Argument REVERSE if selection is reversed."
  (let ((func (if reverse #'re-search-backward #'re-search-forward))
        (func-2 (if reverse #'re-search-forward #'re-search-backward))
        (case-fold-search nil))
    (save-mark-and-excursion
      (or (funcall func text nil t 1)
          (funcall func-2 text nil t 1)))))

(defun eerie-visit (arg)
  "Read a string from minibuffer, then find and select it.

The input will be pushed into `regexp-search-ring'.  So
\\[eerie-search] can be used for further searching with the same
condition.

A list of words and symbols in the current buffer will be
provided for completion.  To search for regexp instead, set
`eerie-visit-sanitize-completion' to nil.  In that case,
completions will be provided in regexp form, but also covering
the words and symbols in the current buffer.

To search backward, use \\[negative-argument]."
  (interactive "P")
  (let* ((reverse arg)
         (pos (point))
         (text (eerie--prompt-symbol-and-words
                (if arg "Visit backward: " "Visit: ")
                (point-min) (point-max) t))
         (visit-point (eerie--visit-point text reverse)))
    (if visit-point
        (let* ((m (match-data))
               (marker-beg (car m))
               (marker-end (cadr m))
               (beg (if (> pos visit-point) (marker-position marker-end) (marker-position marker-beg)))
               (end (if (> pos visit-point) (marker-position marker-beg) (marker-position marker-end))))
          (thread-first
            (eerie--make-selection '(select . visit) beg end)
            (eerie--select t))
          (eerie--push-search text)
          (eerie--ensure-visible)
          (eerie--highlight-regexp-in-buffer text)
          (setq eerie--dont-remove-overlay t))
      (message "Visit: %s failed" text))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; THING
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-thing-prompt (prompt-text)
  (read-char
   (if eerie-display-thing-help
       (concat (eerie--render-char-thing-table) "\n" prompt-text)
     prompt-text)))

(defun eerie--thing-get-direction (cmd)
  (or
   (alist-get cmd eerie-thing-selection-directions)
   'forward))

(defun eerie-beginning-of-thing (thing)
  "Select to the beginning of THING."
  (interactive (list (eerie-thing-prompt "Beginning of: ")))
  (save-window-excursion
    (let ((back (equal 'backward (eerie--thing-get-direction 'beginning)))
          (bounds (eerie--parse-inner-of-thing-char thing)))
      (when bounds
        (thread-first
          (eerie--make-selection '(select . transient)
                                (if back (point) (car bounds))
                                (if back (car bounds) (point)))
          (eerie--select t))))))

(defun eerie-end-of-thing (thing)
  "Select to the end of THING."
  (interactive (list (eerie-thing-prompt "End of: ")))
  (save-window-excursion
    (let ((back (equal 'backward (eerie--thing-get-direction 'end)))
          (bounds (eerie--parse-inner-of-thing-char thing)))
      (when bounds
        (thread-first
          (eerie--make-selection '(select . transient)
                                (if back (cdr bounds) (point))
                                (if back (point) (cdr bounds)))
          (eerie--select t))))))

(defun eerie--select-range (back bounds)
  (when bounds
    (thread-first
      (eerie--make-selection '(select . transient)
                            (if back (cdr bounds) (car bounds))
                            (if back (car bounds) (cdr bounds)))
      (eerie--select t))))

(defun eerie-inner-of-thing (thing)
  "Select inner (excluding delimiters) of THING."
  (interactive (list (eerie-thing-prompt "Inner of: ")))
  (save-window-excursion
    (let ((back (equal 'backward (eerie--thing-get-direction 'inner)))
          (bounds (eerie--parse-inner-of-thing-char thing)))
      (eerie--select-range back bounds))))

(defun eerie-bounds-of-thing (thing)
  "Select bounds (including delimiters) of THING."
  (interactive (list (eerie-thing-prompt "Bounds of: ")))
  (save-window-excursion
    (let ((back (equal 'backward (eerie--thing-get-direction 'bounds)))
          (bounds (eerie--parse-bounds-of-thing-char thing)))
      (eerie--select-range back bounds))))

(defconst eerie--vim-text-object-table
  '((?\( . round)
    (?\) . round)
    (?\[ . square)
    (?\] . square)
    (?\{ . curly)
    (?\} . curly)
    (?\" . double-quote)
    (?\' . single-quote))
  "Mapping from Vim-style text object chars to Eerie thing symbols.")

(defun eerie--read-vim-text-object-char (prompt)
  "Read a Vim-style text object character with PROMPT."
  (read-char prompt))

(defun eerie--vim-text-object-for-char (ch)
  "Return the thing symbol for Vim-style text object character CH."
  (or (alist-get ch eerie--vim-text-object-table)
      (user-error "Unsupported text object: %s" (single-key-description ch))))

(defun eerie--select-vim-text-object (kind thing)
  "Select THING using KIND, which is either `inner' or `bounds'."
  (let ((bounds (eerie--parse-range-of-thing thing (eq kind 'inner))))
    (unless bounds
      (user-error "No %s text object at point" (symbol-name thing)))
    (thread-first
      (eerie--make-selection '(select . transient) (car bounds) (cdr bounds))
      (eerie--select t))))

(defun eerie-visual-inner-of-thing ()
  "Select the inner Vim-style text object in VISUAL mode."
  (interactive)
  (if (eerie--multiedit-active-p)
      (eerie--multiedit-start-insert-or-append 'insert)
    (let* ((ch (eerie--read-vim-text-object-char "Visual inner object: "))
           (thing (eerie--vim-text-object-for-char ch)))
      (eerie--select-vim-text-object 'inner thing)
      (setq-local eerie--visual-type 'char)
      (eerie--switch-state (eerie--visual-target-state)))))

(defun eerie-visual-bounds-of-thing ()
  "Select the bounds Vim-style text object in VISUAL mode."
  (interactive)
  (if (eerie--multiedit-active-p)
      (eerie--multiedit-start-insert-or-append 'append)
    (let* ((ch (eerie--read-vim-text-object-char "Visual around object: "))
           (thing (eerie--vim-text-object-for-char ch)))
      (eerie--select-vim-text-object 'bounds thing)
      (setq-local eerie--visual-type 'char)
      (eerie--switch-state (eerie--visual-target-state)))))

(defun eerie--operator-select-range (beg end)
  "Create an operator selection spanning BEG to END."
  (unless (and beg end (/= beg end))
    (user-error "Motion produced no target"))
  (thread-first
    (eerie--make-selection '(select . transient) beg end)
    (eerie--select t)))

(defun eerie--operator-forward-thing-start (thing)
  "Return the start of the next THING from point."
  (save-mark-and-excursion
    (when-let ((bounds (bounds-of-thing-at-point thing)))
      (goto-char (cdr bounds)))
    (while (and (< (point) (point-max))
                (bounds-of-thing-at-point thing))
      (forward-char 1))
    (while (and (< (point) (point-max))
                (not (bounds-of-thing-at-point thing)))
      (forward-char 1))
    (when-let ((bounds (bounds-of-thing-at-point thing)))
      (car bounds))))

(defun eerie--operator-backward-thing-start (thing)
  "Return the start of the previous THING from point."
  (save-mark-and-excursion
    (when (> (point) (point-min))
      (backward-char 1))
    (while (and (> (point) (point-min))
                (not (bounds-of-thing-at-point thing)))
      (backward-char 1))
    (when-let ((bounds (bounds-of-thing-at-point thing)))
      (car bounds))))

(defun eerie--operator-current-thing-end (thing)
  "Return the end of the current THING at point."
  (when-let ((bounds (bounds-of-thing-at-point thing)))
    (cdr bounds)))

(defun eerie--operator-find-forward (ch &optional till)
  "Return the forward find target for CH.

When TILL is non-nil, return the position just before CH."
  (save-mark-and-excursion
    (let ((case-fold-search nil)
          (limit (line-end-position))
          (target (char-to-string ch)))
      (when (search-forward target limit t 1)
        (if till
            (1- (point))
          (point))))))

(defun eerie--operator-motion-range (operator motion)
  "Return the range for OPERATOR acting on MOTION."
  (let ((orig (point)))
    (pcase motion
      (`(word-forward)
       (cons orig
             (or (and (eq operator 'change)
                      (eerie--operator-current-thing-end eerie-word-thing))
                 (eerie--operator-forward-thing-start eerie-word-thing))))
      (`(symbol-forward)
       (cons orig
             (or (and (eq operator 'change)
                      (eerie--operator-current-thing-end eerie-symbol-thing))
                 (eerie--operator-forward-thing-start eerie-symbol-thing))))
      (`(word-backward)
       (cons orig (eerie--operator-backward-thing-start eerie-word-thing)))
      (`(symbol-backward)
       (cons orig (eerie--operator-backward-thing-start eerie-symbol-thing)))
      (`(char-left)
       (cons orig (and (> orig (point-min)) (1- orig))))
      (`(char-right)
       (cons orig (and (< orig (point-max)) (1+ orig))))
      (`(line-start)
       (cons orig (line-beginning-position)))
      (`(line-end)
       (cons orig (line-end-position)))
      (`(find-forward ,ch)
       (cons orig (eerie--operator-find-forward ch nil)))
      (`(till-forward ,ch)
       (cons orig (eerie--operator-find-forward ch t))))))

(defun eerie--operator-target (operator)
  "Read and return the target for OPERATOR."
  (let ((event (read-key (format "%s target: " (capitalize (symbol-name operator))))))
    (pcase (event-basic-type event)
      ((pred (lambda (it) (eq it (aref (symbol-name operator) 0))))
       '(line))
      (?w '(motion word-forward))
      (?W '(motion symbol-forward))
      (?b '(motion word-backward))
      (?B '(motion symbol-backward))
      (?h '(motion char-left))
      (?l '(motion char-right))
      (?0 '(motion line-start))
      (?$ '(motion line-end))
      (?f
       (list 'motion 'find-forward
             (eerie--read-vim-text-object-char "Find char: ")))
      (?t
       (list 'motion 'till-forward
             (eerie--read-vim-text-object-char "Till char: ")))
      (?i
       (list 'text-object 'inner
             (eerie--vim-text-object-for-char
              (eerie--read-vim-text-object-char "Inner object: "))))
      (?a
       (list 'text-object 'bounds
             (eerie--vim-text-object-for-char
              (eerie--read-vim-text-object-char "Around object: "))))
      (_
       (user-error "Unsupported %s target" (symbol-name operator))))))

(defun eerie--operator-command (operator)
  "Execute Vim-style OPERATOR on the next target."
  (let ((origin (point-marker)))
  (pcase (eerie--operator-target operator)
    (`(line)
     (thread-first
       (eerie--make-selection '(expand . line)
                             (line-beginning-position)
                             (line-end-position))
       (eerie--select t)))
    (`(motion ,motion-kind)
     (pcase-let ((`(,beg . ,end)
                  (eerie--operator-motion-range operator (list motion-kind))))
       (eerie--operator-select-range beg end)))
    (`(motion ,motion-kind ,motion-arg)
     (pcase-let ((`(,beg . ,end)
                  (eerie--operator-motion-range operator (list motion-kind motion-arg))))
       (eerie--operator-select-range beg end)))
    (`(text-object ,kind ,thing)
     (eerie--select-vim-text-object kind thing)))
  (pcase operator
    ('delete (eerie-kill))
    ('change (eerie-change))
    ('yank
     (eerie-save)
     (when (and (marker-buffer origin)
                (eq (marker-buffer origin) (current-buffer)))
       (goto-char origin))))
  (unless (eerie-insert-mode-p)
    (when (region-active-p)
      (eerie--cancel-selection))
    (eerie--switch-state 'normal))))

(defun eerie-operator-delete ()
  "Run a Vim-style delete operator."
  (interactive)
  (if (and eerie--multicursor-active
           (eerie--multiedit-active-p))
      (eerie--multiedit-delete-all-targets)
    (eerie--operator-command 'delete)))

(defun eerie-operator-change ()
  "Run a Vim-style change operator."
  (interactive)
  (if (and eerie--multicursor-active
           (eerie--multiedit-active-p))
      (eerie--multiedit-start-change)
    (eerie--operator-command 'change)))

(defun eerie-operator-yank ()
  "Run a Vim-style yank operator."
  (interactive)
  (if (and eerie--multicursor-active
           (eerie--multiedit-active-p))
      (let ((origin (point-marker))
            (primary-text (eerie--multiedit-primary-text)))
        (eerie--multiedit-reset-state)
        (kill-new primary-text)
        (when (region-active-p)
          (eerie--cancel-selection))
        (when eerie--multicursor-active
          (eerie--multicursor-reset-state))
        (when (and (marker-buffer origin)
                   (eq (marker-buffer origin) (current-buffer)))
          (goto-char origin))
        (eerie--switch-state 'normal))
    (eerie--operator-command 'yank)))

(defun eerie-indent ()
  "Indent region or current line."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-indent-region))

(defun eerie-M-x ()
  "Just Meta-x."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-excute-extended-command))

(defun eerie-unpop-to-mark ()
  "Unpop off mark ring. Does nothing if mark ring is empty."
  (interactive)
  (eerie--with-recorded-jump
    (eerie--cancel-selection)
    (when mark-ring
      (setq mark-ring (cons (copy-marker (mark-marker)) mark-ring))
      (set-marker (mark-marker) (car (last mark-ring)) (current-buffer))
      (setq mark-ring (nbutlast mark-ring))
      (goto-char (marker-position (car (last mark-ring)))))))

(defun eerie-pop-to-mark ()
  "Alternative command to `pop-to-mark-command'.

Before jump, a mark of current location will be created."
  (interactive)
  (eerie--with-recorded-jump
    (eerie--cancel-selection)
    (unless (member last-command '(eerie-pop-to-mark eerie-unpop-to-mark eerie-pop-or-unpop-to-mark))
      (setq mark-ring (append mark-ring (list (point-marker)))))
    (pop-to-mark-command)))

(defun eerie-pop-or-unpop-to-mark (arg)
  "Call `eerie-pop-to-mark' or `eerie-unpop-to-mark', depending on ARG.

With a negative prefix ARG, call `eerie-unpop-to-mark'. Otherwise, call
`eerie-pop-to-mark.'

See also `eerie-pop-or-unpop-to-mark-repeat-unpop'."
  (interactive "p")
  (if (or (and eerie-pop-or-unpop-to-mark-repeat-unpop
               (eq last-command 'eerie-unpop-to-mark))
          (< arg 0))
      (progn
        (setq this-command 'eerie-unpop-to-mark)
        (eerie-unpop-to-mark))
    (eerie-pop-to-mark)))

(defun eerie-pop-to-global-mark ()
  "Alternative command to `pop-global-mark'.

Before jump, a mark of current location will be created."
  (interactive)
  (eerie--with-recorded-jump
    (eerie--cancel-selection)
    (unless (member last-command '(eerie-pop-to-global-mark eerie-pop-to-mark eerie-unpop-to-mark))
      (setq global-mark-ring (append global-mark-ring (list (point-marker)))))
    (eerie--execute-kbd-macro eerie--kbd-pop-global-mark)))

(defun eerie-back-to-indentation ()
  "Back to indentation."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-back-to-indentation))

(defun eerie-query-replace ()
  "Query replace."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-query-replace))

(defun eerie-query-replace-regexp ()
  "Query replace regexp."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-query-replace-regexp))

(defun eerie-last-buffer (arg)
  "Switch to last buffer.
Argument ARG if not nil, switching in a new window."
  (interactive "P")
  (cond
   ((minibufferp)
    (keyboard-escape-quit))
   ((not arg)
    (mode-line-other-buffer))
   (t)))

(defun eerie-minibuffer-quit ()
  "Keyboard escape quit in minibuffer."
  (interactive)
  (if (minibufferp)
      (if (fboundp 'minibuffer-keyboard-quit)
          (call-interactively #'minibuffer-keyboard-quit)
        (call-interactively #'abort-recursive-edit))
    (call-interactively #'keyboard-quit)))

(defun eerie-escape-or-normal-modal ()
  "Keyboard escape quit or switch to normal state."
  (interactive)
  (cond
   ((minibufferp)
    (if (fboundp 'minibuffer-keyboard-quit)
        (call-interactively #'minibuffer-keyboard-quit)
      (call-interactively #'abort-recursive-edit)))
   ((eerie-insert-mode-p)
    (eerie--switch-state 'normal))
   (t
    (eerie--switch-state 'normal))))

(defun eerie-eval-last-exp ()
  "Eval last sexp."
  (interactive)
  (eerie--execute-kbd-macro eerie--kbd-eval-last-exp))

(defun eerie-expand (&optional n)
  (interactive)
  (eerie--with-selection-fallback
   (when (and eerie--expand-nav-function
              (region-active-p)
              (eerie--selection-type))
     (let* ((n (or n (string-to-number (char-to-string last-input-event))))
            (n (if (= n 0) 10 n))
            (sel-type (cons eerie-expand-selection-type (cdr (eerie--selection-type)))))
       (thread-first
         (eerie--make-selection sel-type (mark)
                               (save-mark-and-excursion
                                 (let ((eerie--expanding-p t))
                                   (dotimes (_ n)
                                     (funcall
                                      (if (eerie--direction-backward-p)
                                          (car eerie--expand-nav-function)
                                        (cdr eerie--expand-nav-function)))))
                                 (point)))
         (eerie--select t))
       (eerie--maybe-highlight-num-positions eerie--expand-nav-function)))))

(defun eerie-expand-1 () (interactive) (eerie-expand 1))
(defun eerie-expand-2 () (interactive) (eerie-expand 2))
(defun eerie-expand-3 () (interactive) (eerie-expand 3))
(defun eerie-expand-4 () (interactive) (eerie-expand 4))
(defun eerie-expand-5 () (interactive) (eerie-expand 5))
(defun eerie-expand-6 () (interactive) (eerie-expand 6))
(defun eerie-expand-7 () (interactive) (eerie-expand 7))
(defun eerie-expand-8 () (interactive) (eerie-expand 8))
(defun eerie-expand-9 () (interactive) (eerie-expand 9))
(defun eerie-expand-0 () (interactive) (eerie-expand 0))

(defun eerie-digit-argument ()
  (interactive)
  (set-transient-map eerie-numeric-argument-keymap)
  (call-interactively #'digit-argument))

(defun eerie-universal-argument ()
  "Replacement for universal-argument."
  (interactive)
  (if current-prefix-arg
      (call-interactively 'universal-argument-more)
    (call-interactively 'universal-argument)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; KMACROS
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie-kmacro-lines ()
  "Apply KMacro to each line in region."
  (interactive)
  (eerie--with-selection-fallback
   (let ((beg (caar (region-bounds)))
         (end (cdar (region-bounds)))
         (ov-list))
     (eerie--wrap-collapse-undo
       ;; create overlays as marks at each line beginning.
       ;; apply kmacro at those positions.
       ;; these allow user executing kmacro those create newlines.
       (save-mark-and-excursion
         (goto-char beg)
         (while (< (point) end)
           (goto-char (line-beginning-position))
           (push (make-overlay (point) (point)) ov-list)
           (forward-line 1)))
       (cl-loop for ov in (reverse ov-list) do
                (goto-char (overlay-start ov))
                (thread-first
                  (eerie--make-selection 'line (line-end-position) (line-beginning-position))
                  (eerie--select t))
                (call-last-kbd-macro)
                (delete-overlay ov))))))

(defun eerie-kmacro-matches (arg)
  "Apply KMacro by search.

Use negative argument for backward application."
  (interactive "P")
  (let ((s (car regexp-search-ring))
        (case-fold-search nil)
        (back (eerie--with-negative-argument-p arg)))
    (eerie--wrap-collapse-undo
      (while (if back
                 (re-search-backward s nil t)
               (re-search-forward s nil t))
        (thread-first
          (eerie--make-selection '(select . visit)
                                (if back
                                    (point)
                                  (match-beginning 0))
                                (if back
                                    (match-end 0)
                                  (point)))
          (eerie--select t))
        (let ((ov (make-overlay (region-beginning) (region-end))))
          (unwind-protect
              (progn
                (kmacro-call-macro nil))
            (progn
              (if back
                  (goto-char (min (point) (overlay-start ov)))
                (goto-char (max (point) (overlay-end ov))))
              (delete-overlay ov))))))))

(defun eerie-end-or-call-kmacro ()
  "End kmacro recording or call macro.

This command is a replacement for built-in `kmacro-end-or-call-macro'."
  (interactive)
  (cond
   ((eq eerie--beacon-defining-kbd-macro 'record)
    (setq eerie--beacon-defining-kbd-macro nil)
    (eerie-beacon-end-and-apply-kmacro))
   ((or (eerie-normal-mode-p)
        (eerie-motion-mode-p))
    (call-interactively #'kmacro-end-or-call-macro))
   (t
    (message "Can only end or call kmacro in NORMAL or MOTION state."))))

(defun eerie-end-kmacro ()
  "End kmacro recording or call macro.

This command is a replacement for built-in `kmacro-end-macro'."
  (interactive)
  (cond
   ((or (eerie-normal-mode-p)
        (eerie-motion-mode-p))
    (call-interactively #'kmacro-end-or-call-macro))
   (t
    (message "Can only end or call kmacro in NORMAL or MOTION state."))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; GRAB SELECTION
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun eerie--cancel-second-selection ()
  (delete-overlay mouse-secondary-overlay)
  (setq mouse-secondary-start (make-marker))
  (move-marker mouse-secondary-start (point)))

(defun eerie-grab ()
  "Create secondary selection or a marker if no region available."
  (interactive)
  (if (region-active-p)
      (secondary-selection-from-region)
    (eerie--cancel-second-selection))
  (eerie--cancel-selection))

(defun eerie-pop-grab ()
  "Pop to secondary selection."
  (interactive)
  (cond
   ((eerie--second-sel-buffer)
    (pop-to-buffer (eerie--second-sel-buffer))
    (secondary-selection-to-region)
    (setq mouse-secondary-start (make-marker))
    (move-marker mouse-secondary-start (point))
    (eerie--beacon-remove-overlays))
   ((markerp mouse-secondary-start)
       (or
     (when-let* ((buf (marker-buffer mouse-secondary-start)))
       (pop-to-buffer buf)
       (when-let* ((pos (marker-position mouse-secondary-start)))
         (goto-char pos)))
     (message "No secondary selection")))))

(defun eerie-swap-grab ()
  "Swap region and secondary selection."
  (interactive)
  (let* ((rbeg (region-beginning))
         (rend (region-end))
         (region-str (when (region-active-p) (buffer-substring-no-properties rbeg rend)))
         (sel-str (eerie--second-sel-get-string))
         (next-marker (make-marker)))
    (when region-str (eerie--delete-region rbeg rend))
    (when sel-str (eerie--insert sel-str))
    (move-marker next-marker (point))
    (eerie--second-sel-set-string (or region-str ""))
    (when (overlayp mouse-secondary-overlay)
       (delete-overlay mouse-secondary-overlay))
    (setq mouse-secondary-start next-marker)
    (eerie--cancel-selection)))

(defun eerie-sync-grab ()
  "Sync secondary selection with current region."
  (interactive)
  (eerie--with-selection-fallback
   (let* ((rbeg (region-beginning))
          (rend (region-end))
          (region-str (buffer-substring-no-properties rbeg rend))
          (next-marker (make-marker)))
     (move-marker next-marker (point))
     (eerie--second-sel-set-string region-str)
     (when (overlayp mouse-secondary-overlay)
       (delete-overlay mouse-secondary-overlay))
     (setq mouse-secondary-start next-marker)
     (eerie--cancel-selection))))

(defun eerie-describe-key (key-list &optional buffer)
  (interactive (list (help--read-key-sequence)))
  (if (= 1 (length key-list))
      (let* ((key (format-kbd-macro (cdar key-list)))
             (cmd (key-binding key)))
        (if-let* ((dispatch (and (commandp cmd)
                                 (get cmd 'eerie-dispatch))))
            (describe-key (kbd dispatch) buffer)
          (describe-key key-list buffer)))
    ;; for mouse events
    (describe-key key-list buffer)))

;; aliases
(defalias 'eerie-backward-delete 'eerie-backspace)
(defalias 'eerie-c-d 'eerie-C-d)
(defalias 'eerie-c-k 'eerie-C-k)
(defalias 'eerie-delete 'eerie-C-d)
(defalias 'eerie-cancel 'eerie-cancel-selection)

;; removed commands

(defmacro eerie--remove-command (orig rep)
  `(defun ,orig ()
     (interactive)
     (message "Command removed, use `%s' instead." ,(symbol-name rep))))

(eerie--remove-command eerie-begin-of-buffer eerie-beginning-of-thing)
(eerie--remove-command eerie-end-of-buffer eerie-end-of-thing)
(eerie--remove-command eerie-pop eerie-pop-selection)
(eerie--remove-command eerie-insert-at-begin eerie-insert)
(eerie--remove-command eerie-append-at-end eerie-append)
(eerie--remove-command eerie-head eerie-left)
(eerie--remove-command eerie-tail eerie-right)
(eerie--remove-command eerie-head-expand eerie-left-expand)
(eerie--remove-command eerie-tail-expand eerie-right-expand)
(eerie--remove-command eerie-block-expand eerie-to-block)

(provide 'eerie-command)
;;; eerie-command.el ends here
