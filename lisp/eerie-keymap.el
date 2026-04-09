;;; eerie-keymap.el --- Default keybindings for Eerie  -*- lexical-binding: t; -*-

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
;; Default keybindings.

;;; Code:

(require 'eerie-var)

(declare-function eerie-describe-key "eerie-command")
(declare-function eerie-goto-line-end "eerie-command")
(declare-function eerie-jump-char "eerie-command")
(declare-function eerie-jump-matching "eerie-command")
(declare-function eerie-jump-word-occurrence "eerie-command")
(declare-function eerie-next-space "eerie-command")
(declare-function eerie-multicursor-start "eerie-command")
(declare-function eerie-multicursor-match-next "eerie-command")
(declare-function eerie-multicursor-unmatch-last "eerie-command")
(declare-function eerie-multicursor-skip-match "eerie-command")
(declare-function eerie-visual-enter-multicursor "eerie-command")
(declare-function eerie-multicursor-visual-exit "eerie-command")
(declare-function eerie-multiedit-match-next "eerie-command")
(declare-function eerie-multiedit-unmatch-last "eerie-command")
(declare-function eerie-multiedit-reverse-direction "eerie-command")
(declare-function eerie-multiedit-skip-match "eerie-command")
(declare-function eerie-multicursor-cancel "eerie-command")
(declare-function eerie-visual-jump-char "eerie-command")
(declare-function eerie-visual-goto-line-end "eerie-command")
(declare-function eerie-visual-jump-matching "eerie-command")
(declare-function eerie-end-or-call-kmacro "eerie-command")
(declare-function eerie-end-kmacro "eerie-command")

(defvar eerie-normal-g-prefix-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "g") 'eerie-goto-buffer-start)
    (define-key keymap (kbd "d") 'eerie-goto-definition)
    keymap)
  "Prefix keymap for NORMAL mode `g` bindings.")

(defvar eerie-visual-g-prefix-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "g") 'eerie-visual-goto-buffer-start)
    keymap)
  "Prefix keymap for VISUAL mode `g` bindings.")

(defvar eerie-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap [remap describe-key] #'eerie-describe-key)
    keymap)
  "Global keymap for Eerie.")

