;;; eerie-face.el --- Faces for Eerie  -*- lexical-binding: t; -*-

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
;; Faces for Eerie.

;;; Code:

(require 'eerie-var)

(declare-function eerie--mix-color "eerie-util")

(defface eerie-normal-indicator
  '((((class color) (background dark))
     ())
    (((class color) (background light))
     ()))
  "Normal state indicator."
  :group 'eerie)

(defface eerie-visual-indicator
  '((((class color) (background dark))
     ())
    (((class color) (background light))
     ()))
  "Visual state indicator."
  :group 'eerie)

(defface eerie-beacon-indicator
  '((((class color) (background dark))
     ())
    (((class color) (background light))
     ()))
  "Cursor state indicator."
  :group 'eerie)

(defface eerie-insert-indicator
  '((((class color) (background dark))
     ())
    (((class color) (background light))
     ()))
  "Insert state indicator."
  :group 'eerie)

(defface eerie-motion-indicator
  '((((class color) (background dark))
     ())
    (((class color) (background light))
     ()))
  "Motion state indicator."
  :group 'eerie)

(defface eerie-normal-cursor
  '((((class color) (background dark))
     (:inherit cursor))
    (((class color) (background light))
     (:inherit cursor)))
  "Normal state cursor."
  :group 'eerie)

(defface eerie-visual-cursor
  '((((class color) (background dark))
     (:inherit region))
    (((class color) (background light))
     (:inherit region)))
  "Visual state cursor."
  :group 'eerie)

(defface eerie-insert-cursor
  '((((class color) (background dark))
     (:inherit cursor))
    (((class color) (background light))
     (:inherit cursor)))
  "Insert state cursor."
  :group 'eerie)

(defface eerie-motion-cursor
  '((((class color) (background dark))
     (:inherit cursor))
    (((class color) (background light))
     (:inherit cursor)))
  "Motion state cursor."
  :group 'eerie)

(defface eerie-beacon-cursor
  '((t (:inherit cursor)))
  "BEACON cursor face."
  :group 'eerie)

(defface eerie-beacon-fake-selection
  '((t (:inherit region)))
  "BEACON selection face."
  :group 'eerie)

(defface eerie-beacon-fake-cursor
  '((t (:inherit region :extend nil)))
  "BEACON selection face."
  :group 'eerie)

(defface eerie-unknown-cursor
  '((((class color) (background dark))
     (:inherit cursor))
    (((class color) (background light))
     (:inherit cursor)))
  "Unknown state cursor."
  :group 'eerie)

(defface eerie-region-cursor-1
  `((((class color) (background dark)))
    (((class color) (background light))))
  "Indicator for region direction."
  :group 'eerie)

(defface eerie-region-cursor-2
  `((((class color) (background dark)))
    (((class color) (background light))))
  "Indicator for region direction."
  :group 'eerie)

(defface eerie-region-cursor-3
  `((((class color) (background dark)))
    (((class color) (background light))))
  "Indicator for region direction."
  :group 'eerie)

(defface eerie-kmacro-cursor
  `((t (:underline t)))
  "Indicator for region direction."
  :group 'eerie)

(defface eerie-search-highlight
  '((t (:inherit lazy-highlight)))
  "Search target highlight."
  :group 'eerie)

(defface eerie-position-highlight-number
  '((((class color) (background dark))
     (:inherit default))
    (((class color) (background light))
     (:inherit default)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-position-highlight-number-1
  '((t (:inherit eerie-position-highlight-number)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-position-highlight-number-2
  '((t (:inherit eerie-position-highlight-number)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-position-highlight-number-3
  '((t (:inherit eerie-position-highlight-number)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-position-highlight-reverse-number-1
  '((t (:inherit eerie-position-highlight-number-1)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-position-highlight-reverse-number-2
  '((t (:inherit eerie-position-highlight-number-2)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-position-highlight-reverse-number-3
  '((t (:inherit eerie-position-highlight-number-3)))
  "Num position highlight."
  :group 'eerie)

(defface eerie-search-indicator
  '((((class color) (background dark))
     (:foreground "grey40"))
    (((class color) (background light))
     (:foreground "grey60")))
  "Face for search indicator."
  :group 'eerie)

(defface eerie-cheatsheet-command
  '((t (:inherit fixed-pitch :height 90)))
  "Face for Eerie cheatsheet command."
  :group 'eerie)

(defface eerie-cheatsheet-highlight
  '((((class color) (background dark))
     (:foreground "grey90" :inherit eerie-cheatsheet-command))
    (((class color) (background light))
     (:foreground "grey10" :inherit eerie-cheatsheet-command)))
  "Face for Eerie cheatsheet highlight text."
  :group 'eerie)

(defun eerie--prepare-face (&rest _ignore)
  "Calculate faces based on current theme dynamically.

This function will be called after each time the theme changed."
  (when eerie-use-dynamic-face-color
    (when-let* ((r (face-background 'region nil t))
                (c (face-background 'cursor nil t))
                (s (face-background 'secondary-selection nil t))
                (b (face-background 'default nil t))
                (f (face-foreground 'default nil t))
                (bc (face-background 'eerie-beacon-cursor nil t)))
      (when (and (color-defined-p r)
                 (color-defined-p c))
        (let* ((clrs (eerie--mix-color c r 3))
               (c1 (car clrs))
               (c2 (cadr clrs))
               (c3 (caddr clrs)))
          (set-face-attribute 'eerie-region-cursor-1 nil :background c1 :foreground f :distant-foreground b)
          (set-face-attribute 'eerie-region-cursor-2 nil :background c2 :foreground f :distant-foreground b)
          (set-face-attribute 'eerie-region-cursor-3 nil :background c3 :foreground f :distant-foreground b)))

      (set-face-attribute 'eerie-position-highlight-number nil :foreground b :distant-foreground f)

      (when (and (color-defined-p c)
                 (color-defined-p b))
        (let ((c-b-3 (eerie--mix-color c b 3)))
          (set-face-background 'eerie-position-highlight-number-1 (car c-b-3))
          (set-face-background 'eerie-position-highlight-number-2 (cadr c-b-3))
          (set-face-background 'eerie-position-highlight-number-3 (caddr c-b-3))))

      (when (and (color-defined-p r)
                 (color-defined-p s))
        (set-face-attribute 'eerie-beacon-fake-selection
                            nil
                            :foreground b
                            :distant-foreground f
                            :background (car (eerie--mix-color r s 1))))

      (when (and (color-defined-p bc)
                 (color-defined-p s))
        (set-face-attribute 'eerie-beacon-fake-cursor
                            nil
                            :foreground b
                            :distant-foreground f
                            :extend nil
                            :background (car (eerie--mix-color bc s 1)))))))

(provide 'eerie-face)
;;; eerie-face.el ends here
