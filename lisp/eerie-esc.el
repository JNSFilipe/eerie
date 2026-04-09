;;; eerie-esc.el --- make ESC works in TUI       -*- lexical-binding: t; -*-

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; In the terminal, ESC can be used as META, because they send the
;; same keycode.  To allow both usages simulataneously, you can
;; customize eerie-esc-delay, the maximum time between ESC and the
;; keypress that should be treated as a meta combo. If the time is
;; longer than the delay, it's treated as pressing ESC and then the
;; key separately.
;;; Code:

(defvar eerie-esc-delay 0.1)
(defvar eerie--escape-key-seq [?\e])

;;;###autoload
(define-minor-mode eerie-esc-mode
  "Mode that ensures ESC works in the terminal"
  :init-value nil
  :global t
  :group 'eerie
  :keymap nil
  (if eerie-esc-mode
      (progn
        (setq eerie-esc-mode t)
        (add-hook 'after-make-frame-functions #'eerie--init-esc-if-tui)
        (mapc #'eerie--init-esc-if-tui (frame-list)))
    (progn
      (remove-hook 'after-make-frame-functions #'eerie--init-esc-if-tui)
      (mapc #'eerie--deinit-esc-if-tui (frame-list))
      (setq eerie-esc-mode nil))))


(defun eerie--init-esc-if-tui (frame)
  (with-selected-frame frame
    (unless window-system
      (let ((term (frame-terminal frame)))
        (when (not (terminal-parameter term 'eerie-esc-map))
          (let ((eerie-esc-map (lookup-key input-decode-map [?\e])))
            (set-terminal-parameter term 'eerie-esc-map eerie-esc-map)
            (define-key input-decode-map eerie--escape-key-seq
                        `(menu-item "" ,eerie-esc-map :filter ,#'eerie-esc))))))))

(defun eerie--deinit-esc-if-tui (frame)
  (with-selected-frame frame
    (unless window-system
      (let ((term (frame-terminal frame)))
        (when (terminal-live-p term)
          (let ((eerie-esc-map (terminal-parameter term 'eerie-esc-map)))
            (when eerie-esc-map
              (define-key input-decode-map eerie--escape-key-seq eerie-esc-map)
              (set-terminal-parameter term 'eerie-esc-map nil))))))))

(defun eerie-esc (map)
  (if (and (let ((keys (this-single-command-keys)))
             (and (> (length keys) 0)
                  (= (aref keys (1- (length keys))) ?\e)))
           (sit-for eerie-esc-delay))
      (prog1 [escape]
        (when defining-kbd-macro
          (end-kbd-macro)
          (setq last-kbd-macro (vconcat last-kbd-macro [escape]))
          (start-kbd-macro t t)))
    map))

(provide 'eerie-esc)
;;; eerie-esc.el ends here
