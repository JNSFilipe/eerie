;;; eerie-thing.el --- Calculate bounds of thing in Eerie  -*- lexical-binding: t -*-

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

(require 'cl-lib)
(require 'subr-x)

(require 'eerie-var)
(require 'eerie-util)

(declare-function eerie--visual-line-end-position "eerie-command")
(declare-function eerie--visual-line-beginning-position "eerie-command")

(defun eerie--bounds-of-symbol ()
  (when-let* ((bounds (bounds-of-thing-at-point eerie-symbol-thing)))
    (let ((beg (car bounds))
          (end (cdr bounds)))
      (save-mark-and-excursion
        (goto-char end)
        (if (not (looking-at-p "\\s)"))
            (while (looking-at-p " \\|,")
              (goto-char (cl-incf end)))
          (goto-char beg)
          (while (looking-back " \\|," 1)
            (goto-char (cl-decf beg))))
        (cons beg end)))))

(defun eerie--bounds-of-string-1 ()
  "Return the bounds of the string under the cursor.

The thing `string' is not available in Emacs 27.'"
  (if (version< emacs-version "28")
      (when (eerie--in-string-p)
        (let (beg end)
          (save-mark-and-excursion
            (while (eerie--in-string-p)
              (backward-char 1))
            (setq beg (point)))
          (save-mark-and-excursion
            (while (eerie--in-string-p)
              (forward-char 1))
            (setq end (point)))
          (cons beg end)))
    (bounds-of-thing-at-point 'string)))

(defun eerie--inner-of-symbol ()
  (bounds-of-thing-at-point eerie-symbol-thing))

(defun eerie--bounds-of-string (&optional inner)
  (when-let* ((bounds (eerie--bounds-of-string-1)))
    (let ((beg (car bounds))
          (end (cdr bounds)))
      (cons
       (save-mark-and-excursion
         (goto-char beg)
         (funcall (if inner #'skip-syntax-forward #'skip-syntax-backward) "\"|")
         (point))
       (save-mark-and-excursion
         (goto-char end)
         (funcall (if inner #'skip-syntax-backward #'skip-syntax-forward) "\"|")
         (point))))))

(defun eerie--inner-of-string ()
  (eerie--bounds-of-string t))

(defun eerie--inner-of-window ()
  (cons (window-start) (window-end)))

(defun eerie--inner-of-line ()
  (cons (save-mark-and-excursion (back-to-indentation) (point))
        (line-end-position)))

(defun eerie--inner-of-visual-line ()
  (cons (eerie--visual-line-beginning-position)
        (eerie--visual-line-end-position)))

;;; Registry

(defvar eerie--thing-registry nil
  "Thing registry.

This is a plist mapping from thing to (inner-fn . bounds-fn).
Both inner-fn and bounds-fn returns a cons of (start . end) for that thing.")

(defun eerie--thing-register (thing inner-fn bounds-fn)
  "Register INNER-FN and BOUNDS-FN to a THING."
  (setq eerie--thing-registry
        (plist-put eerie--thing-registry
                   thing
                   (cons inner-fn bounds-fn))))

(defun eerie--thing-syntax-function (syntax)
  (cons
   (save-mark-and-excursion
     (when (use-region-p)
       (goto-char (region-beginning)))
     (skip-syntax-backward (cdr syntax))
     (point))
   (save-mark-and-excursion
     (when (use-region-p)
       (goto-char (region-end)))
     (skip-syntax-forward (cdr syntax))
     (point))))

(defun eerie--thing-regexp-function (b-re f-re near)
  (let ((beg (save-mark-and-excursion
               (when (use-region-p)
                 (goto-char (region-beginning)))
               (when (re-search-backward b-re nil t)
                 (if near (match-end 0) (point)))))
        (end (save-mark-and-excursion
               (when (use-region-p)
                 (goto-char (region-end)))
               (when (re-search-forward f-re nil t)
                 (if near (match-beginning 0) (point))))))
    (when (and beg end)
      (cons beg end))))

(defun eerie--thing-parse-pair-search (push-token pop-token back near)
  (let* ((search-fn (if back #'re-search-backward #'re-search-forward))
         (match-fn (if back #'match-end #'match-beginning))
         (cmp-fn (if back #'> #'<))
         (push-next-pos nil)
         (pop-next-pos nil)
         (push-pos (save-mark-and-excursion
                     (when (funcall search-fn push-token nil t)
                       (setq push-next-pos (point))
                       (if near (funcall match-fn 0) (point)))))
         (pop-pos (save-mark-and-excursion
                    (when (funcall search-fn pop-token nil t)
                      (setq pop-next-pos (point))
                      (if near (funcall match-fn 0) (point))))))
    (cond
     ((and (not pop-pos) (not push-pos))
      nil)
     ((not pop-pos)
      (goto-char push-next-pos)
      (cons 'push push-pos))
     ((not push-pos)
      (goto-char pop-next-pos)
      (cons 'pop pop-pos))
     ((funcall cmp-fn push-pos pop-pos)
      (goto-char push-next-pos)
      (cons 'push push-pos))
     (t
      (goto-char pop-next-pos)
      (cons 'pop pop-pos)))))

(defun eerie--thing-pair-function (push-token pop-token near)
  (let* ((found nil)
         (depth  0)
         (beg (save-mark-and-excursion
                (prog1
                    (let ((case-fold-search nil))
                      (while (and (<= depth 0)
                                  (setq found (eerie--thing-parse-pair-search push-token pop-token t near)))
                        (let ((push-or-pop (car found)))
                          (if (eq 'push push-or-pop)
                              (cl-incf depth)
                            (cl-decf depth))))
                      (when (> depth 0) (cdr found)))
                  (setq depth 0
                        found nil))))
         (end (save-mark-and-excursion
                (let ((case-fold-search nil))
                  (while (and (>= depth 0)
                              (setq found (eerie--thing-parse-pair-search push-token pop-token nil near)))
                    (let ((push-or-pop (car found)))
                      (if (eq 'push push-or-pop)
                          (cl-incf depth)
                        (cl-decf depth))))
                  (when (< depth 0) (cdr found))))))
    (when (and beg end)
      (cons beg end))))


(defun eerie--thing-make-syntax-function (x)
  (lambda () (eerie--thing-syntax-function x)))

(defun eerie--thing-make-regexp-function (x near)
  (let* ((b-re (cadr x))
         (f-re (caddr x)))
    (lambda () (eerie--thing-regexp-function b-re f-re near))))

(defun eerie--thing-make-pair-function (x near)
  (let* ((push-token (let ((tokens (cadr x)))
                       (string-join (mapcar #'regexp-quote tokens) "\\|")))
         (pop-token (let ((tokens (caddr x)))
                      (string-join (mapcar #'regexp-quote tokens) "\\|"))))
    (lambda () (eerie--thing-pair-function push-token pop-token near))))

(defun eerie--thing-make-pair-regexp-function (x near)
  (let* ((push-token (let ((tokens (cadr x)))
                       (string-join  tokens "\\|")))
         (pop-token (let ((tokens (caddr x)))
                      (string-join  tokens "\\|"))))
    (lambda () (eerie--thing-pair-function push-token pop-token near))))

(defun eerie--thing-parse-multi (xs near)
  (let ((chained-fns (mapcar (lambda (x) (eerie--thing-parse x near)) xs)))
    (lambda ()
      (let ((fns chained-fns)
            ret)
        (while (and fns (not ret))
          (setq ret (funcall (car fns))
                fns (cdr fns)))
        ret))))

(defun eerie--thing-parse (x near)
  (cond
   ((functionp x)
    x)
   ((symbolp x)
    (lambda () (bounds-of-thing-at-point x)))
   ((equal 'syntax (car x))
    (eerie--thing-make-syntax-function x))
   ((equal 'regexp (car x))
    (eerie--thing-make-regexp-function x near))
   ((equal 'pair (car x))
    (eerie--thing-make-pair-function x near))
   ((equal 'pair-regexp (car x))
    (eerie--thing-make-pair-regexp-function x near))
   ((listp x)
    (eerie--thing-parse-multi x near))
   (t
    (lambda ()
      (message "Eerie: THING definition broken")
      (cons (point) (point))))))

(defun eerie-thing-register (thing inner bounds)
  "Register a THING with INNER and BOUNDS.

Argument THING should be symbol, which specified in `eerie-char-thing-table'.
Argument INNER and BOUNDS support following expressions:

  EXPR ::= FUNCTION | SYMBOL | SYNTAX-EXPR | REGEXP-EXPR
         | PAIRED-EXPR | MULTI-EXPR
  SYNTAX-EXPR ::= (syntax . STRING)
  REGEXP-EXPR ::= (regexp STRING STRING)
  PAIRED-EXPR ::= (pair TOKENS TOKENS)
  PAIRED-REGEXP-EXPR ::= (pair-regexp TOKENS-REGEXP TOKENS-REGEXP)
  MULTI-EXPR ::= (EXPR ...)
  TOKENS ::= (STRING ...)

FUNCTION is a function receives no arguments, return a cons which
  the car is the beginning of thing, and the cdr is the end of
  thing.

SYMBOL is a symbol represent a builtin thing.

  Example: url

    (eerie-thing-register \\='url \\='url \\='url)

SYNTAX-EXPR contains a syntax description used by `skip-syntax-forward'

  Example: non-whitespaces

    (eerie-thing-register \\='non-whitespace
                         \\='(syntax . \"^-\")
                         \\='(syntax . \"^-\"))

  You can find the description for syntax in current buffer with
  \\[describe-syntax].

REGEXP-EXPR contains two regexps, the first is used for
  beginning, the second is used for end. For inner/beginning/end
  function, the point of near end of match will be used.  For
  bounds function, the point of far end of match will be used.

  Example: quoted

    (eerie-thing-register \\='quoted
                         \\='(regexp \"\\=`\" \"\\=`\\\\|\\='\")
                         \\='(regexp \"\\=`\" \"\\=`\\\\|\\='\"))

PAIR-EXPR contains two string token lists. The tokens in first
  list are used for finding beginning, the tokens in second list
  are used for finding end.  A depth variable will be used while
  searching, thus only matched pair will be found.

  Example: do/end block

    (eerie-thing-register \\='do/end
                         \\='(pair (\"do\") (\"end\"))
                         \\='(pair (\"do\") (\"end\")))

PAIR-REGEXP-EXPR contains two regexp lists. The regexp in first
  list are used for finding beginning, the regexp in second list
  are used for finding end.  A depth variable will be used while
  searching, thus only matched pair will be found.

  Example: The inner block of `{}` will ignore newlines and spaces
           after \\='{\\=' before \\='}\\='.
    (eerie-thing-register \\='code-block
                         \\='(pair-regexp (\"{[\\n\\t ]*\")  (\"[\\n\\t ]*}\") )
                         \\='(pair (\"{\") (\"}\")))"
    (let ((inner-fn (eerie--thing-parse inner t))
          (bounds-fn (eerie--thing-parse bounds nil)))
      (eerie--thing-register thing inner-fn bounds-fn)))

(eerie-thing-register 'round
                     '(pair ("(") (")"))
                     '(pair ("(") (")")))

(eerie-thing-register 'square
                     '(pair ("[") ("]"))
                     '(pair ("[") ("]")))

(eerie-thing-register 'curly
                     '(pair ("{") ("}"))
                     '(pair ("{") ("}")))

(eerie-thing-register 'double-quote
                     '(regexp "\"" "\"")
                     '(regexp "\"" "\""))

(eerie-thing-register 'single-quote
                     '(regexp "'" "'")
                     '(regexp "'" "'"))

(eerie-thing-register 'paragraph 'paragraph 'paragraph)

(eerie-thing-register 'sentence 'sentence 'sentence)

(eerie-thing-register 'buffer 'buffer 'buffer)

(eerie-thing-register 'defun 'defun 'defun)

(eerie-thing-register eerie-symbol-thing #'eerie--inner-of-symbol #'eerie--bounds-of-symbol)

(eerie-thing-register 'string #'eerie--inner-of-string #'eerie--bounds-of-string)

(eerie-thing-register 'window #'eerie--inner-of-window #'eerie--inner-of-window)

(eerie-thing-register 'line #'eerie--inner-of-line 'line)

(eerie-thing-register 'visual-line #'eerie--inner-of-visual-line #'eerie--inner-of-visual-line)

(defun eerie--parse-inner-of-thing-char (ch)
  (when-let* ((ch-to-thing (assoc ch eerie-char-thing-table)))
    (eerie--parse-range-of-thing (cdr ch-to-thing) t)))

(defun eerie--parse-bounds-of-thing-char (ch)
  (when-let* ((ch-to-thing (assoc ch eerie-char-thing-table)))
    (eerie--parse-range-of-thing (cdr ch-to-thing) nil)))

(defun eerie--parse-range-of-thing (thing inner)
  "Parse either inner or bounds of THING. If INNER is non-nil then parse inner."
  (when-let* ((bounds-fn-pair (plist-get eerie--thing-registry thing)))
    (if inner
        (funcall (car bounds-fn-pair))
      (funcall (cdr bounds-fn-pair)))))

(provide 'eerie-thing)
;;; eerie-thing.el ends here