(defvar eerie-insert-state-keymap
  (let ((keymap (make-keymap)))
    (define-key keymap [escape] 'eerie-insert-exit)
    (define-key keymap [remap kmacro-end-or-call-macro] #'eerie-end-or-call-kmacro)
    (define-key keymap [remap kmacro-end-macro] #'eerie-end-kmacro)
    keymap)
  "Keymap for Eerie insert state.")

(defvar eerie-numeric-argument-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "1") 'digit-argument)
    (define-key keymap (kbd "2") 'digit-argument)
    (define-key keymap (kbd "3") 'digit-argument)
    (define-key keymap (kbd "4") 'digit-argument)
    (define-key keymap (kbd "5") 'digit-argument)
    (define-key keymap (kbd "6") 'digit-argument)
    (define-key keymap (kbd "7") 'digit-argument)
    (define-key keymap (kbd "8") 'digit-argument)
    (define-key keymap (kbd "9") 'digit-argument)
    (define-key keymap (kbd "0") 'digit-argument)
    keymap))

(defvar eerie-leader-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "1") 'eerie-digit-argument)
    (define-key keymap (kbd "2") 'eerie-digit-argument)
    (define-key keymap (kbd "3") 'eerie-digit-argument)
    (define-key keymap (kbd "4") 'eerie-digit-argument)
    (define-key keymap (kbd "5") 'eerie-digit-argument)
    (define-key keymap (kbd "6") 'eerie-digit-argument)
    (define-key keymap (kbd "7") 'eerie-digit-argument)
    (define-key keymap (kbd "8") 'eerie-digit-argument)
    (define-key keymap (kbd "9") 'eerie-digit-argument)
    (define-key keymap (kbd "0") 'eerie-digit-argument)
    (define-key keymap (kbd "/") 'eerie-describe-key)
    (define-key keymap (kbd "?") 'eerie-cheatsheet)
    keymap)
  "Leader keymap used by `SPC' bindings.")

(defvar eerie-normal-state-keymap
  (let ((keymap (make-keymap)))
    (suppress-keymap keymap t)
    (define-key keymap (kbd "g") eerie-normal-g-prefix-keymap)
    (define-key keymap (kbd "G") 'eerie-goto-buffer-end)
    (define-key keymap (kbd "$") 'eerie-goto-line-end)
    (define-key keymap (kbd "C-b") 'eerie-left)
    (define-key keymap (kbd "C-f") 'eerie-right)
    (define-key keymap (kbd "h") 'eerie-left)
    (define-key keymap (kbd "j") 'eerie-next)
    (define-key keymap (kbd "k") 'eerie-prev)
    (define-key keymap (kbd "l") 'eerie-right)
    (define-key keymap (kbd "m") 'eerie-multicursor-start)
    (define-key keymap (kbd "C-n") 'eerie-next)
    (define-key keymap (kbd "C-p") 'eerie-prev)
    (define-key keymap (kbd "u") 'eerie-undo)
    (define-key keymap (kbd "x") 'eerie-delete)
    (define-key keymap (kbd "p") 'eerie-yank)
    (define-key keymap (kbd "f") 'eerie-jump-char)
    (define-key keymap (kbd "W") 'eerie-next-space)
    (define-key keymap (kbd "i") 'eerie-insert)
    (define-key keymap (kbd "I") 'eerie-insert-beginning-of-line)
    (define-key keymap (kbd "a") 'eerie-append)
    (define-key keymap (kbd "A") 'eerie-append-end-of-line)
    (define-key keymap (kbd "w") 'eerie-jump-word-occurrence)
    (define-key keymap (kbd "v") 'eerie-visual-start)
    (define-key keymap (kbd "V") 'eerie-visual-line-start)
    (define-key keymap (kbd "C-v") 'eerie-visual-block-start)
    (define-key keymap (kbd "d") 'eerie-operator-delete)
    (define-key keymap (kbd "c") 'eerie-operator-change)
    (define-key keymap (kbd "y") 'eerie-operator-yank)
    (define-key keymap (kbd "/") 'eerie-search-forward)
    (define-key keymap (kbd "?") 'eerie-search-backward)
    (define-key keymap (kbd "n") 'eerie-search-next)
    (define-key keymap (kbd "N") 'eerie-search-prev)
    (define-key keymap (kbd "%") 'eerie-jump-matching)
    (define-key keymap (kbd "C-c") mode-specific-map)
    (define-key keymap (kbd "C-o") 'eerie-jump-back)
    (define-key keymap (kbd "C-i") 'eerie-jump-forward)
    (define-key keymap (kbd "C-x") ctl-x-map)
    (define-key keymap (kbd "SPC") eerie-leader-keymap)
    (define-key keymap (kbd "<escape>") 'ignore)
    (define-key keymap [remap kmacro-end-or-call-macro] #'eerie-end-or-call-kmacro)
    (define-key keymap [remap kmacro-end-macro] #'eerie-end-kmacro)
    keymap)
  "Keymap for Eerie normal state.")

(defvar eerie-visual-state-keymap
  (let ((keymap (make-keymap)))
    (suppress-keymap keymap t)
    (define-key keymap (kbd "h") 'eerie-visual-left)
    (define-key keymap (kbd "j") 'eerie-visual-next)
    (define-key keymap (kbd "k") 'eerie-visual-prev)
    (define-key keymap (kbd "l") 'eerie-visual-right)
    (define-key keymap (kbd "g") eerie-visual-g-prefix-keymap)
    (define-key keymap (kbd "G") 'eerie-visual-goto-buffer-end)
    (define-key keymap (kbd "$") 'eerie-visual-goto-line-end)
    (define-key keymap (kbd "v") 'eerie-visual-exit)
    (define-key keymap (kbd "V") 'eerie-visual-line-start)
    (define-key keymap (kbd "C-v") 'eerie-visual-block-start)
    (define-key keymap (kbd "d") 'eerie-visual-delete)
    (define-key keymap (kbd "c") 'eerie-visual-change)
    (define-key keymap (kbd "y") 'eerie-visual-yank)
    (define-key keymap (kbd "I") 'eerie-visual-insert)
    (define-key keymap (kbd "A") 'eerie-visual-append)
    (define-key keymap (kbd "f") 'eerie-visual-jump-char)
    (define-key keymap (kbd "/") 'eerie-visual-search-forward)
    (define-key keymap (kbd "?") 'eerie-visual-search-backward)
    (define-key keymap (kbd "n") 'eerie-visual-search-next)
    (define-key keymap (kbd "N") 'eerie-visual-search-prev)
    (define-key keymap (kbd "%") 'eerie-visual-jump-matching)
    (define-key keymap (kbd "m") 'eerie-visual-enter-multicursor)
    (define-key keymap (kbd "i") 'eerie-visual-inner-of-thing)
    (define-key keymap (kbd "a") 'eerie-visual-bounds-of-thing)
    (define-key keymap (kbd "SPC") eerie-leader-keymap)
    (define-key keymap (kbd "<escape>") 'eerie-visual-exit)
    keymap)
  "Keymap for Eerie visual state.")

(defvar eerie-multicursor-state-keymap
  (let ((keymap (make-sparse-keymap)))
    (set-keymap-parent keymap eerie-normal-state-keymap)
    (define-key keymap (kbd "<escape>") 'eerie-multicursor-cancel)
    keymap)
  "Keymap for Eerie multi-cursor state.")

(defvar eerie-multicursor-visual-state-keymap
  (let ((keymap (make-sparse-keymap)))
    (set-keymap-parent keymap eerie-visual-state-keymap)
    (define-key keymap (kbd "v") 'eerie-multicursor-visual-exit)
    (define-key keymap (kbd ".") 'eerie-multicursor-match-next)
    (define-key keymap (kbd ",") 'eerie-multicursor-unmatch-last)
    (define-key keymap (kbd "-") 'eerie-multicursor-skip-match)
    (define-key keymap (kbd "<escape>") 'eerie-multicursor-cancel)
    keymap)
  "Keymap for Eerie multi-cursor VISUAL state.")

(defvar eerie-motion-state-keymap
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "h") 'eerie-left)
    (define-key keymap [escape] 'eerie-last-buffer)
    (define-key keymap (kbd "j") 'eerie-next)
    (define-key keymap (kbd "k") 'eerie-prev)
    (define-key keymap (kbd "l") 'eerie-right)
    (define-key keymap (kbd "SPC") eerie-leader-keymap)
    keymap)
  "Keymap for Eerie motion state.")

(defvar eerie-beacon-state-keymap
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map eerie-normal-state-keymap)
    (suppress-keymap map t)

    ;; kmacros
    (define-key map (kbd "c") 'eerie-beacon-change)
    (define-key map (kbd "d") 'eerie-beacon-kill-delete)
    (define-key map (kbd "y") 'eerie-beacon-noop)
    (define-key map (kbd "v") 'eerie-beacon-noop)
    (define-key map (kbd "V") 'eerie-beacon-noop)
    (define-key map (kbd "C-v") 'eerie-beacon-noop)
    (define-key map [remap eerie-insert] 'eerie-beacon-insert)
    (define-key map [remap eerie-append] 'eerie-beacon-append)
    (define-key map [remap eerie-change] 'eerie-beacon-change)
    (define-key map [remap eerie-change-save] 'eerie-beacon-change-save)
    (define-key map [remap eerie-replace] 'eerie-beacon-replace)
    (define-key map [remap eerie-kill] 'eerie-beacon-kill-delete)

    (define-key map [remap kmacro-end-or-call-macro] 'eerie-beacon-apply-kmacro)
    (define-key map [remap kmacro-start-macro-or-insert-counter] 'eerie-beacon-start)
    (define-key map [remap kmacro-start-macro] 'eerie-beacon-start)
    (define-key map [remap eerie-end-or-call-kmacro] 'eerie-beacon-apply-kmacro)
    (define-key map [remap eerie-end-kmacro] 'eerie-beacon-apply-kmacro)

    ;; noops
    (define-key map [remap eerie-delete] 'eerie-beacon-noop)
    (define-key map [remap eerie-C-d] 'eerie-beacon-noop)
    (define-key map [remap eerie-C-k] 'eerie-beacon-noop)
    (define-key map [remap eerie-save] 'eerie-beacon-noop)
    (define-key map [remap eerie-insert-exit] 'eerie-beacon-noop)
    (define-key map [remap eerie-last-buffer] 'eerie-beacon-noop)
    (define-key map [remap eerie-swap-grab] 'eerie-beacon-noop)
    (define-key map [remap eerie-sync-grab] 'eerie-beacon-noop)
    map)
  "Keymap for Eerie cursor state.")

(defvar eerie-keymap-alist
  `((insert . ,eerie-insert-state-keymap)
    (normal . ,eerie-normal-state-keymap)
    (visual . ,eerie-visual-state-keymap)
    (motion . ,eerie-motion-state-keymap)
    (multicursor . ,eerie-multicursor-state-keymap)
    (multicursor-visual . ,eerie-multicursor-visual-state-keymap)
    (beacon . ,eerie-beacon-state-keymap)
    (leader . ,eerie-leader-keymap))
  "Alist of symbols of state names to keymaps.")

(provide 'eerie-keymap)
;;; eerie-keymap.el ends here
