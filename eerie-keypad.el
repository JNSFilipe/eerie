;;; eerie-keypad.el --- Eerie keypad mode -*- lexical-binding: t -*-

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
;; Keypad state is a special state to simulate C-x and C-c key sequences.
;;
;; Useful commands:
;;
;; eerie-keypad
;; Enter keypad state.
;;
;; eerie-keypad-start
;; Enter keypad state, and simulate this key with Control modifier.
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'eerie-var)
(require 'eerie-util)
(require 'eerie-helpers)
(require 'eerie-beacon)

(defun eerie--keypad-format-upcase (k)
  "Return S-k for upcase K."
  (let ((case-fold-search nil))
    (if (and (stringp k)
             (string-match-p "^[A-Z]$" k))
        (format "S-%s" (downcase k))
      k)))

(defun eerie--keypad-format-key-1 (key)
  "Return a display format for input KEY."
  (cl-case (car key)
    (meta (format "M-%s" (cdr key)))
    (control (format "C-%s" (eerie--keypad-format-upcase (cdr key))))
    (both (format "C-M-%s" (eerie--keypad-format-upcase (cdr key))))
    (literal (cdr key))))

(defun eerie--keypad-format-prefix ()
  "Return a display format for current prefix."
  (cond
   ((equal '(4) eerie--prefix-arg)
    "C-u ")
   (eerie--prefix-arg
    (format "%s " eerie--prefix-arg))
   (t "")))

(defun eerie--keypad-lookup-key (keys)
  "Lookup the command which is bound at KEYS."
  (let* ((keybind (if eerie--keypad-base-keymap
		      (lookup-key eerie--keypad-base-keymap keys)
		    (key-binding keys))))
    keybind))

(defun eerie--keypad-has-sub-meta-keymap-p ()
  "Check if there's a keymap belongs to Meta prefix.

A key sequences starts with ESC is accessible via Meta key."
  (and (not eerie--use-literal)
       (not eerie--use-both)
       (not eerie--use-meta)
       (or (not eerie--keypad-keys)
           (let* ((key-str (eerie--keypad-format-keys nil))
                  (keymap (eerie--keypad-lookup-key (kbd key-str))))
             (and (keymapp keymap)
                  (lookup-key keymap ""))))))

(defun eerie--keypad-format-keys (&optional prompt)
  "Return a display format for current input keys.

The message is prepended with an optional PROMPT."
  (let ((result ""))
    (setq result
          (thread-first
              (mapcar #'eerie--keypad-format-key-1 eerie--keypad-keys)
            (reverse)
            (string-join " ")))
    (cond
     (eerie--use-both
      (setq result
            (if (string-empty-p result)
                "C-M-"
              (concat result " C-M-"))))
     (eerie--use-meta
      (setq result
            (if (string-empty-p result)
                "M-"
              (concat result " M-"))))
     (eerie--use-literal
      (setq result (concat result " ○")))

     (prompt
      (setq result (concat result " C-"))))
    result))

(defun eerie--keypad-quit ()
  "Quit keypad state."
  (setq eerie--keypad-keys nil
        eerie--use-literal nil
        eerie--use-meta nil
        eerie--use-both nil
        eerie--keypad-help nil)
  (eerie--keypad-clear-message)
  (eerie--exit-keypad-state)
  ;; Return t to indicate the keypad loop should be stopped
  t)

(defun eerie-keypad-quit ()
  "Quit keypad state."
  (interactive)
  (setq this-command last-command)
  (when eerie-keypad-message
    (message "KEYPAD exit"))
  (eerie--keypad-quit))

(defun eerie--make-keymap-for-describe (keymap control)
  "Parse the KEYMAP to make it suitable for describe.

Argument CONTROL, non-nils stands for current input is prefixed with Control."
  (let ((km (make-keymap)))
    (suppress-keymap km t)
    (when (keymapp keymap)
      (map-keymap
       (lambda (key def)
         (unless (member (event-basic-type key) '(127))
           (when (if control (member 'control (event-modifiers key))
                   (not (member 'control (event-modifiers key))))
             (define-key km (vector (eerie--get-event-key key))
                         (funcall eerie-keypad-get-title-function def)))))
       keymap))
    km))

(defun eerie--keypad-get-keymap-for-describe ()
  "Get a keymap for describe."
  (let* ((input (thread-first
                  (mapcar #'eerie--keypad-format-key-1 eerie--keypad-keys)
                  (reverse)
                  (string-join " ")))
         (meta-both-keymap (eerie--keypad-lookup-key
                            (read-kbd-macro
                             (if (string-blank-p input)
                                 "ESC"
                               (concat input " ESC"))))))
    (cond
     (eerie--use-meta
      (when meta-both-keymap
        (eerie--make-keymap-for-describe meta-both-keymap nil)))
     (eerie--use-both
      (when meta-both-keymap
        (eerie--make-keymap-for-describe meta-both-keymap t)))
     (eerie--use-literal
      (when-let* ((keymap (eerie--keypad-lookup-key (read-kbd-macro input))))
        (when (keymapp keymap)
          (eerie--make-keymap-for-describe keymap nil))))

     ;; For leader popup
     ;; eerie-keypad-leader-dispatch can be string, keymap or nil
     ;; - string, dynamically find the keymap
     ;; - keymap, just use it
     ;; - nil, take the one in eerie-keymap-alist
     ;; Leader keymap may contain eerie-dispatch commands
     ;; translated names based on the commands they refer to
     ((null eerie--keypad-keys)
      (when-let* ((keymap (if (stringp eerie-keypad-leader-dispatch)
                              (eerie--keypad-lookup-key (read-kbd-macro eerie-keypad-leader-dispatch))
                            (or eerie-keypad-leader-dispatch
                                (alist-get 'leader eerie-keymap-alist)))))
        (let ((km (make-keymap)))
          (suppress-keymap km t)
          (map-keymap
           (lambda (key def)
             (when (and (not (member 'control (event-modifiers key)))
                        (not (member key (list eerie-keypad-meta-prefix
                                               eerie-keypad-ctrl-meta-prefix
                                               eerie-keypad-literal-prefix)))
                        (not (alist-get key eerie-keypad-start-keys)))
               (let ((keys (vector (eerie--get-event-key key))))
                 (unless (lookup-key km keys)
                   (define-key km keys (funcall eerie-keypad-get-title-function def))))))
           keymap)
          km)))

     (t
      (when-let* ((keymap (eerie--keypad-lookup-key (read-kbd-macro input))))
        (when (keymapp keymap)
          (let* ((km (make-keymap))
                 (has-sub-meta (eerie--keypad-has-sub-meta-keymap-p))
                 (ignores (if has-sub-meta
                              (list eerie-keypad-meta-prefix
                                    eerie-keypad-ctrl-meta-prefix
                                    eerie-keypad-literal-prefix
                                    127)
                            (list eerie-keypad-literal-prefix 127))))
            (suppress-keymap km t)
            (map-keymap
             (lambda (key def)
               (when (member 'control (event-modifiers key))
                 (unless (member (eerie--event-key key) ignores)
                   (when def
                     (let ((k (vector (eerie--get-event-key key))))
                       (unless (lookup-key km k)
                         (define-key km k (funcall eerie-keypad-get-title-function def))))))))
             keymap)
            (map-keymap
             (lambda (key def)
               (unless (member 'control (event-modifiers key))
                 (unless (member key ignores)
                   (let ((k (vector (eerie--get-event-key key))))
                     (unless (lookup-key km k)
                       (define-key km (vector (eerie--get-event-key key)) (funcall eerie-keypad-get-title-function def)))))))
             keymap)
            km)))))))

(defun eerie--keypad-clear-message ()
  "Clear displayed message by calling `eerie-keypad-clear-describe-keymap-function'."
  (when eerie-keypad-clear-describe-keymap-function
    (funcall eerie-keypad-clear-describe-keymap-function)))

(defun eerie--keypad-display-message ()
  "Display a message for current input state."
  (when eerie-keypad-describe-keymap-function
    (when (or
           eerie--keypad-keymap-description-activated

           (setq eerie--keypad-keymap-description-activated
                 (sit-for eerie-keypad-describe-delay t)))
      (let ((keymap (eerie--keypad-get-keymap-for-describe)))
        (funcall eerie-keypad-describe-keymap-function keymap)))))

(defun eerie--describe-keymap-format (pairs &optional width)
  (let* ((fw (or width (frame-width)))
         (cnt (length pairs))
         (best-col-w nil)
         (best-rows nil))
    (cl-loop for col from 5 downto 2  do
             (let* ((row (1+ (/ cnt col)))
                    (v-parts (seq-partition pairs row))
                    (rows (eerie--transpose-lists v-parts))
                    (col-w (thread-last
                             v-parts
                             (mapcar
                              (lambda (col)
                                (cons (seq-max (or (mapcar (lambda (it) (length (car it))) col) '(0)))
                                      (seq-max (or (mapcar (lambda (it) (length (cdr it))) col) '(0))))))))
                    ;; col-w looks like:
                    ;; ((3 . 2) (4 . 3))
                    (w (thread-last
                         col-w
                         ;; 4 is for the width of arrow(3) between key and command
                         ;; and the end tab or newline(1)
                         (mapcar (lambda (it) (+ (car it) (cdr it) 4)))
                         (eerie--sum))))
               (when (<= w fw)
                 (setq best-col-w col-w
                       best-rows rows)
                 (cl-return nil))))
    (if best-rows
        (thread-last
          best-rows
          (mapcar
           (lambda (row)
             (thread-last
               row
               (seq-map-indexed
                (lambda (it idx)
                  (let* ((key-str (car it))
                         (def-str (cdr it))
                         (l-r (nth idx best-col-w))
                         (l (car l-r))
                         (r (cdr l-r))
                         (key (eerie--string-pad key-str l 32 t))
                         (def (eerie--string-pad def-str r 32)))
                    (format "%s%s%s"
                            key
                            (propertize " → " 'face 'font-lock-comment-face)
                            def))))
               (eerie--string-join " "))))
          (eerie--string-join "\n"))
      (propertize "Frame is too narrow for KEYPAD popup" 'face 'eerie-keypad-cannot-display))))



(defun eerie-describe-keymap (keymap)
  (when (and keymap (not defining-kbd-macro) (not eerie--keypad-help))
    (let* ((rst))
      (map-keymap
       (lambda (key def)
         (let ((k (if (consp key)
                      (format "%s .. %s"
                              (key-description (list (car key)))
                              (key-description (list (cdr key))))
                    (key-description (list key)))))
           (let (key-str def-str)
             (cond
              ((and (commandp def) (symbolp def))
               (setq key-str (propertize k 'face 'font-lock-constant-face)
                     def-str (propertize (symbol-name def) 'face 'font-lock-function-name-face)))
              ((symbolp def)
               (setq key-str (propertize k 'face 'font-lock-constant-face)
                     def-str (propertize (concat "+" (symbol-name def)) 'face 'font-lock-keyword-face)))
              ((functionp def)
               (setq key-str (propertize k 'face 'font-lock-constant-face)
                     def-str (propertize "?closure" 'face 'font-lock-function-name-face)))
              (t
               (setq key-str (propertize k 'face 'font-lock-constant-face)
                     def-str (propertize "+prefix" 'face 'font-lock-keyword-face))))
             (push (cons key-str def-str) rst))))
       keymap)
      (setq rst (reverse rst))
      (let ((msg (eerie--describe-keymap-format rst)))
        (let ((message-log-max)
              (max-mini-window-height 1.0))
          (save-window-excursion
            (with-temp-message
                (format "%s\n%s%s%s"
                        msg
                        eerie-keypad-message-prefix
                        (let ((pre (eerie--keypad-format-prefix)))
                          (if (string-blank-p pre)
                              ""
                            (propertize pre 'face 'font-lock-comment-face)))
                        (propertize (eerie--keypad-format-keys nil) 'face 'font-lock-string-face))
              (sit-for 1000000 t))))))))

(defun eerie-keypad-get-title (def)
  "Return a symbol as title or DEF.

Returning DEF will result in a generated title."
  (if-let* ((cmd (and (symbolp def)
                      (commandp def)
                      (get def 'eerie-dispatch))))
      (eerie--keypad-lookup-key (kbd cmd))
    def))

(defun eerie-keypad-undo ()
  "Pop the last input."
  (interactive)
  (setq this-command last-command)
  (cond
   (eerie--use-both
    (setq eerie--use-both nil))
   (eerie--use-literal
    (setq eerie--use-literal nil))
   (eerie--use-meta
    (setq eerie--use-meta nil))
   (t
    (pop eerie--keypad-keys)))
  (if eerie--keypad-keys
      (progn
        (eerie--update-indicator)
        (eerie--keypad-display-message))
    (when eerie-keypad-message
      (message "KEYPAD exit"))
    (eerie--keypad-quit)))

(defun eerie--keypad-show-message ()
  "Show message for current keypad input."
  (let ((message-log-max))
    (message "%s%s%s%s"
             eerie-keypad-message-prefix
             (if eerie--keypad-help "(describe key)" "")
             (let ((pre (eerie--keypad-format-prefix)))
               (if (string-blank-p pre)
                   ""
                 (propertize pre 'face 'font-lock-comment-face)))
             (propertize (eerie--keypad-format-keys nil) 'face 'font-lock-string-face))))

(defun eerie--keypad-in-beacon-p ()
  "Return whether keypad is started from BEACON state."
  (and (eerie--beacon-inside-secondary-selection)
       eerie--beacon-overlays))

(defun eerie--keypad-execute (command)
  "Execute the COMMAND.

If there are beacons, execute it at every beacon."
  (if (eerie--keypad-in-beacon-p)
      (cond
       ((member command '(kmacro-start-macro kmacro-start-macro-or-insert-counter))
        (call-interactively 'eerie-beacon-start))
       ((member command '(kmacro-end-macro eerie-end-kmacro))
        (call-interactively 'eerie-beacon-end-and-apply-kmacro))
       ((and (not defining-kbd-macro)
             (not executing-kbd-macro)
             eerie-keypad-execute-on-beacons)
        (call-interactively command)
        (eerie--beacon-apply-command command)))
    (call-interactively command)))

(defun eerie--keypad-try-execute ()
  "Try execute command, return t when the translation progress can be ended.

This function supports a fallback behavior, where it allows to use `SPC
x f' to execute `C-x C-f' or `C-x f' when `C-x C-f' is not bound."
  (unless (or eerie--use-literal
              eerie--use-meta
              eerie--use-both)
    (let* ((key-str (eerie--keypad-format-keys nil))
           (cmd (eerie--keypad-lookup-key (kbd key-str))))
      (cond
       ((keymapp cmd)
        (when eerie-keypad-message (eerie--keypad-show-message))
        (eerie--keypad-display-message)
        nil)
       ((commandp cmd t)
        (setq current-prefix-arg eerie--prefix-arg
              eerie--prefix-arg nil)
        (if eerie--keypad-help
            (progn
              (eerie--keypad-quit)
              (describe-function cmd)
              t)
          (let ((eerie--keypad-this-command cmd))
            (eerie--keypad-quit)
            (setq real-this-command cmd
                  this-command cmd)
            (eerie--keypad-execute cmd)
            t)))
       ((equal 'control (caar eerie--keypad-keys))
        (setcar eerie--keypad-keys (cons 'literal (cdar eerie--keypad-keys)))
        (eerie--keypad-try-execute))
       (t
        (setq eerie--prefix-arg nil)
        (eerie--keypad-quit)
        (if (or (eq t eerie-keypad-leader-transparent)
                (eq eerie--keypad-previous-state eerie-keypad-leader-transparent))
          (let* ((key (eerie--parse-input-event last-input-event))
                 (origin-cmd (cl-some (lambda (m)
                                        (when (and (not (eq m eerie-normal-state-keymap))
                                                   (not (eq m eerie-visual-state-keymap))
                                                   (not (eq m eerie-motion-state-keymap)))
                                          (let ((cmd (lookup-key m (kbd key))))
                                            (when (commandp cmd)
                                              cmd))))
                                      (current-active-maps)))
                 (remapped-cmd (command-remapping origin-cmd))
                 (cmd-to-call (if (member remapped-cmd '(undefined nil))
                                  (or origin-cmd 'undefined)
                                remapped-cmd)))
            (eerie--keypad-execute cmd-to-call))
          (message "%s is undefined" key-str))
        t)))))

(defun eerie--keypad-handle-input-with-keymap (input-event)
  "Handle INPUT-EVENT with `eerie-keypad-state-keymap'.

Return t if handling is completed."
  (if (equal 'escape last-input-event)
      (eerie--keypad-quit)
    (setq last-command-event last-input-event)
    (let ((kbd (single-key-description input-event)))
      (if-let* ((cmd (lookup-key eerie-keypad-state-keymap (read-kbd-macro kbd))))
          (call-interactively cmd)
        (eerie--keypad-handle-input-event input-event)))))

(defun eerie--keypad-handle-input-event (input-event)
  "Handle the INPUT-EVENT.

Add a parsed key and its modifier to current key sequence. Then invoke a
command when there's one available on current key sequence."
  (eerie--keypad-clear-message)
  (when-let* ((key (single-key-description input-event)))
    (let ((has-sub-meta (eerie--keypad-has-sub-meta-keymap-p)))
      (cond
       (eerie--use-literal
        (push (cons 'literal key)
              eerie--keypad-keys)
        (setq eerie--use-literal nil))
       (eerie--use-both
        (push (cons 'both key) eerie--keypad-keys)
        (setq eerie--use-both nil))
       (eerie--use-meta
        (push (cons 'meta key) eerie--keypad-keys)
        (setq eerie--use-meta nil))
       ((and (equal input-event eerie-keypad-meta-prefix)
             (not eerie--use-meta)
             has-sub-meta)
        (setq eerie--use-meta t))
       ((and (equal input-event eerie-keypad-ctrl-meta-prefix)
             (not eerie--use-both)
             has-sub-meta)
        (setq eerie--use-both t))
       ((and (equal input-event eerie-keypad-literal-prefix)
             (not eerie--use-literal)
             eerie--keypad-keys)
        (setq eerie--use-literal t))
       (eerie--keypad-keys
        (push (cons 'control key) eerie--keypad-keys))
       ((alist-get input-event eerie-keypad-start-keys)
        (push (cons 'control (eerie--parse-input-event
                              (alist-get input-event eerie-keypad-start-keys)))
              eerie--keypad-keys))
       (t
        (if-let* ((keymap (eerie--get-leader-keymap)))
            (setq eerie--keypad-base-keymap keymap)
          (setq eerie--keypad-keys (eerie--parse-string-to-keypad-keys eerie-keypad-leader-dispatch)))
        (push (cons 'literal key) eerie--keypad-keys))))

    ;; Try execute if the input is valid.
    (if (or eerie--use-literal
            eerie--use-meta
            eerie--use-both)
        (progn
          (when eerie-keypad-message (eerie--keypad-show-message))
          (eerie--keypad-display-message)
          nil)
      (eerie--keypad-try-execute))))

(defun eerie-keypad ()
  "Enter keypad state and convert inputs."
  (interactive)
  (eerie-keypad-start-with nil))

(defun eerie-keypad-start ()
  "Enter keypad state with current input as initial key sequences."
  (interactive)
  (setq this-command last-command
        eerie--keypad-keys nil
        eerie--keypad-previous-state (eerie--current-state)
        eerie--prefix-arg current-prefix-arg)
  (eerie--switch-state 'keypad)
  (unwind-protect
      (progn
        (eerie--keypad-handle-input-with-keymap last-input-event)
        (while (not (eerie--keypad-handle-input-with-keymap (read-key)))))
    (when (bound-and-true-p eerie-keypad-mode)
      (eerie--keypad-quit))))

(defun eerie-keypad-start-with (input)
  "Enter keypad state with INPUT.

A string INPUT, stands for initial keys.
When INPUT is nil, start without initial keys."
  (setq this-command last-command
        eerie--keypad-keys (when input (eerie--parse-string-to-keypad-keys input))
        eerie--keypad-previous-state (eerie--current-state)
        eerie--prefix-arg current-prefix-arg)
  (eerie--switch-state 'keypad)
  (unwind-protect
      (progn
        (eerie--keypad-show-message)
        (eerie--keypad-display-message)
        (while (not (eerie--keypad-handle-input-with-keymap (read-key)))))
    (when (bound-and-true-p eerie-keypad-mode)
      (eerie--keypad-quit))))

(defun eerie-keypad-describe-key ()
  "Describe key via KEYPAD input."
  (interactive)
  (setq eerie--keypad-help t)
  (eerie-keypad))

(provide 'eerie-keypad)
;;; eerie-keypad.el ends here
