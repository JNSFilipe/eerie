;;; eerie-beacons.el --- Batch Macro state in Eerie  -*- lexical-binding: t; -*-

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
;; The file contains BEACON state implementation.

;;; Code:

(require 'eerie-util)
(require 'eerie-var)
(require 'kmacro)
(require 'seq)

(declare-function eerie-replace "eerie-command")
(declare-function eerie-insert "eerie-command")
(declare-function eerie-change "eerie-command")
(declare-function eerie-change-char "eerie-command")
(declare-function eerie-append "eerie-command")
(declare-function eerie-kill "eerie-command")
(declare-function eerie--cancel-selection "eerie-command")
(declare-function eerie--selection-fallback "eerie-command")
(declare-function eerie--make-selection "eerie-command")
(declare-function eerie--select "eerie-command")
(declare-function eerie-beacon-mode "eerie-core")
(declare-function eerie-change-save "eerie-command")
(declare-function eerie-escape-or-normal-modal "eerie-command")

(defvar-local eerie--beacon-overlays nil)
(defvar-local eerie--beacon-insert-enter-key nil)

(defun eerie--beacon-add-overlay-at-point (pos)
  "Create an overlay to draw a fake cursor as beacon at POS."
  (let ((ov (make-overlay pos (1+ pos) nil t)))
    (overlay-put ov 'face 'eerie-beacon-fake-cursor)
    (overlay-put ov 'eerie-beacon-type 'cursor)
    (push ov eerie--beacon-overlays)))

(defun eerie--beacon-add-overlay-at-region (type p1 p2 backward)
  "Create an overlay to draw a fake selection as beacon from P1 to 12.

TYPE is used for selection type.
Non-nil BACKWARD means backward direction."
  (let ((ov (make-overlay p1 p2)))
    (overlay-put ov 'face 'eerie-beacon-fake-selection)
    (overlay-put ov 'eerie-beacon-type type)
    (overlay-put ov 'eerie-beacon-backward backward)
    (push ov eerie--beacon-overlays)))

(defun eerie--beacon-remove-overlays ()
  "Remove all beacon overlays from current buffer."
  (mapc #'delete-overlay eerie--beacon-overlays)
  (setq eerie--beacon-overlays nil))

(defun eerie--maybe-toggle-beacon-state ()
  "Maybe switch to BEACON state."
  (unless (or defining-kbd-macro executing-kbd-macro)
    (let ((inside (eerie--beacon-inside-secondary-selection)))
      (cond
       ((and (eerie-normal-mode-p)
             inside)
        (eerie--switch-state 'beacon)
        (eerie--beacon-update-overlays))
       ((eerie-beacon-mode-p)
        (if inside
            (eerie--beacon-update-overlays)
          (eerie--beacon-remove-overlays)
          (eerie--switch-state 'normal)))))))

(defun eerie--beacon-shrink-selection ()
  "Shrink selection to one char width."
  (if eerie-use-cursor-position-hack
      (let ((m (if (eerie--direction-forward-p)
                   (1- (point))
                 (1+ (point)))))
        (eerie--cancel-selection)
        (thread-first
          (eerie--make-selection '(select . transient) m (point))
          (eerie--select t)))
    (eerie--cancel-selection)))

(defun eerie--beacon-apply-command (cmd)
  "Apply CMD in BEACON state."
  (when eerie--beacon-overlays
    (let ((bak (overlay-get (car eerie--beacon-overlays)
                            'eerie-beacon-backward)))
      (eerie--wrap-collapse-undo
        (save-mark-and-excursion
          (cl-loop for ov in (if bak (reverse eerie--beacon-overlays) eerie--beacon-overlays) do
                   (when (and (overlayp ov))
                     (let ((type (overlay-get ov 'eerie-beacon-type))
                           (backward (overlay-get ov 'eerie-beacon-backward)))
                       ;; always switch to normal state before applying kmacro
                       (eerie--switch-state 'normal)

                       (if (eq type 'cursor)
                           (progn
                             (eerie--cancel-selection)
                             (goto-char (overlay-start ov)))
                         (thread-first
                           (if backward
                               (eerie--make-selection
                                type (overlay-end ov) (overlay-start ov))
                             (eerie--make-selection type (overlay-start ov) (overlay-end ov)))
                           (eerie--select t)))

                       (call-interactively cmd))
                     (delete-overlay ov))))))))

(defun eerie--beacon-apply-kmacros-from-insert ()
  "Apply kmacros in BEACON state, after exiting from insert.

This is treated separately because we must enter each insert state the
same way, and escape each time the macro is applied."
  (eerie--beacon-apply-command (lambda ()
                                (interactive)
                                (eerie--execute-kbd-macro
                                 (key-description
                                  (vector eerie--beacon-insert-enter-key)))
                                (call-interactively #'kmacro-call-macro)
                                (eerie-escape-or-normal-modal))))

(defun eerie--beacon-apply-kmacros ()
  "Apply kmacros in BEACON state."
  (eerie--beacon-apply-command 'kmacro-call-macro))

(defun eerie--add-beacons-for-char ()
  "Add beacon for char movement."
  (save-restriction
    (let* ((bounds (eerie--second-sel-bound))
           (beg (car bounds))
           (end (cdr bounds))
           (curr (point))
           (col (- (point) (line-beginning-position)))
           break)
      (save-mark-and-excursion
        (while (< (line-end-position) end)
          (forward-line 1)
          (let ((pos (+ col (line-beginning-position))))
            (when (<= pos (min end (line-end-position)))
              (eerie--beacon-add-overlay-at-point pos)))))
      (save-mark-and-excursion
        (goto-char beg)
        (while (not break)
          (if (>= (line-end-position) curr)
              (setq break t)
            (let ((pos (+ col (line-beginning-position))))
              (when (and
                     (>= pos beg)
                     (<= pos (line-end-position)))
                (eerie--beacon-add-overlay-at-point pos)))
            (forward-line 1))))))
  (setq eerie--beacon-overlays (reverse eerie--beacon-overlays))
  (eerie--cancel-selection))

(defun eerie--add-beacons-for-char-expand ()
  "Add beacon for char expand movement."
  (save-restriction
    (let* ((bounds (eerie--second-sel-bound))
           (ss-beg (car bounds))
           (ss-end (cdr bounds))
           (curr (point))
           (bak (eerie--direction-backward-p))
           (beg-col (- (region-beginning) (line-beginning-position)))
           (end-col (- (region-end) (line-beginning-position)))
           break)
      (save-mark-and-excursion
        (while (< (line-end-position) ss-end)
          (forward-line 1)
          (let ((beg (+ beg-col (line-beginning-position)))
                (end (+ end-col (line-beginning-position))))
            (when (<= end (min ss-end (line-end-position)))
              (eerie--beacon-add-overlay-at-region
               '(expand . char)
               beg
               end
               bak)))))
      (save-mark-and-excursion
        (goto-char ss-beg)
        (while (not break)
          (if (>= (line-end-position) curr)
              (setq break t)
            (let ((beg (+ beg-col (line-beginning-position)))
                  (end (+ end-col (line-beginning-position))))
              (when (and
                     (>= beg ss-beg)
                     (<= end (line-end-position)))
                (eerie--beacon-add-overlay-at-region
                 '(expand . char)
                 beg
                 end
                 bak)))
            (forward-line 1)))))
    (setq eerie--beacon-overlays (reverse eerie--beacon-overlays))))

(defun eerie--add-beacons-for-thing (thing)
  "Add beacon for word movement."
  (save-restriction
    (eerie--narrow-secondary-selection)
    (let ((orig (point)))
      (if (eerie--direction-forward-p)
          ;; forward direction, add cursors at words' end
          (progn
            (save-mark-and-excursion
              (goto-char (point-min))
              (while (let ((p (point)))
                       (forward-thing thing 1)
                       (not (= p (point))))
                (unless (= (point) orig)
                  (eerie--beacon-add-overlay-at-point (eerie--hack-cursor-pos (point)))))))

        (save-mark-and-excursion
          (goto-char (point-max))
          (while (let ((p (point)))
                       (forward-thing thing -1)
                       (not (= p (point))))
            (unless (= (point) orig)
              (eerie--beacon-add-overlay-at-point (point))))))))
  (eerie--beacon-shrink-selection))

(defun eerie--add-beacons-for-match (match)
  "Add beacon for match(mark, visit or search).

MATCH is the search regexp."
  (save-restriction
    (eerie--narrow-secondary-selection)
    (let ((orig-end (region-end))
          (orig-beg (region-beginning))
          (back (eerie--direction-backward-p)))
      (save-mark-and-excursion
        (goto-char (point-min))
        (let ((case-fold-search nil))
          (while (re-search-forward match nil t)
            (unless (or (= orig-end (point))
                        (= orig-beg (point)))
              (let ((match (match-data)))
                (eerie--beacon-add-overlay-at-region
                 '(select . visit)
                 (car match)
                 (cadr match)
                 back)))))
        (setq eerie--beacon-overlays (reverse eerie--beacon-overlays))))))

(defun eerie--beacon-count-lines (beg end)
  "Count selected lines from BEG to END."
  (if (and (= (point) (line-beginning-position))
           (eerie--direction-forward-p))
      (1+ (count-lines beg end))
    (count-lines beg end)))

(defun eerie--beacon-forward-line (n bound)
  "Forward N line, inside BOUND."
  (cond
   ((> n 0)
    (when (> n 1) (forward-line (1- n)))
    (unless (<= bound (line-end-position))
      (forward-line 1)))
   ((< n 0)
    (when (< n -1) (forward-line (+ n 1)))
    (unless (>= bound (line-beginning-position))
      (forward-line -1)))
   (t
    (not (= (point) bound)))))

(defun eerie--add-beacons-for-line ()
  "Add beacon for line movement."
  (save-restriction
    (eerie--narrow-secondary-selection)
    (let* ((beg (region-beginning))
           (end (region-end))
           (ln (eerie--beacon-count-lines beg end))
           (back (eerie--direction-backward-p))
           prev)
      (save-mark-and-excursion
        (goto-char end)
        (forward-line)
        (setq prev (point))
        (while (eerie--beacon-forward-line
                (1- ln)
                (point-max))
          (eerie--beacon-add-overlay-at-region
           '(select . line)
           prev
           (line-end-position)
           back)
          (forward-line 1)
          (setq prev (point))))
      (save-mark-and-excursion
        (goto-char (point-min))
        (setq prev (point))
        (while (eerie--beacon-forward-line
                (1- ln)
                beg)
          (eerie--beacon-add-overlay-at-region
           '(select . line)
           prev
           (line-end-position)
           back)
          (forward-line 1)
          (setq prev (point)))))))

(defun eerie--add-beacons-for-join ()
  "Add beacon for join movement."
  (save-restriction
    (eerie--narrow-secondary-selection)
    (let ((orig (point)))
      (save-mark-and-excursion
        (goto-char (point-min))
        (back-to-indentation)
        (unless (= (point) orig)
          (eerie--beacon-add-overlay-at-point (point)))
        (while (< (line-end-position) (point-max))
          (forward-line 1)
          (back-to-indentation)
          (unless (= (point) orig)
            (eerie--beacon-add-overlay-at-point (point))))))
    (eerie--cancel-selection)))

(defun eerie--add-beacons-for-find ()
  "Add beacon for find movement."
  (let ((ch-str (if (eq eerie--last-find 13)
                   "\n"
                 (char-to-string eerie--last-find))))
    (save-restriction
      (eerie--narrow-secondary-selection)
      (let ((orig (point))
            (case-fold-search nil))
        (if (eerie--direction-forward-p)
            (save-mark-and-excursion
              (goto-char (point-min))
              (while (search-forward ch-str nil t)
                (unless (= orig (point))
                  (eerie--beacon-add-overlay-at-point (eerie--hack-cursor-pos (point))))))
          (save-mark-and-excursion
              (goto-char (point-max))
              (while (search-backward ch-str nil t)
                (unless (= orig (point))
                  (eerie--beacon-add-overlay-at-point (point))))))))
    (eerie--beacon-shrink-selection)))

(defun eerie--add-beacons-for-till ()
  "Add beacon for till movement."
  (let ((ch-str (if (eq eerie--last-till 13)
                    "\n"
                  (char-to-string eerie--last-till))))
    (save-restriction
      (eerie--narrow-secondary-selection)
      (let ((orig (point))
            (case-fold-search nil))
        (if (eerie--direction-forward-p)
            (progn
              (save-mark-and-excursion
                (goto-char (point-min))
                (while (search-forward ch-str nil t)
                  (unless (or (= orig (1- (point)))
                              (zerop (- (point) 2)))
                    (eerie--beacon-add-overlay-at-point (eerie--hack-cursor-pos (1- (point))))))))
          (save-mark-and-excursion
            (goto-char (point-max))
            (while (search-backward ch-str nil t)
              (unless (or (= orig (1+ (point)))
                          (= (point) (point-max)))
                (eerie--beacon-add-overlay-at-point (1+ (point)))))))))
    (eerie--beacon-shrink-selection)))

(defun eerie--beacon-region-words-to-match ()
  "Convert the word selected in region to a regexp."
  (let ((s (buffer-substring-no-properties
            (region-beginning)
            (region-end)))
        (re (car regexp-search-ring)))
    (if (string-match-p (format "\\`%s\\'" re) s)
        re
      (format "\\<%s\\>" (regexp-quote s)))))

(defun eerie--beacon-update-overlays ()
  "Update overlays for BEACON state."
  (eerie--beacon-remove-overlays)
  (when (eerie--beacon-inside-secondary-selection)
    (let* ((ex (car (eerie--selection-type)))
           (type (cdr (eerie--selection-type))))
      (cl-case type
        ((nil transient) (eerie--add-beacons-for-char))
        ((word) (if (not (eq 'expand ex))
                    (eerie--add-beacons-for-thing eerie-word-thing)
                  (eerie--add-beacons-for-match (eerie--beacon-region-words-to-match))))
        ((symbol) (if (not (eq 'expand ex))
                    (eerie--add-beacons-for-thing eerie-symbol-thing)
                  (eerie--add-beacons-for-match (eerie--beacon-region-words-to-match))))
        ((visit) (eerie--add-beacons-for-match (car regexp-search-ring)))
        ((line) (eerie--add-beacons-for-line))
        ((join) (eerie--add-beacons-for-join))
        ((find) (eerie--add-beacons-for-find))
        ((till) (eerie--add-beacons-for-till))
        ((char) (when (eq 'expand ex) (eerie--add-beacons-for-char-expand)))))))

(defun eerie-beacon-end-and-apply-kmacro ()
  "End or apply kmacro."
  (interactive)
  (call-interactively #'kmacro-end-macro)
  (eerie--beacon-apply-kmacros))

(defun eerie-beacon-start ()
  "Start kmacro recording, apply to all cursors when terminate."
  (interactive)
  (eerie--switch-state 'normal)
  (call-interactively 'kmacro-start-macro)
  (setq-local eerie--beacon-insert-enter-key nil)
  (setq eerie--beacon-defining-kbd-macro 'record))

(defun eerie-beacon-insert-exit ()
  "Exit insert mode and terminate kmacro recording."
  (interactive)
  (when defining-kbd-macro
    (end-kbd-macro)
    (eerie--beacon-apply-kmacros-from-insert))
  (eerie--switch-state 'beacon))

(defun eerie-beacon-insert ()
  "Insert and start kmacro recording.

Will terminate recording when exit insert mode.
The recorded kmacro will be applied to all cursors immediately."
  (interactive)
  (eerie-beacon-mode -1)
  (eerie-insert)
  (call-interactively #'kmacro-start-macro)
  (setq-local eerie--beacon-insert-enter-key last-input-event)
  (setq eerie--beacon-defining-kbd-macro 'quick))

(defun eerie-beacon-append ()
  "Append and start kmacro recording.

Will terminate recording when exit insert mode.
The recorded kmacro will be applied to all cursors immediately."
  (interactive)
  (eerie-beacon-mode -1)
  (eerie-append)
  (call-interactively #'kmacro-start-macro)
  (setq-local eerie--beacon-insert-enter-key last-input-event)
  (setq eerie--beacon-defining-kbd-macro 'quick))

(defun eerie-beacon-change ()
  "Change and start kmacro recording.

Will terminate recording when exit insert mode.
The recorded kmacro will be applied to all cursors immediately."
  (interactive)
  (eerie--with-selection-fallback
   (eerie-beacon-mode -1)
   (eerie-change)
   (call-interactively #'kmacro-start-macro)
   (setq-local eerie--beacon-insert-enter-key last-input-event)
   (setq eerie--beacon-defining-kbd-macro 'quick)))

(defun eerie-beacon-change-save ()
  "Change and start kmacro recording.

Will terminate recording when exit insert mode.
The recorded kmacro will be applied to all cursors immediately."
  (interactive)
  (eerie--with-selection-fallback
   (eerie-beacon-mode -1)
   (eerie-change-save)
   (call-interactively #'kmacro-start-macro)
   (setq-local eerie--beacon-insert-enter-key last-input-event)
   (setq eerie--beacon-defining-kbd-macro 'quick)))

(defun eerie-beacon-change-char ()
  "Change and start kmacro recording.

Will terminate recording when exit insert mode.
The recorded kmacro will be applied to all cursors immediately."
  (interactive)
  (eerie-beacon-mode -1)
  (eerie-change-char)
  (call-interactively #'kmacro-start-macro)
  (setq-local eerie--beacon-insert-enter-key last-input-event)
  (setq eerie--beacon-defining-kbd-macro 'quick))

(defun eerie-beacon-replace ()
  "Replace all selection with current kill-ring head."
  (interactive)
  (eerie--with-selection-fallback
   (eerie--wrap-collapse-undo
     (eerie-replace)
     (save-mark-and-excursion
       (cl-loop for ov in eerie--beacon-overlays do
                (when (and (overlayp ov)
                           (not (eq 'cursor (overlay-get ov 'eerie-beacon-type))))
                  (goto-char (overlay-start ov))
                  (push-mark (overlay-end ov) t)
                  (eerie-replace)
                  (delete-overlay ov)))))))

(defun eerie--beacon-delete-region ()
  (eerie--delete-region (region-beginning) (region-end)))

(defun eerie-beacon-kill-delete ()
  "Delete all selections.

By default, this command will be remapped to `eerie-kill'.
Because `eerie-kill' are used for deletion on region.

Only the content in real selection will be saved to `kill-ring'."
  (interactive)
  (eerie--with-selection-fallback
   (eerie--wrap-collapse-undo
     (eerie-kill)
     (save-mark-and-excursion
       (cl-loop for ov in eerie--beacon-overlays do
                (when (and (overlayp ov)
                           (not (eq 'cursor (overlay-get ov 'eerie-beacon-type))))
                  (goto-char (overlay-start ov))
                  (push-mark (overlay-end ov) t)
                  (eerie--beacon-delete-region)
                  (delete-overlay ov)))))))

(defun eerie-beacon-apply-kmacro ()
  (interactive)
  (eerie--switch-state 'normal)
  (call-interactively #'kmacro-call-macro)
  (eerie--beacon-apply-kmacros)
  (eerie--switch-state 'beacon))

(defun eerie-beacon-noop ()
  "Noop, to disable some keybindings in cursor state."
  (interactive))

(provide 'eerie-beacon)
;;; eerie-beacon.el ends here
