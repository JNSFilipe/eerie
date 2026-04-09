;;; eerie-cheatsheet.el --- Cheatsheet for Eerie  -*- lexical-binding: t; -*-

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
;; Cheatsheet for Eerie.

;;; Code:

(require 'eerie-var)
(require 'eerie-util)
(require 'eerie-cheatsheet-layout)

(defconst eerie--cheatsheet-note
  (format "
NOTE:
%s means this command will expand current region.
" (propertize "ex" 'face 'eerie-cheatsheet-highlight)))

(defun eerie--render-cheatsheet-thing-table ()
  (concat
   (format
    "%s, %s, %s and %s require a %s as input:\n"
    (propertize "←thing→ (inner)" 'face 'eerie-cheatsheet-highlight)
    (propertize "[thing] (bounds)" 'face 'eerie-cheatsheet-highlight)
    (propertize "←thing (begin)" 'face 'eerie-cheatsheet-highlight)
    (propertize "thing→ (end)" 'face 'eerie-cheatsheet-highlight)
    (propertize "THING" 'face 'eerie-cheatsheet-highlight))
   (eerie--cheatsheet-render-char-thing-table 'eerie-cheatsheet-highlight)))

(defvar eerie-cheatsheet-physical-layout eerie-cheatsheet-physical-layout-ansi
  "Physical keyboard layout used to display cheatsheet.

Currently `eerie-cheatsheet-physical-layout-ansi' is supported.")

(defvar eerie-cheatsheet-layout eerie-cheatsheet-layout-qwerty
  "Keyboard layout used to display cheatsheet.

Currently `eerie-cheatsheet-layout-qwerty', `eerie-cheatsheet-layout-dvorak',
`eerie-cheatsheet-layout-dvp' and `eerie-cheatsheet-layout-colemak' is supported.")

(defun eerie--short-command-name (cmd)
  (or
   (when (symbolp cmd)
     (when-let* ((s
                  (or (alist-get cmd eerie-command-to-short-name-list)
                      (cl-case cmd
                        (undefined "")
                        (t (thread-last
                             (symbol-name cmd)
                             (replace-regexp-in-string "eerie-" "")))))))
       (if (<= (length s) 9)
           (format "% 9s" s)
         (eerie--truncate-string 9 s eerie-cheatsheet-ellipsis))))
   "         "))

(defun eerie--cheatsheet-replace-keysyms ()
  (dolist (it eerie-cheatsheet-layout)
    (let* ((keysym (car it))
           (lower (cadr it))
           (upper (caddr it))
           (tgt (concat "  " (symbol-name keysym) " "))
           (lower-cmd (key-binding (read-kbd-macro lower)))
           (upper-cmd (key-binding (read-kbd-macro upper))))
      (goto-char (point-min))
      (when (search-forward tgt nil t)
        (let ((x (- (point) (line-beginning-position))))
          (delete-char -9)
          (insert (concat "       " upper " "))
          (forward-line 1)
          (forward-char x)
          (delete-char -9)
          (insert (propertize (eerie--short-command-name upper-cmd) 'face 'eerie-cheatsheet-highlight))
          (forward-line 2)
          (forward-char x)
          (delete-char -9)
          (insert (concat "       " lower " "))
          (forward-line 1)
          (forward-char x)
          (delete-char -9)
          (insert (propertize (eerie--short-command-name lower-cmd) 'face 'eerie-cheatsheet-highlight)))))))

(defun eerie--cheatsheet-render-char-thing-table (&optional key-face)
  (let* ((ww (frame-width))
         (w 16)
         (col (min 5 (/ ww w))))
    (thread-last
      (seq-map-indexed
       (lambda (it idx)
         (let ((c (car it))
               (th (cdr it)))
           (format "% 9s ->% 3s%s"
                   (symbol-name th)
                   (propertize (char-to-string c) 'face (or key-face 'font-lock-keyword-face))
                   (if (= (1- col) (mod idx col))
                       "\n"
                     " "))))
       eerie-char-thing-table)
      (string-join)
      (string-trim-right))))

(defun eerie-cheatsheet ()
  (interactive)
  (cond
   ((not eerie-cheatsheet-physical-layout)
    (message "`eerie-cheatsheet-physical-layout' is not specified"))
   ((not eerie-cheatsheet-layout)
    (message "`eerie-cheatsheet-layout' is not specified"))
   (t
    (let ((buf (get-buffer-create (format "*Eerie Cheatsheet*"))))
    (with-current-buffer buf
      (text-mode)
      (setq buffer-read-only nil)
      (erase-buffer)
      (apply #'insert (make-list 63 " "))
      (insert "Eerie Cheatsheet\n")
      (insert eerie-cheatsheet-physical-layout)
      (eerie--cheatsheet-replace-keysyms)
      (goto-char (point-max))
      (insert eerie--cheatsheet-note)
      (insert (eerie--render-cheatsheet-thing-table))
      (add-face-text-property (point-min) (point-max) 'eerie-cheatsheet-command)
      (setq buffer-read-only t))
    (switch-to-buffer buf)))))

(provide 'eerie-cheatsheet)
;;; eerie-cheatsheet.el ends here
