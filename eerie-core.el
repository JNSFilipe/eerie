;;; eerie-core.el --- Mode definitions for Eerie  -*- lexical-binding: t; -*-

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

;;; Modes definition in Eerie.

;;; Code:

(require 'cl-lib)
(require 'subr-x)

(require 'eerie-util)
(require 'eerie-command)
(require 'eerie-keypad)
(require 'eerie-var)
(require 'eerie-esc)
(require 'eerie-shims)
(require 'eerie-beacon)
(require 'eerie-helpers)

(eerie-define-state insert
  "Eerie INSERT state minor mode."
  :lighter " [I]"
  :keymap eerie-insert-state-keymap
  :face eerie-insert-cursor
  (if eerie-insert-mode
      (run-hooks 'eerie-insert-enter-hook)
    (when (and eerie--insert-pos
               (not (= (point) eerie--insert-pos)))
      (thread-first
        (eerie--make-selection '(select . transient) eerie--insert-pos (point))
        (eerie--select eerie--insert-activate-mark)))
    (run-hooks 'eerie-insert-exit-hook)
    (setq-local eerie--insert-pos nil
                eerie--insert-activate-mark nil)))

(eerie-define-state normal
  "Eerie NORMAL state minor mode."
  :lighter " [N]"
  :keymap eerie-normal-state-keymap
  :face eerie-normal-cursor)

(eerie-define-state visual
  "Eerie VISUAL state minor mode."
  :lighter " [V]"
  :keymap eerie-visual-state-keymap
  :face eerie-visual-cursor
  (unless eerie-visual-mode
    (setq-local eerie--visual-type nil
                eerie--visual-line-anchor nil)
    (when (bound-and-true-p rectangle-mark-mode)
      (rectangle-mark-mode -1))
    (when (region-active-p)
      (eerie--cancel-selection))))

(eerie-define-state motion
  "Eerie MOTION state minor mode."
  :lighter " [M]"
  :keymap eerie-motion-state-keymap
  :face eerie-motion-cursor)

(eerie-define-state multicursor
  "Eerie multi-cursor NORMAL-like state."
  :lighter " [MC]"
  :keymap eerie-multicursor-state-keymap
  :face eerie-beacon-cursor)

(eerie-define-state multicursor-visual
  "Eerie multi-cursor VISUAL-like state."
  :lighter " [MCV]"
  :keymap eerie-multicursor-visual-state-keymap
  :face eerie-beacon-cursor
  (unless eerie-multicursor-visual-mode
    (setq-local eerie--visual-type nil
                eerie--visual-line-anchor nil)
    (when (bound-and-true-p rectangle-mark-mode)
      (rectangle-mark-mode -1))
    (when (region-active-p)
      (eerie--cancel-selection))))

(eerie-define-state keypad
  "Eerie KEYPAD state minor mode."
  :lighter " [K]"
  :face eerie-keypad-cursor
  (when eerie-keypad-mode
    (setq eerie--prefix-arg current-prefix-arg
          eerie--keypad-keymap-description-activated nil
          eerie--keypad-base-keymap nil
          eerie--use-literal nil
          eerie--use-meta nil
          eerie--use-both nil)))

(eerie-define-state beacon
  "Eerie BEACON state minor mode."
  :lighter " [B]"
  :keymap eerie-beacon-state-keymap
  :face eerie-beacon-cursor
  (if eerie-beacon-mode
      (progn
        (setq eerie--beacon-backup-hl-line (bound-and-true-p hl-line-mode)
              eerie--beacon-defining-kbd-macro nil)
        (hl-line-mode -1))
    (when eerie--beacon-backup-hl-line
      (hl-line-mode 1))))

;;;###autoload
(define-minor-mode eerie-mode
  "Eerie minor mode.

This minor mode is used by eerie-global-mode, should not be enabled directly."
  :init-value nil
  :interactive nil
  :global nil
  :keymap eerie-keymap
  (if eerie-mode
      (eerie--enable)
    (eerie--disable)))

;;;###autoload
(defun eerie-indicator ()
  "Indicator showing current mode."
  (or eerie--indicator (eerie--update-indicator)))

;;;###autoload
(define-global-minor-mode eerie-global-mode eerie-mode
  (lambda ()
    (unless (minibufferp)
      (eerie-mode 1)))
  :group 'eerie
  (if eerie-mode
      (eerie--global-enable)
    (eerie--global-disable)))

(defun eerie--enable ()
  "Enable Eerie.

This function will switch to the proper state for current major
mode. Firstly, the variable `eerie-mode-state-list' will be used.
If current major mode derived from any mode from the list,
specified state will be used.  When no result is found, give a
test on the commands bound to the keys a-z. If any of the command
names contains \"self-insert\", then NORMAL state will be used.
Otherwise, MOTION state will be used.

Note: When this function is called, NORMAL state is already
enabled.  NORMAL state is enabled globally when
`eerie-global-mode' is used, because in `fundamental-mode',
there's no chance for eerie to call an init function."
  (eerie--enable-jump-tracking)
  (add-hook 'kill-buffer-hook #'eerie--disable-jump-tracking nil t)
  (let ((state (eerie--mode-get-state)))
    (eerie--disable-current-state)
    (eerie--switch-state state t)))

(defun eerie--disable ()
  "Disable Eerie."
  (eerie--multiedit-reset-state)
  (eerie--multicursor-reset-state)
  (remove-hook 'kill-buffer-hook #'eerie--disable-jump-tracking t)
  (eerie--disable-jump-tracking)
  (mapc (lambda (state-mode) (funcall (cdr state-mode) -1)) eerie-state-mode-alist)
  (eerie--beacon-remove-overlays)
  (when (secondary-selection-exist-p)
    (eerie--cancel-second-selection)))

(defun eerie--enable-theme-advice (theme)
  "Prepare face if the THEME to enable is `user'."
  (when (eq theme 'user)
    (eerie--prepare-face)))

(defun eerie--global-enable ()
  "Enable eerie globally."
  (setq-default eerie-normal-mode t)
  (eerie--init-buffers)
  (add-hook 'window-state-change-functions #'eerie--on-window-state-change)
  (add-hook 'minibuffer-setup-hook #'eerie--minibuffer-setup)
  (add-hook 'pre-command-hook 'eerie--highlight-pre-command)
  (add-hook 'post-command-hook 'eerie--maybe-toggle-beacon-state)
  (add-hook 'suspend-hook 'eerie--on-exit)
  (add-hook 'suspend-resume-hook 'eerie--update-cursor)
  (add-hook 'kill-emacs-hook 'eerie--on-exit)
  (add-hook 'desktop-after-read-hook 'eerie--init-buffers)

  (eerie--enable-shims)
  ;; eerie-esc-mode fix ESC in TUI
  (eerie-esc-mode 1)
  ;; raise Eerie keymap priority
  (add-to-ordered-list 'emulation-mode-map-alists
                       `((eerie-motion-mode . ,eerie-motion-state-keymap)))
  (add-to-ordered-list 'emulation-mode-map-alists
                       `((eerie-normal-mode . ,eerie-normal-state-keymap)))
  (add-to-ordered-list 'emulation-mode-map-alists
                       `((eerie-visual-mode . ,eerie-visual-state-keymap)))
  (add-to-ordered-list 'emulation-mode-map-alists
                       `((eerie-multicursor-mode . ,eerie-multicursor-state-keymap)))
  (add-to-ordered-list 'emulation-mode-map-alists
                       `((eerie-multicursor-visual-mode . ,eerie-multicursor-visual-state-keymap)))
  (add-to-ordered-list 'emulation-mode-map-alists
                       `((eerie-beacon-mode . ,eerie-beacon-state-keymap)))
  (when eerie-use-cursor-position-hack
    (setq redisplay-highlight-region-function #'eerie--redisplay-highlight-region-function)
    (setq redisplay-unhighlight-region-function #'eerie--redisplay-unhighlight-region-function))
  (eerie--prepare-face)
  (advice-add 'enable-theme :after 'eerie--enable-theme-advice))

(defun eerie--global-disable ()
  "Disable Eerie globally."
  (setq-default eerie-normal-mode nil)
  (remove-hook 'window-state-change-functions #'eerie--on-window-state-change)
  (remove-hook 'minibuffer-setup-hook #'eerie--minibuffer-setup)
  (remove-hook 'pre-command-hook 'eerie--highlight-pre-command)
  (remove-hook 'post-command-hook 'eerie--maybe-toggle-beacon-state)
  (remove-hook 'suspend-hook 'eerie--on-exit)
  (remove-hook 'suspend-resume-hook 'eerie--update-cursor)
  (remove-hook 'kill-emacs-hook 'eerie--on-exit)
  (remove-hook 'desktop-after-read-hook 'eerie--init-buffers)
  (eerie--disable-shims)
  (eerie--remove-modeline-indicator)
  (when eerie-use-cursor-position-hack
    (setq redisplay-highlight-region-function eerie--backup-redisplay-highlight-region-function)
    (setq redisplay-unhighlight-region-function eerie--backup-redisplay-unhighlight-region-function))
  (eerie-esc-mode -1)
  (advice-remove 'enable-theme 'eerie--enable-theme-advice))

(provide 'eerie-core)
;;; eerie-core.el ends here
