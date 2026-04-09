;;; eerie-shims.el --- Make Eerie play well with other packages.  -*- lexical-binding: t; -*-

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
;; The file contains all the shim code we need to make eerie
;; work with other packages.

;;; Code:

(require 'eerie-var)
(require 'eerie-command)
(require 'delsel)

(declare-function eerie-normal-mode "eerie")
(declare-function eerie-motion-mode "eerie")
(declare-function eerie-insert-exit "eerie-command")

(defun eerie--switch-to-motion (&rest _ignore)
  "Switch to motion state, used for advice.
Optional argument IGNORE ignored."
  (eerie--switch-state 'motion))

(defun eerie--switch-to-normal (&rest _ignore)
  "Switch to normal state, used for advice.
Optional argument IGNORE ignored."
  (eerie--switch-state 'normal))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; undo-tree

(defvar undo-tree-enable-undo-in-region)

(defun eerie--setup-undo-tree (enable)
  "Setup `undo-tree-enable-undo-in-region' for undo-tree.

Command `eerie-undo-in-selection' will call undo-tree undo.

Argument ENABLE non-nill means turn on."
  (when enable (setq undo-tree-enable-undo-in-region t)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eldoc

(defvar eerie--eldoc-setup nil
  "Whether already setup eldoc.")

(defconst eerie--eldoc-commands
  '(eerie-head
    eerie-tail
    eerie-left
    eerie-right
    eerie-prev
    eerie-next
    eerie-insert
    eerie-append)
  "A list of eerie commands that trigger eldoc.")

(defun eerie--setup-eldoc (enable)
  "Setup commands that trigger eldoc.

Basically, all navigation commands should trigger eldoc.
Argument ENABLE non-nill means turn on."
  (setq eerie--eldoc-setup enable)
  (if enable
      (apply #'eldoc-add-command eerie--eldoc-commands)
    (apply #'eldoc-remove-command eerie--eldoc-commands)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; company

(defvar eerie--company-setup nil
  "Whether already setup company.")

(declare-function company--active-p "company")
(declare-function company-abort "company")

(defvar company-candidates)

(defun eerie--company-maybe-abort-advice ()
  "Adviced for `eerie-insert-exit'."
  (when company-candidates
    (company-abort)))

(defun eerie--setup-company (enable)
  "Setup for company.
Argument ENABLE non-nil means turn on."
  (setq eerie--company-setup enable)
  (if enable
      (add-hook 'eerie-insert-exit-hook #'eerie--company-maybe-abort-advice)
    (remove-hook 'eerie-insert-exit-hook #'eerie--company-maybe-abort-advice)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; corfu

(declare-function corfu-quit "corfu")

(defvar eerie--corfu-setup nil
  "Whether already setup corfu.")

(defun eerie--corfu-maybe-abort-advice ()
  "Adviced for `eerie-insert-exit'."
  (when (bound-and-true-p corfu-mode) (corfu-quit)))

(defun eerie--setup-corfu (enable)
  "Setup for corfu.
Argument ENABLE non-nil means turn on."
  (setq eerie--corfu-setup enable)
  (if enable
      (add-hook 'eerie-insert-exit-hook #'eerie--corfu-maybe-abort-advice)
    (remove-hook 'eerie-insert-exit-hook #'eerie--corfu-maybe-abort-advice)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; repeat-map

(defvar eerie--diff-hl-setup nil
  "Whether already setup diff-hl.")

(defun eerie--setup-diff-hl (enable)
  "Setup diff-hl."
  (if enable
      (progn
        (advice-add 'diff-hl-show-hunk-inline-popup :before 'eerie--switch-to-motion)
        (advice-add 'diff-hl-show-hunk-posframe :before 'eerie--switch-to-motion)
        (advice-add 'diff-hl-show-hunk-hide :after 'eerie--switch-to-normal))
    (advice-remove 'diff-hl-show-hunk-inline-popup 'eerie--switch-to-motion)
    (advice-remove 'diff-hl-show-hunk-posframe 'eerie--switch-to-motion)
    (advice-remove 'diff-hl-show-hunk-hide 'eerie--switch-to-normal)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wgrep

(defvar eerie--wgrep-setup nil
  "Whether already setup wgrep.")

(defun eerie--setup-wgrep (enable)
  "Setup wgrep.

We use advice here because wgrep doesn't call its hooks.
Argument ENABLE non-nil means turn on."
  (setq eerie--wgrep-setup enable)
  (if enable
      (progn
        (advice-add 'wgrep-change-to-wgrep-mode :after #'eerie--switch-to-normal)
        (advice-add 'wgrep-exit :after #'eerie--switch-to-motion)
        (advice-add 'wgrep-finish-edit :after #'eerie--switch-to-motion)
        (advice-add 'wgrep-abort-changes :after #'eerie--switch-to-motion)
        (advice-add 'wgrep-save-all-buffers :after #'eerie--switch-to-motion))
    (advice-remove 'wgrep-change-to-wgrep-mode #'eerie--switch-to-normal)
    (advice-remove 'wgrep-exit #'eerie--switch-to-motion)
    (advice-remove 'wgrep-abort-changes #'eerie--switch-to-motion)
    (advice-remove 'wgrep-finish-edit #'eerie--switch-to-motion)
    (advice-remove 'wgrep-save-all-buffers #'eerie--switch-to-motion)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; grep-edit


(defvar eerie--grep-edit-setup nil
  "Wheter already setup grep-edit.")

(defvar grep-edit-mode-hook)

(declare-function grep-edit-save-changes "grep")

(defun eerie--setup-grep-edit (enable)
  "Setup grep-edit.

Argument ENABLE non-nil means turn on."
  (if enable
      (progn
        (add-hook 'grep-edit-mode-hook #'eerie--switch-to-normal)
        (advice-add #'grep-edit-save-changes :after #'eerie--switch-to-motion))
    (remove-hook 'grep-edit-mode-hook #'eerie--switch-to-normal)
    (advice-remove 'grep-edit-save-changes #'eerie--switch-to-motion)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; wdired

(defvar eerie--wdired-setup nil
  "Whether already setup wdired.")

(defvar wdired-mode-hook)

(declare-function wdired-exit "wdired")
(declare-function wdired-finish-edit "wdired")
(declare-function wdired-abort-changes "wdired")

(defun eerie--setup-wdired (enable)
  "Setup wdired.

Argument ENABLE non-nil means turn on."
  (setq eerie--wdired-setup enable)
  (if enable
      (progn
        (add-hook 'wdired-mode-hook #'eerie--switch-to-normal)
        (advice-add #'wdired-exit :after #'eerie--switch-to-motion)
        (advice-add #'wdired-abort-changes :after #'eerie--switch-to-motion)
        (advice-add #'wdired-finish-edit :after #'eerie--switch-to-motion))
    (remove-hook 'wdired-mode-hook #'eerie--switch-to-normal)
    (advice-remove #'wdired-exit #'eerie--switch-to-motion)
    (advice-remove #'wdired-abort-changes #'eerie--switch-to-motion)
    (advice-remove #'wdired-finish-edit #'eerie--switch-to-motion)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; rectangle-mark-mode

(defvar eerie--rectangle-mark-setup nil
  "Whether already setup rectangle-mark.")

(defun eerie--rectangle-mark-init ()
  "Patch the eerie selection type to prevent it from being cancelled."
  (when (bound-and-true-p rectangle-mark-mode)
    (setq eerie--selection
          '((expand . char) 0 0))))

(defun eerie--setup-rectangle-mark (enable)
  "Setup `rectangle-mark-mode'.
Argument ENABLE non-nil means turn on."
  (setq eerie--rectangle-mark-setup enable)
  (if enable
      (add-hook 'rectangle-mark-mode-hook 'eerie--rectangle-mark-init)
    (remove-hook 'rectangle-mark-mode-hook 'eerie--rectangle-mark-init)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; edebug

(defvar eerie--edebug-setup nil)

(defun eerie--edebug-hook-function ()
  "Switch eerie state when entering/leaving edebug."
  (if (bound-and-true-p edebug-mode)
      (eerie--switch-to-motion)
    (eerie--switch-to-normal)))

(defun eerie--setup-edebug (enable)
  "Setup edebug.
Argument ENABLE non-nil means turn on."
  (setq eerie--edebug-setup enable)
  (if enable
      (add-hook 'edebug-mode-hook 'eerie--edebug-hook-function)
    (remove-hook 'edebug-mode-hook 'eerie--edebug-hook-function)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; magit

(defvar eerie--magit-setup nil)

(defun eerie--magit-blame-hook-function ()
  "Switch eerie state when entering/leaving `magit-blame-read-only-mode'."
  (if (bound-and-true-p magit-blame-read-only-mode)
      (eerie--switch-to-motion)
    (eerie--switch-to-normal)))

(defun eerie--setup-magit (enable)
  "Setup magit.
Argument ENABLE non-nil means turn on."
  (setq eerie--magit-setup enable)
  (if enable
      (add-hook 'magit-blame-mode-hook 'eerie--magit-blame-hook-function)
    (remove-hook 'magit-blame-mode-hook 'eerie--magit-blame-hook-function)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; cider (debug)

(defvar eerie--cider-setup nil)

(defun eerie--cider-debug-hook-function ()
  "Switch eerie state when entering/leaving cider debug."
  (if (bound-and-true-p cider--debug-mode)
      (eerie--switch-to-motion)
    (eerie--switch-to-normal)))

(defun eerie--setup-cider (enable)
  "Setup cider.
Argument ENABLE non-nil means turn on."
  (setq eerie--cider-setup enable)
  (if enable
      (add-hook 'cider--debug-mode-hook 'eerie--cider-debug-hook-function)
    (remove-hook 'cider--debug-mode-hook 'eerie--cider-debug-hook-function)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; sly (db)

(defvar eerie--sly-setup nil)

(defun eerie--sly-debug-hook-function ()
  "Switch eerie state when entering/leaving sly-db-mode."
  (if (bound-and-true-p sly-db-mode-hook)
      (eerie--switch-to-motion)
    (eerie--switch-to-motion)))

(defun eerie--setup-sly (enable)
  "Setup sly.
Argument ENABLE non-nil means turn on."
  (setq eerie--sly-setup enable)
  (if enable
      (add-hook 'sly-db-hook 'eerie--sly-debug-hook-function)
    (remove-hook 'sly-db-hook 'eerie--sly-debug-hook-function)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; macrostep

(defvar macrostep-overlays)
(defvar macrostep-mode)

(defvar eerie--macrostep-setup nil)
(defvar eerie--macrostep-setup-previous-state nil)

(defun eerie--macrostep-inside-overlay-p ()
  "Return whether point is inside a `macrostep-mode' overlay."
  (seq-some (let ((pt (point)))
              (lambda (ov)
                (and (<= (overlay-start ov) pt)
                     (< pt (overlay-end ov)))))
            macrostep-overlays))

(defun eerie--macrostep-post-command-function ()
  "Function to run in `post-commmand-hook' when `macrostep-mode' is enabled.

`macrostep-mode' uses a local keymap for the overlay showing the
expansion.  Switch to Motion state when we enter the overlay and
try to switch back to the previous state when leaving it."
  (if (eerie--macrostep-inside-overlay-p)
      ;; The overlay is not editable, so the `macrostep-mode' commands are
      ;; likely more important than the Beacon-state commands and possibly more
      ;; important than any custom-state commands.
      (eerie--switch-to-motion)
    (eerie--switch-state eerie--macrostep-setup-previous-state)))

(defun eerie--macrostep-record-outside-state (state)
  "Record the Eerie STATE in most circumstances, so that we can return to it later.

This function receives the STATE to which one switches via `eerie--switch-state'
inside `eerie-switch-state-hook'.

Record the state if:
- We are outside the overlay.
- We are inside the overlay and not in Motion state."
  ;; We assume that the user will not try to switch to Motion state for the
  ;; entire buffer while we are already in Motion state while inside an overlay.
  (if (not (eerie--macrostep-inside-overlay-p))
      (setq-local eerie--macrostep-setup-previous-state state)
    (unless (eq state 'motion)
      (setq-local eerie--macrostep-setup-previous-state state))))

(defun eerie--macrostep-hook-function ()
  "Switch Eerie state when entering/leaving `macrostep-mode' or its overlays."
  (if macrostep-mode
      (progn
        (setq-local eerie--macrostep-setup-previous-state eerie--current-state)
        ;; Add to end of `post-command-hook', so that this function is run after
        ;; the check for whether we should switch to Beacon state.
        (add-hook 'post-command-hook #'eerie--macrostep-post-command-function 90 t)
        (add-hook 'eerie-switch-state-hook #'eerie--macrostep-record-outside-state nil t))
    ;; The command `macrostep-collapse' does not seem to trigger
    ;; `post-command-hook', so we switch back manually.
    (eerie--switch-state eerie--macrostep-setup-previous-state)
    (setq-local eerie--macrostep-setup-previous-state nil)
    (remove-hook 'eerie-switch-state-hook #'eerie--macrostep-record-outside-state t)
    (remove-hook 'post-command-hook #'eerie--macrostep-post-command-function t)))

(defun eerie--setup-macrostep (enable)
  "Setup macrostep.
Argument ENABLE non-nil means turn on."
  (setq eerie--macrostep-setup enable)
  (if enable
      (add-hook 'macrostep-mode-hook 'eerie--macrostep-hook-function)
    (remove-hook 'macrostep-mode-hook 'eerie--macrostep-hook-function)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; realgud (debug)

(defvar eerie--realgud-setup nil)

(defun eerie--realgud-debug-hook-function ()
  "Switch eerie state when entering/leaving realgud-short-key-mode."
  (if (bound-and-true-p realgud-short-key-mode)
      (eerie--switch-to-motion)
    (eerie--switch-to-normal)))

(defun eerie--setup-realgud (enable)
  "Setup realgud.
Argument ENABLE non-nil means turn on."
  (setq eerie--realgud-setup enable)
  (if enable
      (add-hook 'realgud-short-key-mode-hook 'eerie--realgud-debug-hook-function)
    (remove-hook 'realgud-short-key-mode-hook 'eerie--realgud-debug-hook-function)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; input methods

(defvar eerie--input-method-setup nil)

(defun eerie--input-method-advice (fnc key)
  "Advice for `quail-input-method'.

Only use the input method in insert mode.
Argument FNC, input method function.
Argument KEY, the current input."
  (funcall (if (and (boundp 'eerie-mode) eerie-mode (not (eerie-insert-mode-p))) #'list fnc) key))

(defun eerie--setup-input-method (enable)
  "Setup input-method.
Argument ENABLE non-nil means turn on."
  (setq eerie--input-method-setup enable)
  (if enable
      (advice-add 'quail-input-method :around 'eerie--input-method-advice)
    (advice-remove 'quail-input-method 'eerie--input-method-advice)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ddskk

(defvar skk-henkan-mode)

(defvar eerie--ddskk-setup nil)
(defun eerie--ddskk-skk-previous-candidate-advice (fnc &optional arg)
  (if (and (not (eq skk-henkan-mode 'active))
           (not (eq last-command 'skk-kakutei-henkan))
           last-command-event
           (eq last-command-event
               (seq-first (car (where-is-internal
                                'eerie-prev
                                eerie-normal-state-keymap)))))
      (forward-line -1)
    (funcall fnc arg)))

(defun eerie--setup-ddskk (enable)
  (setq eerie--ddskk-setup enable)
  (if enable
      (advice-add 'skk-previous-candidate :around
                  'eerie--ddskk-skk-previous-candidate-advice)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; polymode

(defvar polymode-move-these-vars-from-old-buffer)

(defvar eerie--polymode-setup nil)

(defun eerie--setup-polymode (enable)
  "Setup polymode.

Argument ENABLE non-nil means turn on."
  (setq eerie--polymode-setup enable)
  (when enable
    (dolist (v '(eerie--selection
                 eerie--selection-history
                 eerie--current-state
                 eerie-normal-mode
                 eerie-insert-mode
                 eerie-beacon-mode
                 eerie-motion-mode))
      ;; These vars allow us the select through the polymode chunk
      (add-to-list 'polymode-move-these-vars-from-old-buffer v))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; eat-eshell

(defvar eerie--eat-eshell-setup nil)
(defvar eerie--eat-eshell-mode-override nil)

(declare-function eat-eshell-emacs-mode "eat")
(declare-function eat-eshell-semi-char-mode "eat")
(declare-function eat-eshell-char-mode "eat")

(declare-function eerie-insert-mode "eerie-core")

(defun eerie--eat-eshell-mode-override-enable ()
  (setq-local eerie--eat-eshell-mode-override t)
  (add-hook 'eerie-insert-enter-hook #'eat-eshell-char-mode nil t)
  (add-hook 'eerie-insert-exit-hook #'eat-eshell-emacs-mode nil t)
  (if (bound-and-true-p eerie-insert-mode)
      (eat-eshell-char-mode)
    (eat-eshell-emacs-mode)))

(defun eerie--eat-eshell-mode-override-disable ()
  (setq-local eerie--eat-eshell-mode-override nil)
  (remove-hook 'eerie-insert-enter-hook #'eat-eshell-char-mode t)
  (remove-hook 'eerie-insert-exit-hook #'eat-eshell-emacs-mode t))

(defun eerie--setup-eat-eshell (enable)
  (setq eerie--eat-eshell-setup enable)
  (if enable
      (progn (add-hook 'eat-eshell-exec-hook #'eerie--eat-eshell-mode-override-enable)
             (add-hook 'eat-eshell-exit-hook #'eerie--eat-eshell-mode-override-disable)
             (add-hook 'eat-eshell-exit-hook #'eerie--update-cursor))

    (remove-hook 'eat-eshell-exec-hook #'eerie--eat-eshell-mode-override-enable)
    (remove-hook 'eat-eshell-exit-hook #'eerie--eat-eshell-mode-override-disable)
    (remove-hook 'eat-eshell-exit-hook #'eerie--update-cursor)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Ediff
(defvar eerie--ediff-setup nil)

(defun eerie--setup-ediff (enable)
  "Setup Ediff.
Argument ENABLE, non-nil means turn on."
  (if enable
      (add-hook 'ediff-mode-hook 'eerie-motion-mode)
    (remove-hook 'ediff-mode-hook 'eerie-motion-mode)))

;; Enable / Disable shims

(defun eerie--enable-shims ()
  "Use a bunch of shim setups."
  ;; This lets us start input without canceling selection.
  ;; We will backup `delete-active-region'.
  (setq eerie--backup-var-delete-activate-region delete-active-region)
  (setq delete-active-region nil)
  (eerie--setup-eldoc t)
  (eerie--setup-rectangle-mark t)

  (eval-after-load "macrostep" (lambda () (eerie--setup-macrostep t)))
  (eval-after-load "wdired" (lambda () (eerie--setup-wdired t)))
  (eval-after-load "edebug" (lambda () (eerie--setup-edebug t)))
  (eval-after-load "magit" (lambda () (eerie--setup-magit t)))
  (eval-after-load "wgrep" (lambda () (eerie--setup-wgrep t)))
  (eval-after-load "grep" (lambda () (eerie--setup-grep-edit t)))
  (eval-after-load "company" (lambda () (eerie--setup-company t)))
  (eval-after-load "corfu" (lambda () (eerie--setup-corfu t)))
  (eval-after-load "polymode" (lambda () (eerie--setup-polymode t)))
  (eval-after-load "cider" (lambda () (eerie--setup-cider t)))
  (eval-after-load "sly" (lambda () (eerie--setup-sly t)))
  (eval-after-load "realgud" (lambda () (eerie--setup-realgud t)))
  (eval-after-load "undo-tree" (lambda () (eerie--setup-undo-tree t)))
  (eval-after-load "diff-hl" (lambda () (eerie--setup-diff-hl t)))
  (eval-after-load "quail" (lambda () (eerie--setup-input-method t)))
  (eval-after-load "skk" (lambda () (eerie--setup-ddskk t)))
  (eval-after-load "eat" (lambda () (eerie--setup-eat-eshell t)))
  (eval-after-load "ediff" (lambda () (eerie--setup-ediff t))))

(defun eerie--disable-shims ()
  "Remove shim setups."
  (setq delete-active-region eerie--backup-var-delete-activate-region)
  (when eerie--macrostep-setup (eerie--setup-macrostep nil))
  (when eerie--eldoc-setup (eerie--setup-eldoc nil))
  (when eerie--rectangle-mark-setup (eerie--setup-rectangle-mark nil))
  (when eerie--wdired-setup (eerie--setup-wdired nil))
  (when eerie--edebug-setup (eerie--setup-edebug nil))
  (when eerie--magit-setup (eerie--setup-magit nil))
  (when eerie--company-setup (eerie--setup-company nil))
  (when eerie--corfu-setup (eerie--setup-corfu nil))
  (when eerie--wgrep-setup (eerie--setup-wgrep nil))
  (when eerie--grep-edit-setup (eerie--setup-grep-edit nil))
  (when eerie--polymode-setup (eerie--setup-polymode nil))
  (when eerie--cider-setup (eerie--setup-cider nil))
  (when eerie--diff-hl-setup (eerie--setup-diff-hl nil))
  (when eerie--input-method-setup (eerie--setup-input-method nil))
  (when eerie--ddskk-setup (eerie--setup-ddskk nil))
  (when eerie--eat-eshell-setup (eerie--setup-eat-eshell nil))
  (when eerie--ediff-setup (eerie--setup-ediff nil)))

;;; eerie-shims.el ends here
(provide 'eerie-shims)
