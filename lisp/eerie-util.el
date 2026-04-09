;;; eerie-util.el --- Utilities for Eerie  -*- lexical-binding: t; -*-

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
;; Utilities for Eerie.

;;; Code:

(require 'subr-x)
(require 'cl-lib)
(require 'seq)
(require 'color)

(require 'eerie-var)
(require 'eerie-keymap)
(require 'eerie-face)

;; Modes

(defvar eerie-normal-mode)

(declare-function eerie--remove-match-highlights "eerie-visual")
(declare-function eerie--remove-expand-highlights "eerie-visual")
(declare-function eerie--remove-search-highlight "eerie-visual")
(declare-function eerie-insert-mode "eerie-core")
(declare-function eerie-motion-mode "eerie-core")
(declare-function eerie-normal-mode "eerie-core")
(declare-function eerie-visual-mode "eerie-core")
(declare-function eerie-multicursor-visual-mode "eerie-core")
(declare-function eerie-beacon-mode "eerie-core")
(declare-function eerie-mode "eerie-core")
(declare-function eerie-minibuffer-quit "eerie-command")
(declare-function eerie--enable "eerie-core")

(defun eerie--execute-kbd-macro (kbd-macro-or-defun)
  "Execute the function bound to `KBD-MACRO-OR-DEFUN'. If `KBD-MACRO-OR-DEFUN' is a string,
instead execute the keyboard macro it corresponds to."
  (when-let* ((ret (if (and (symbolp kbd-macro-or-defun) (fboundp kbd-macro-or-defun))
                       kbd-macro-or-defun
                     (key-binding (read-kbd-macro kbd-macro-or-defun)))))
    (cond
     ((commandp ret)
      (setq this-command ret)
      (call-interactively ret))

     ((keymapp ret)
      (set-transient-map ret nil nil)))))

(defun eerie-insert-mode-p ()
  "Whether insert mode is enabled."
  (bound-and-true-p eerie-insert-mode))

(defun eerie-motion-mode-p ()
  "Whether motion mode is enabled."
  (bound-and-true-p eerie-motion-mode))

(defun eerie-normal-mode-p ()
  "Whether normal mode is enabled."
  (bound-and-true-p eerie-normal-mode))

(defun eerie-visual-mode-p ()
  "Whether visual mode is enabled."
  (bound-and-true-p eerie-visual-mode))

(defun eerie-beacon-mode-p ()
  "Whether beacon mode is enabled."
  (bound-and-true-p eerie-beacon-mode))

(defun eerie--disable-current-state ()
  (when eerie--current-state
    (funcall (alist-get eerie--current-state eerie-state-mode-alist) -1)
    (setq eerie--current-state nil)))

(defun eerie--read-cursor-face-color (face)
  "Read cursor color from face."
  (let ((f (face-attribute face :inherit)))
    (if (equal 'unspecified f)
        (let ((color (face-attribute face :background)))
          (if (equal 'unspecified color)
              (face-attribute 'default :foreground)
            color))
      (eerie--read-cursor-face-color f))))

(defun eerie--set-cursor-type (type)
  (if (display-graphic-p)
      (setq cursor-type type)
    (let* ((shape (or (car-safe type) type))
           (param (cond ((eq shape 'bar) "6")
                        ((eq shape 'hbar) "4")
                        (t "2"))))
      (send-string-to-terminal (concat "\e[" param " q")))))

(defun eerie--set-cursor-color (face)
  "Set cursor color by face."
  (let ((color (eerie--read-cursor-face-color face)))
    (unless (equal (frame-parameter nil 'cursor-color) color)
      (set-cursor-color color))))

(defun eerie--update-cursor-default ()
  "Set default cursor type and color"
  (eerie--set-cursor-type eerie-cursor-type-default)
  (eerie--set-cursor-color 'eerie-unknown-cursor))

(defun eerie--update-cursor-insert ()
  "Set insert cursor type and color"
  (eerie--set-cursor-type eerie-cursor-type-insert)
  (eerie--set-cursor-color 'eerie-insert-cursor))

(defun eerie--update-cursor-normal ()
  "Set normal cursor type and color"
  (if eerie-use-cursor-position-hack
      (unless (use-region-p)
        (eerie--set-cursor-type eerie-cursor-type-normal))
    (eerie--set-cursor-type eerie-cursor-type-normal))
  (eerie--set-cursor-color 'eerie-normal-cursor))

(defun eerie--update-cursor-visual ()
  "Set visual cursor type and color."
  (if eerie-use-cursor-position-hack
      (unless (use-region-p)
        (eerie--set-cursor-type eerie-cursor-type-visual))
    (eerie--set-cursor-type eerie-cursor-type-visual))
  (eerie--set-cursor-color 'eerie-visual-cursor))

(defun eerie--update-cursor-motion ()
  "Set motion cursor type and color"
  (eerie--set-cursor-type eerie-cursor-type-motion)
  (eerie--set-cursor-color 'eerie-motion-cursor))

(defun eerie--update-cursor-beacon ()
  "Set beacon cursor type and color"
  (eerie--set-cursor-type eerie-cursor-type-beacon)
  (eerie--set-cursor-color 'eerie-beacon-cursor))

(defun eerie--cursor-null-p ()
  "Check if cursor-type is null"
  (null cursor-type))

(defun eerie--update-cursor ()
  "Update cursor type according to the current state.

This uses the variable eerie-update-cursor-functions-alist, finds the first
item in which the car evaluates to true, and runs the cdr. The last item's car
in the list will always evaluate to true."
  (with-current-buffer (window-buffer)
    (thread-last eerie-update-cursor-functions-alist
      (cl-remove-if-not (lambda (el) (funcall (car el))))
      (cdar)
      (funcall))))

(defun eerie--get-state-name (state)
  "Get the name of the current state.

Looks up the state in eerie-replace-state-name-list"
  (alist-get state eerie-replace-state-name-list))

(defun eerie--render-indicator ()
  "Renders a short indicator based on the current state."
  (when (bound-and-true-p eerie-global-mode)
    (let* ((state (eerie--current-state))
           (state-name (eerie--get-state-name state))
           (indicator-face (alist-get state eerie-indicator-face-alist)))
      (if state-name
          (propertize
           (format " %s " state-name)
           'face indicator-face)
        ""))))

(defun eerie--update-indicator ()
  (let ((indicator (eerie--render-indicator)))
    (setq-local eerie--indicator indicator)))

(defun eerie--state-p (state)
  (funcall (intern (concat "eerie-" (symbol-name state) "-mode-p"))))

(defun eerie--current-state ()
  eerie--current-state)

(defun eerie--selection-display-mode-p ()
  "Whether selection overlays should use modal display affordances."
  (or (eerie-normal-mode-p)
      (eerie-visual-mode-p)
      (bound-and-true-p eerie-multicursor-visual-mode)
      (eerie-beacon-mode-p)))

(defun eerie--should-update-display-p ()
  (cl-case eerie-update-display-in-macro
    ((t) t)
    ((except-last-macro)
     (or (null executing-kbd-macro)
         (not (equal executing-kbd-macro last-kbd-macro))))
    ((nil)
     (null executing-kbd-macro))))

(defun eerie-update-display ()
  (when (eerie--should-update-display-p)
    (eerie--update-indicator)
    (eerie--update-cursor)))

(defun eerie--switch-state (state &optional no-hook)
  "Switch to STATE execute `eerie-switch-state-hook' unless NO-HOOK is non-nil."
  (unless (eq state (eerie--current-state))
    (let ((mode (alist-get state eerie-state-mode-alist)))
      (funcall mode 1))
    (unless (bound-and-true-p no-hook)
      (run-hook-with-args 'eerie-switch-state-hook state))))

(defun eerie--direction-forward ()
  "Make the selection towards forward."
  (when (and (region-active-p) (< (point) (mark)))
    (exchange-point-and-mark)))

(defun eerie--direction-backward ()
  "Make the selection towards backward."
  (when (and (region-active-p) (> (point) (mark)))
    (exchange-point-and-mark)))

(defun eerie--direction-backward-p ()
  "Return whether we have a backward selection."
  (and (region-active-p)
       (> (mark) (point))))

(defun eerie--direction-forward-p ()
  "Return whether we have a forward selection."
  (and (region-active-p)
       (<= (mark) (point))))

(defun eerie--selection-type ()
  "Return current selection type."
  (when (region-active-p)
    (car eerie--selection)))

(defun eerie--in-string-p (&optional pos)
  "Return whether POS or current position is in string."
  (save-mark-and-excursion
    (when pos (goto-char pos))
    (nth 3 (syntax-ppss))))

(defun eerie--in-comment-p (&optional pos)
  "Return whether POS or current position is in string."
  (save-mark-and-excursion
    (when pos (goto-char pos))
    (nth 4 (syntax-ppss))))

(defun eerie--sum (sequence)
  (seq-reduce #'+ sequence 0))

(defun eerie--reduce (fn init sequence)
  (seq-reduce fn sequence init))

(defun eerie--string-pad (s len pad &optional start)
  (if (<= len (length s))
      s
    (if start
	(concat (make-string (- len (length s)) pad) s)
      (concat s (make-string (- len (length s)) pad)))))

(defun eerie--truncate-string (len s ellipsis)
  (if (> (length s) len)
      (concat (substring s 0 (- len (length ellipsis))) ellipsis)
    s))

(defun eerie--string-join (sep s)
  (string-join s sep))

(defun eerie--prompt-symbol-and-words (prompt beg end &optional disallow-empty)
  "Completion with PROMPT for symbols and words from BEG to END."
  (let ((completions))
    (save-mark-and-excursion
      (goto-char beg)
      (while (re-search-forward "\\_<\\(\\sw\\|\\s_\\)+\\_>" end t)
        (let ((result (match-string-no-properties 0)))
          (when (>= (length result) eerie-visit-collect-min-length)
            (if eerie-visit-sanitize-completion
                (push (cons result (format "\\_<%s\\_>" (regexp-quote result))) completions)
              (push (format "\\_<%s\\_>" (regexp-quote result)) completions))))))
    (setq completions (delete-dups completions))
    (let ((selected (completing-read prompt completions nil nil)))
      (while (and (string-empty-p selected)
                  disallow-empty)
        (setq selected (completing-read
                        (concat "[Input must be non-empty] " prompt)
                        completions nil nil)))
      (if eerie-visit-sanitize-completion
          (or (cdr (assoc selected completions))
              (regexp-quote selected))
        selected))))

(defun eerie--on-window-state-change (&rest _args)
  "Update cursor style after switching window."
  (eerie--update-cursor)
  (eerie--update-indicator))

(defun eerie--on-exit ()
  (unless (display-graphic-p)
    (send-string-to-terminal "\e[2 q")))

(defun eerie--get-indent ()
  "Get indent of current line."
  (save-mark-and-excursion
    (back-to-indentation)
    (- (point) (line-beginning-position))))

(defun eerie--empty-line-p ()
  "Whether current line is empty."
  (string-match-p "^ *$" (buffer-substring-no-properties
                          (line-beginning-position)
                          (line-end-position))))

(defun eerie--ordinal (n)
  (cl-case n
    ((1) "1st")
    ((2) "2nd")
    ((3) "3rd")
    (t (format "%dth" n))))

(defun eerie--allow-modify-p ()
  (and (not buffer-read-only)
       (not eerie--temp-normal)))

(defun eerie--with-universal-argument-p (arg)
  (equal '(4) arg))

(defun eerie--with-negative-argument-p (arg)
  (< (prefix-numeric-value arg) 0))

(defun eerie--with-shift-p ()
  (member 'shift last-input-event))

(defun eerie--bounds-with-type (type thing)
  (when-let* ((bounds (bounds-of-thing-at-point thing)))
    (cons type bounds)))

(defun eerie--insert (&rest args)
  "Use `eerie--insert-function' to insert ARGS at point."
  (apply eerie--insert-function args))

(defun eerie--delete-region (start end)
  "Use `eerie--delete-region-function' to delete text between START and END."
  (funcall eerie--delete-region-function start end))

(defun eerie--push-search (search)
  (unless (string-equal search (car regexp-search-ring))
    (add-to-history 'regexp-search-ring search regexp-search-ring-max)))

(defun eerie--remove-text-properties (text)
  (set-text-properties 0 (length text) nil text)
  text)

(defun eerie--toggle-relative-line-number ()
  (when display-line-numbers
    (if (bound-and-true-p eerie-insert-mode)
        (setq display-line-numbers t)
      (setq display-line-numbers 'relative))))

(defun eerie--render-char-thing-table ()
  (let* ((ww (frame-width))
         (w 25)
         (col (min 5 (/ ww w))))
    (thread-last
      eerie-char-thing-table
      (seq-group-by #'cdr)
      (seq-sort-by #'car #'string-lessp)
      (seq-map-indexed
       (lambda (th-pairs idx)
         (let* ((th (car th-pairs))
                (pairs (cdr th-pairs))
                (pre (thread-last
                       pairs
                       (mapcar (lambda (it) (char-to-string (car it))))
                       (eerie--string-join " "))))
           (format "%s%s%s%s"
                   (propertize
                    (eerie--string-pad pre 8 32 t)
                     'face 'font-lock-constant-face)
                   (propertize " → " 'face 'font-lock-comment-face)
                   (propertize
                    (eerie--string-pad (symbol-name th) 13 32 t)
                     'face 'font-lock-function-name-face)
                   (if (= (1- col) (mod idx col))
                       "\n"
                     " ")))))
      (string-join)
      (string-trim-right))))

(defun eerie--transpose-lists (lists)
  (when lists
    (let* ((n (seq-max (mapcar #'length lists)))
           (rst (apply #'list (make-list n ()))))
      (mapc (lambda (l)
              (seq-map-indexed
               (lambda (it idx)
                 (cl-replace rst
                             (list (cons it (nth idx rst)))
                             :start1 idx
                             :end1 (1+ idx)))
               l))
            lists)
      (mapcar #'reverse rst))))

(defun eerie--get-event-key (e)
  (if (and (integerp (event-basic-type e))
           (member 'shift (event-modifiers e)))
      (upcase (event-basic-type e))
    (event-basic-type e)))

(defun eerie--ensure-visible ()
  (let ((overlays (overlays-at (1- (point))))
        ov expose)
    (while (setq ov (pop overlays))
      (if (and (invisible-p (overlay-get ov 'invisible))
               (setq expose (overlay-get ov 'isearch-open-invisible)))
          (funcall expose ov)))))

(defun eerie--minibuffer-setup ()
  (local-set-key (kbd "<escape>") #'eerie-minibuffer-quit)
  (setq-local eerie-normal-mode nil)
  (when (member this-command eerie-grab-fill-commands)
    (when-let* ((s (eerie--second-sel-get-string)))
      (eerie--insert s))))

(defun eerie--parse-input-event (e)
  (cond
   ((equal e 32)
    "SPC")
   ((characterp e)
    (string e))
   ((equal 'tab e)
    "TAB")
   ((equal 'return e)
    "RET")
   ((equal 'backspace e)
    "DEL")
   ((equal 'escape e)
    "ESC")
   ((symbolp e)
    (format "<%s>" e))
   (t nil)))

(defun eerie--prepare-region-for-kill ()
  (when (and (equal 'line (cdr (eerie--selection-type)))
             (eerie--direction-forward-p)
             (< (point) (point-max)))
    (forward-char 1)))

(defun eerie--prepare-string-for-kill-append (s)
  (let ((curr (current-kill 0 nil)))
    (cl-case (cdr (eerie--selection-type))
      ((line) (concat (unless (string-suffix-p "\n" curr) "\n")
                      (string-trim-right s "\n")))
      ((word block) (concat (unless (string-suffix-p " " curr) " ")
                            (string-trim s " " "\n")))
      (t s))))

(defun eerie--event-key (e)
  (let ((c (event-basic-type e)))
    (if (and (char-or-string-p c)
             (member 'shift (event-modifiers e)))
        (upcase c)
      c)))



(defun eerie--make-button (string callback &optional data help-echo)
  "Copy from buttonize, which is available in Emacs 29.1"
  (let ((string
         (apply #'propertize string
                (list 'font-lock-face 'button
                      'mouse-face 'highlight
                      'help-echo help-echo
                      'button t
                      'follow-link t
                      'category t
                      'button-data data
                      'keymap button-map
                      'action callback))))
    ;; Add the face to the end so that it can be overridden.
    (add-face-text-property 0 (length string) 'button t string)
    string))

(defun eerie--parse-def (def)
  "Return a command or keymap for DEF.

If DEF is a string, return a command that calls the command or keymap
that bound to DEF. Otherwise, return DEF."
  (if (stringp def)
      (let ((cmd-name (gensym 'eerie-dispatch_)))
        ;; dispatch command
        (defalias cmd-name
          (lambda ()
            (:documentation
             (format "Execute the command which is bound to %s."
                     (eerie--make-button def 'describe-key (kbd def))))
            (interactive)
            (eerie--execute-kbd-macro def)))
        (put cmd-name 'eerie-dispatch def)
        cmd-name)
    def))

(defun eerie--second-sel-set-string (string)
  (cond
   ((eerie--second-sel-buffer)
    (with-current-buffer (overlay-buffer mouse-secondary-overlay)
      (goto-char (overlay-start mouse-secondary-overlay))
      (eerie--delete-region (overlay-start mouse-secondary-overlay) (overlay-end mouse-secondary-overlay))
      (eerie--insert string)))
   ((markerp mouse-secondary-start)
    (with-current-buffer (marker-buffer mouse-secondary-start)
      (goto-char (marker-position mouse-secondary-start))
      (eerie--insert string)))))

(defun eerie--second-sel-get-string ()
  (when (eerie--second-sel-buffer)
    (with-current-buffer (overlay-buffer mouse-secondary-overlay)
      (buffer-substring-no-properties
       (overlay-start mouse-secondary-overlay)
       (overlay-end mouse-secondary-overlay)))))

(defun eerie--second-sel-buffer ()
  (and (overlayp mouse-secondary-overlay)
       (overlay-buffer mouse-secondary-overlay)))

(defun eerie--second-sel-bound ()
  (and (secondary-selection-exist-p)
       (cons (overlay-start mouse-secondary-overlay)
             (overlay-end mouse-secondary-overlay))))

(defmacro eerie--with-selection-fallback (&rest body)
  `(if (region-active-p)
       (progn ,@body)
     (eerie--selection-fallback)))

(defmacro eerie--wrap-collapse-undo (&rest body)
  "Like `progn' but perform BODY with undo collapsed."
  (declare (indent 0) (debug t))
  (let ((handle (make-symbol "--change-group-handle--"))
        (success (make-symbol "--change-group-success--")))
    `(let ((,handle (prepare-change-group))
           ;; Don't truncate any undo data in the middle of this.
           (undo-outer-limit nil)
           (undo-limit most-positive-fixnum)
           (undo-strong-limit most-positive-fixnum)
           (,success nil))
       (unwind-protect
           (progn
             (activate-change-group ,handle)
             (prog1 ,(macroexp-progn body)
               (setq ,success t)))
         (if ,success
             (progn
               (accept-change-group ,handle)
               (undo-amalgamate-change-group ,handle))
           (cancel-change-group ,handle))))))

(defun eerie--highlight-pre-command ()
  (unless (member this-command '(eerie-search))
    (eerie--remove-match-highlights))
  (eerie--remove-expand-highlights)
  (eerie--remove-search-highlight))

(defun eerie--remove-fake-cursor (rol)
  (when (overlayp rol)
    (when-let* ((ovs (overlay-get rol 'eerie-face-cursor)))
      (mapc (lambda (o) (when (overlayp o) (delete-overlay o)))
            ovs))))

(defvar eerie--region-cursor-faces '(eerie-region-cursor-1
                                    eerie-region-cursor-2
                                    eerie-region-cursor-3))

(defun eerie--add-fake-cursor (rol)
  (if (and eerie-use-enhanced-selection-effect
           (eerie--selection-display-mode-p))
      (when (overlayp rol)
        (let ((start (overlay-start rol))
              (end (overlay-end rol)))
          (unless (= start end)
            (let (ovs)
                (if (eerie--direction-forward-p)
                    (progn
                      (let ((p end)
                            (i 0))
                        (while (and (> p start)
                                    (< i 3))
                          (let ((ov (make-overlay (1- p) p)))
                            (overlay-put ov 'face (nth i eerie--region-cursor-faces))
                            (overlay-put ov 'priority 10)
                            (overlay-put ov 'window (overlay-get rol 'window))
                            (cl-decf p)
                            (cl-incf i)
                            (push ov ovs)))))
                  (let ((p start)
                        (i 0))
                    (while (and (< p end)
                                (< i 3))
                      (let ((ov (make-overlay p (1+ p))))
                        (overlay-put ov 'face (nth i eerie--region-cursor-faces))
                        (overlay-put ov 'priority 10)
                        (overlay-put ov 'window (overlay-get rol 'window))
                        (cl-incf p)
                        (cl-incf i)
                        (push ov ovs)))))
                (overlay-put rol 'eerie-face-cursor ovs)))
          rol))
    rol))

(defun eerie--redisplay-highlight-region-function (start end window rol)
  (when (and (eerie--selection-display-mode-p)
             (equal window (selected-window)))
    (if (use-region-p)
        (eerie--set-cursor-type eerie-cursor-type-region-cursor)
      (eerie--set-cursor-type
       (if (eerie-visual-mode-p)
           eerie-cursor-type-visual
         eerie-cursor-type-normal))))
  (when eerie-use-enhanced-selection-effect
    (eerie--remove-fake-cursor rol))
  (thread-first
    (funcall eerie--backup-redisplay-highlight-region-function start end window rol)
    (eerie--add-fake-cursor)))

(defun eerie--redisplay-unhighlight-region-function (rol)
  (eerie--remove-fake-cursor rol)
  (when (and (overlayp rol)
             (equal (overlay-get rol 'window) (selected-window))
             (eerie--selection-display-mode-p))
    (eerie--set-cursor-type
     (if (eerie-visual-mode-p)
         eerie-cursor-type-visual
       eerie-cursor-type-normal)))
  (funcall eerie--backup-redisplay-unhighlight-region-function rol))

(defun eerie--mix-color (color1 color2 n)
  (mapcar (lambda (c) (apply #'color-rgb-to-hex c))
          (color-gradient (color-name-to-rgb color1)
                          (color-name-to-rgb color2)
                          n)))

(defun eerie--beacon-inside-secondary-selection ()
  (and
   (secondary-selection-exist-p)
   (< (overlay-start mouse-secondary-overlay)
      (overlay-end mouse-secondary-overlay))
   (<= (overlay-start mouse-secondary-overlay)
       (point)
       (overlay-end mouse-secondary-overlay))))

(defun eerie--narrow-secondary-selection ()
  (narrow-to-region (overlay-start mouse-secondary-overlay)
                    (overlay-end mouse-secondary-overlay)))

(defun eerie--hack-cursor-pos (pos)
  "Hack the point when `eerie-use-cursor-position-hack' is enabled."
  (if eerie-use-cursor-position-hack
      (1- pos)
    pos))

(defun eerie--remove-modeline-indicator ()
  (setq-default mode-line-format
                (cl-remove '(:eval (eerie-indicator)) mode-line-format
                           :test 'equal)))

(defun eerie--init-buffers ()
  "Enable eerie in existing buffers."
  (dolist (buf (buffer-list))
    (unless (minibufferp buf)
      (with-current-buffer buf
        (eerie--enable)))))

(defun eerie--get-leader-keymap ()
  (alist-get 'leader eerie-keymap-alist))

(provide 'eerie-util)
;;; eerie-util.el ends here
