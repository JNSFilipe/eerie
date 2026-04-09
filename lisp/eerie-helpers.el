;;; eerie-helpers.el --- Eerie helpers for customization  -*- lexical-binding: t; -*-

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
;;
;; Define custom keys in a state with function `eerie-define-keys'.
;; Define custom keys in normal map with function `eerie-normal-define-key'.
;; Define custom keys in global leader map with function `eerie-leader-define-key'.
;; Define custom keys in leader map for specific mode with function `eerie-leader-define-mode-key'.
;; Define a custom state with the macro `eerie-define-state'
;;; Code:

(require 'cl-lib)

(require 'eerie-util)
(require 'eerie-var)
(require 'eerie-keymap)

(defun eerie-intern (name suffix &optional two-dashes prefix)
  "Convert a string into a eerie symbol. Macro helper.
Concat the string PREFIX or \"eerie\" if PREFIX is null, either
one or two hyphens based on TWO-DASHES, the string NAME, and the
string SUFFIX. Then, convert this string into a symbol."
  (intern (concat (if prefix prefix "eerie") (if two-dashes "--" "-")
                  name suffix)))

(defun eerie-define-keys (state &rest keybinds)
  "Define KEYBINDS in STATE.

Example usage:
  (eerie-define-keys
    ;; state
    \\='normal

    ;; bind to a command
    \\='(\"a\" . eerie-append)

    ;; bind to a keymap
    (cons \"x\" ctl-x-map)

    ;; bind to a keybinding which holds a keymap
    \\='(\"c\" . \"C-c\")

    ;; bind to a keybinding which holds a command
    \\='(\"q\" . \"C-x C-q\"))"
  (declare (indent 1))
  (let ((map (alist-get state eerie-keymap-alist)))
    (pcase-dolist (`(,key . ,def) keybinds)
      (define-key map (kbd key) (eerie--parse-def def)))))

