;;; eerie-visual.el --- Visual effect in Eerie  -*- lexical-binding: t; -*-

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
(require 'pcase)

(require 'eerie-var)
(require 'eerie-util)

(declare-function hl-line-highlight "hl-line")

(defvar eerie--expand-overlays nil
  "Overlays used to highlight expand hints in buffer.")

(defvar eerie--match-overlays nil
  "Overlays used to highlight matches in buffer.")

(defvar eerie--search-indicator-overlay nil
  "Overlays used to display search indicator in current line.")

(defvar-local eerie--search-indicator-state nil
  "The state for search indicator.

Value is a list of (last-regexp last-pos idx cnt).")

(defvar eerie--dont-remove-overlay nil
  "Indicate we should prevent removing overlay for once.")

(defvar eerie--highlight-timer nil
  "Timer for highlight cleaner.")

(defun eerie--remove-expand-highlights ()
  (mapc #'delete-overlay eerie--expand-overlays)
  (setq eerie--expand-overlays nil))

(defun eerie--remove-match-highlights ()
  (mapc #'delete-overlay eerie--match-overlays)
  (setq eerie--match-overlays nil))

(defun eerie--remove-search-highlight ()
  (when eerie--search-indicator-overlay
    (delete-overlay eerie--search-indicator-overlay)))

(defun eerie--clean-search-indicator-state ()
  (setq eerie--search-indicator-overlay nil
        eerie--search-indicator-state nil))

(defun eerie--remove-search-indicator ()
  (eerie--remove-search-highlight)
  (eerie--clean-search-indicator-state))

(defun eerie--show-indicator (pos idx cnt)
  (goto-char pos)
  (goto-char (line-end-position))
  (if (= (point) (point-max))
      (let ((ov (make-overlay (point) (point))))
        (overlay-put ov 'after-string (propertize (format " [%d/%d]" idx cnt) 'face 'eerie-search-indicator))
        (setq eerie--search-indicator-overlay ov))
    (let ((ov (make-overlay (point) (1+ (point)))))
      (overlay-put ov 'display (propertize (format " [%d/%d] \n" idx cnt) 'face 'eerie-search-indicator))
      (setq eerie--search-indicator-overlay ov))))

(defun eerie--highlight-match ()
  (let ((beg (match-beginning 0))
        (end (match-end 0)))
    (unless (cl-find-if (lambda (it)
                          (overlay-get it 'eerie))
                        (overlays-at beg))
      (let ((ov (make-overlay beg end)))
        (overlay-put ov 'face 'eerie-search-highlight)
        (overlay-put ov 'priority 0)
        (overlay-put ov 'eerie t)
        (push ov eerie--match-overlays)))))

(defun eerie--highlight-regexp-in-buffer (regexp)
  "Highlight all regexp in this buffer."
  (when (and (eerie-normal-mode-p)
             (region-active-p))
    (eerie--remove-expand-highlights)
    (let* ((cnt 0)
           (idx 0)
           (pos (region-end))
           (hl-start (max (point-min) (- (point) 3000)))
           (hl-end (min (point-max) (+ (point) 3000))))
      (setq eerie--expand-nav-function nil)
      (setq eerie--visual-command this-command)
      (save-mark-and-excursion
        (eerie--remove-search-indicator)
        (let ((case-fold-search nil))
          (goto-char (point-min))
          (while (re-search-forward regexp (point-max) t)
            (cl-incf cnt)
            (when (<= (match-beginning 0) pos (match-end 0))
              (setq idx cnt))
            (when (<= hl-start (point) hl-end)
              (eerie--highlight-match)))
          (eerie--show-indicator pos idx cnt))))))

(defun eerie--format-full-width-number (n)
  (alist-get n eerie-full-width-number-position-chars))

(defun eerie--highlight-num-positions-1 (nav-function faces bound)
  (save-mark-and-excursion
    (let ((pos (point))
          (i 1))
      (cl-loop for face in faces
               do
               (if-let* ((r (funcall nav-function)))
                   (if (> r 0)
                       (save-mark-and-excursion
                         (goto-char r)
                         (if (or (> (point) (cdr bound))
                                 (< (point) (car bound))
                                 (= (point) pos))
                             (cl-return)
                           (setq pos (point))
                           (let ((ov (make-overlay (point) (1+ (point))))
                                 (before-full-width-char (and (char-after) (= 2 (char-width (char-after)))))
                                 (before-newline (equal 10 (char-after)))
                                 (before-tab (equal 9 (char-after)))
                                 (n (mod i 10)))
                             (overlay-put ov 'window (selected-window))
                             (cond
                              (before-newline
                               (overlay-put ov 'display (concat (propertize (format "%s" n) 'face face) "\n")))
                              (before-tab
                               (overlay-put ov 'display (concat (propertize (format "%s" n) 'face face) "\t")))
                              (before-full-width-char
                               (overlay-put ov 'display (propertize (format "%s" (eerie--format-full-width-number n)) 'face face)))
                              (t
                               (overlay-put ov 'display (propertize (format "%s" n) 'face face))))
                             (push ov eerie--expand-overlays)
                             (cl-incf i))))
                     (cl-return))
                 (cl-return))))))

(defun eerie--highlight-num-positions (num)
  (setq eerie--visual-command this-command)
  (eerie--remove-expand-highlights)
  (eerie--remove-match-highlights)
  (eerie--remove-search-indicator)
  (let ((bound (cons (window-start) (window-end)))
        (faces (seq-take
                (if (eerie--direction-backward-p)
                    (seq-concatenate
                     'list
                     (make-list 10 'eerie-position-highlight-reverse-number-1)
                     (make-list 10 'eerie-position-highlight-reverse-number-2)
                     (make-list 10 'eerie-position-highlight-reverse-number-3))
                  (seq-concatenate
                   'list
                   (make-list 10 'eerie-position-highlight-number-1)
                   (make-list 10 'eerie-position-highlight-number-2)
                   (make-list 10 'eerie-position-highlight-number-3)))
                num))
        (nav-function (if (eerie--direction-backward-p)
                          (car eerie--expand-nav-function)
                        (cdr eerie--expand-nav-function))))
    (eerie--highlight-num-positions-1 nav-function faces bound)
    (when eerie--highlight-timer
      (cancel-timer eerie--highlight-timer)
      (setq eerie--highlight-timer nil))
    (setq eerie--highlight-timer
          (run-at-time
           (time-add (current-time)
                     (seconds-to-time eerie-expand-hint-remove-delay))
           nil
           #'eerie--remove-expand-highlights))))

(defun eerie--select-expandable-p ()
  (when (eerie-normal-mode-p)
    (when-let* ((sel (eerie--selection-type)))
      (let ((type (cdr sel)))
        (member type '(word symbol line block find till))))))

(defun eerie--maybe-highlight-num-positions (&optional nav-functions)
  (when (and (eerie-normal-mode-p)
             (eerie--select-expandable-p))
    (setq eerie--expand-nav-function (or nav-functions eerie--expand-nav-function))
    (when (and (not (member major-mode eerie-expand-exclude-mode-list))
               eerie--expand-nav-function)
      (let ((num (or
                  (alist-get (cdr (eerie--selection-type)) eerie-expand-hint-counts)
                  0)))
        (eerie--highlight-num-positions num)))))

(provide 'eerie-visual)
;;; eerie-visual.el ends here