(defun eerie-normal-define-key (&rest keybinds)
  "Define key for NORMAL state with KEYBINDS.

Example usage:
  (eerie-normal-define-key
    ;; bind to a command
    \\='(\"a\" . eerie-append)

    ;; bind to a keymap
    (cons \"x\" ctl-x-map)

    ;; bind to a keybinding which holds a keymap
    \\='(\"c\" . \"C-c\")

    ;; bind to a keybinding which holds a command
    \\='(\"q\" . \"C-x C-q\"))"
  (apply #'eerie-define-keys 'normal keybinds))

(defun eerie-visual-define-key (&rest keybinds)
  "Define key for VISUAL state with KEYBINDS.

Check `eerie-normal-define-key' for usages."
  (apply #'eerie-define-keys 'visual keybinds))

(defun eerie-leader-define-key (&rest keybinds)
  "Define key in leader keymap with KEYBINDS.

Eerie uses a dedicated leader keymap behind `SPC'.

Check `eerie-normal-define-key' for usages."
  (apply #'eerie-define-keys 'leader keybinds))

(defun eerie-motion-define-key (&rest keybinds)
  "Define key for MOTION state.

Check `eerie-normal-define-key' for usages."
  (apply #'eerie-define-keys 'motion keybinds))

(defalias 'eerie-motion-overwrite-define-key 'eerie-motion-define-key)
(make-obsolete 'eerie-motion-overwrite-define-key 'eerie-motion-define-key "1.6.0")

(defun eerie-setup-line-number ()
  (add-hook 'display-line-numbers-mode-hook #'eerie--toggle-relative-line-number)
  (add-hook 'eerie-insert-mode-hook #'eerie--toggle-relative-line-number))

(defun eerie-setup-indicator ()
  "Setup indicator appending the return of function
`eerie-indicator' to the modeline.

This function should be called after you setup other parts of the mode-line
 and will work well for most cases.

If this function is not enough for your requirements,
use `eerie-indicator' to get the raw text for indicator
and put it anywhere you want."
  (unless (cl-find '(:eval (eerie-indicator)) mode-line-format :test 'equal)
    (setq-default mode-line-format (append '((:eval (eerie-indicator))) mode-line-format))))

(defun eerie--define-state-minor-mode (name
                                      init-value
                                      description
                                      keymap
                                      lighter
                                      form)
  "Generate a minor mode definition with name eerie-NAME-mode,
DESCRIPTION and LIGHTER."
  `(define-minor-mode ,(eerie-intern name "-mode")
     ,description
     :init-value ,init-value
     :lighter ,lighter
     :keymap ,keymap
     (if (not ,(eerie-intern name "-mode"))
	 (setq-local eerie--current-state nil)
       (eerie--disable-current-state)
       (setq-local eerie--current-state ',(intern name))
       (eerie-update-display))
     ,form))

(defun eerie--define-state-active-p (name)
  "Generate a predicate function to check if eerie-NAME-mode is
currently active. Function is named eerie-NAME-mode-p."
  `(defun ,(eerie-intern name "-mode-p") ()
     ,(concat "Whether " name " mode is enabled.\n"
              "Generated by eerie-define-state-active-p")
     (bound-and-true-p ,(eerie-intern name "-mode"))))

(defun eerie--define-state-cursor-type (name)
  "Generate a cursor type eerie-cursor-type-NAME."
  `(defvar ,(eerie-intern name nil nil "eerie-cursor-type")
     eerie-cursor-type-default))

(defun eerie--define-state-cursor-function (name &optional face)
  `(defun ,(eerie-intern name nil nil "eerie--update-cursor") ()
     (eerie--set-cursor-type ,(eerie-intern name nil nil "eerie-cursor-type"))
     (eerie--set-cursor-color ',(if face face 'eerie-unknown-cursor))))

(defun eerie-register-state (name mode activep cursorf &optional keymap)
  "Register a custom state with symbol NAME and symbol MODE
associated with it. ACTIVEP is a function that returns t if the
state is active, nil otherwise. CURSORF is a function that
updates the cursor when the state is entered. For help with
making a working CURSORF, check the variable
eerie-update-cursor-functions-alist and the utility functions
eerie--set-cursor-type and eerie--set-cursor-color."
  (add-to-list 'eerie-state-mode-alist `(,name . ,mode))
  (add-to-list 'eerie-replace-state-name-list
               `(,name . ,(upcase (symbol-name name))))
  (add-to-list 'eerie-update-cursor-functions-alist
               `(,activep . ,cursorf))
  (when keymap
    (add-to-list 'eerie-keymap-alist `(,name . ,keymap))))

;;;###autoload
(defmacro eerie-define-state (name-sym
                             description
                             &rest body)
  "Define a custom eerie state.

The state will be called NAME-SYM, and have description
DESCRIPTION. Following these two arguments, pairs of keywords and
values should be passed, similarly to define-minor-mode syntax.

Recognized keywords:
:keymap - the keymap to use for the state
:lighter - the text to display in the mode line while state is active
:face - custom cursor face

The last argument is an optional lisp form that will be run when the minor
mode turns on AND off. If you want to hook into only the turn-on event,
check whether (eerie-NAME-SYM-mode) is true.

Example usage:
(eerie-define-state mystate
  \"My eerie state\"
  :lighter \" [M]\"
  :keymap \\='my-keymap
  (message \"toggled state\"))

Also see eerie-register-state, which is used internally by this
function, if you want more control over defining your state. This
is more helpful if you already have a keymap and defined minor
mode that you only need to integrate with eerie.

This function produces several items:
1. eerie-NAME-mode: a minor mode for the state. This is the main entry point.
2. eerie-NAME-mode-p: a predicate for whether the state is active.
3. eerie-cursor-type-NAME: a variable for the cursor type for the state.
4. eerie--update-cursor-NAME: a function that sets the cursor type to 3.
 and face FACE or \\='eerie-unknown cursor if FACE is nil."
  (declare (indent 1))
  (let ((name       (symbol-name name-sym))
        (init-value (plist-get body :init-value))
        (keymap     (plist-get body :keymap))
        (lighter    (plist-get body :lighter))
        (face       (plist-get body :face))
        (form       (unless (cl-evenp (length body))
                    (car (last body)))))
    `(progn
       ,(eerie--define-state-active-p name)
       ,(eerie--define-state-minor-mode name init-value description keymap lighter form)
       ,(eerie--define-state-cursor-type name)
       ,(eerie--define-state-cursor-function name face)
       (eerie-register-state ',(intern name) ',(eerie-intern name "-mode")
                            ',(eerie-intern name "-mode-p")
                            #',(eerie-intern name nil nil
					    "eerie--update-cursor")
			    ,keymap))))

(defun eerie--is-self-insertp (cmd)
  (and (symbolp cmd)
       (string-match-p "\\`.*self-insert.*\\'"
                       (symbol-name cmd))))

(defun eerie--mode-guess-state ()
  "Get initial state for current major mode.
If any of the keys a-z are bound to self insert, then we should
probably start in normal mode, otherwise we start in motion."
  (let ((state eerie--current-state))
    (eerie--disable-current-state)
    (let* ((letters (split-string "abcdefghijklmnopqrstuvwxyz" "" t))
           (bindings (mapcar #'key-binding letters))
           (any-self-insert (cl-some #'eerie--is-self-insertp bindings)))
      (eerie--switch-state state t)
      (if any-self-insert
          'normal
        'motion))))

(defun eerie--mode-get-state (&optional mode)
  "Get initial state for MODE or current major mode if and only if
MODE is nil."
  (let* ((mode (if mode mode major-mode))
         (parent-mode (get mode 'derived-mode-parent))
         (state (alist-get mode eerie-mode-state-list)))
    (cond
     (state state)
     (parent-mode (eerie--mode-get-state parent-mode))
     (t (eerie--mode-guess-state)))))

(provide 'eerie-helpers)
;;; eerie-helpers.el ends here
