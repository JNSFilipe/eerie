;;; eerie-vim-tests.el --- Tests for Vim-style Eerie fork -*- lexical-binding: t; -*-

(require 'cl-lib)
(require 'ert)
(require 'eerie nil nil)

(defmacro eerie-test-with-buffer (content &rest body)
  "Run BODY in a temporary Eerie-enabled buffer seeded with CONTENT."
  (declare (indent 1) (debug t))
  `(let ((buf (generate-new-buffer " *eerie-test*"))
         (global-mark-ring nil)
         (regexp-search-ring nil)
         (eerie--last-search-direction 'forward)
         (kill-ring nil)
         (kill-ring-yank-pointer nil)
         (unread-command-events nil)
         (last-kbd-macro nil)
         (executing-kbd-macro nil)
         (defining-kbd-macro nil)
         (last-command nil)
         (real-last-command nil)
         (this-command nil))
     (unwind-protect
         (save-window-excursion
           (switch-to-buffer buf)
           (erase-buffer)
           (fundamental-mode)
           (buffer-enable-undo)
           (transient-mark-mode 1)
           (insert ,content)
           (goto-char (point-min))
           (eerie-mode 1)
           (eerie--set-jump-stack 'back nil)
           (eerie--set-jump-stack 'forward nil)
           ,@body)
       (when (buffer-live-p buf)
         (with-current-buffer buf
           (when (bound-and-true-p eerie-mode)
             (eerie-mode -1)))
         (kill-buffer buf)))))

(defun eerie-test-run-operator (command &rest events)
  "Run operator COMMAND by feeding unread EVENTS."
  (let ((unread-command-events events))
    (call-interactively command)))

(defun eerie-test-run-search (command input)
  "Run search COMMAND while returning INPUT from the minibuffer prompt."
  (cl-letf (((symbol-function 'read-from-minibuffer)
             (lambda (&rest _) input)))
    (call-interactively command)))

(defmacro eerie-test-with-read-keys (keys &rest body)
  "Run BODY while `read-key' and `read-char' return KEYS in sequence."
  (declare (indent 1) (debug t))
  `(let ((events ,keys))
     (cl-letf (((symbol-function 'read-key)
                (lambda (&rest _)
                  (let ((event (if events
                                   (prog1 (car events)
                                     (setq events (cdr events)))
                                 ?\C-g)))
                    (eerie--multicursor-record-read-event event)
                    event)))
               ((symbol-function 'read-char)
                (lambda (&rest _)
                  (let ((event (if events
                                   (prog1 (car events)
                                     (setq events (cdr events)))
                                 ?\C-g)))
                    (eerie--multicursor-record-read-event event)
                    event))))
       ,@body)))

(defun eerie-test-run-multicursor-command (command &optional inputs)
  "Run multicursor COMMAND with INPUTS on the primary and replay it."
  (let ((prefix current-prefix-arg)
        (recorded-inputs (copy-sequence (or inputs '()))))
    (or (eerie--multicursor-replay-special-command command recorded-inputs)
        (eerie-test-with-read-keys recorded-inputs
          (call-interactively command)))
    (eerie--multicursor-replay-command command prefix recorded-inputs)))

(defun eerie-test-goto-second-line ()
  "Move point to the beginning of the second line."
  (interactive)
  (goto-char (point-min))
  (forward-line 1))

(defun eerie-test-set-window-body-height (height)
  "Resize the selected window to HEIGHT body lines."
  (let ((delta (- height (window-body-height))))
    (when (/= delta 0)
      (window-resize (selected-window) delta nil t))))

(defun eerie-test-range-of (needle &optional occurrence)
  "Return the range of NEEDLE at OCCURRENCE in the current buffer."
  (let ((count (or occurrence 1)))
    (save-excursion
      (goto-char (point-min))
      (dotimes (_ count)
        (search-forward needle nil t))
      (cons (- (point) (length needle)) (point)))))

(defun eerie-test-start-charwise-visual (range &optional backward)
  "Start charwise VISUAL on RANGE, optionally in BACKWARD direction."
  (thread-first
    (eerie--make-selection '(expand . char) (car range) (cdr range))
    (eerie--select t backward))
  (setq-local eerie--visual-type 'char)
  (eerie--switch-state 'visual))

(defun eerie-test-start-charwise-multicursor-visual (range &optional backward)
  "Start charwise multicursor VISUAL on RANGE, optionally BACKWARD."
  (thread-first
    (eerie--make-selection '(expand . char) (car range) (cdr range))
    (eerie--select t backward))
  (setq-local eerie--visual-type 'char)
  (eerie--switch-state 'multicursor-visual))

(defun eerie-test-sort-ranges (ranges)
  "Return RANGES sorted by their starting position."
  (sort (copy-sequence ranges)
        (lambda (left right)
          (< (car left) (car right)))))

(defun eerie-test-multicursor-points ()
  "Return all active multi-cursor points sorted by buffer position."
  (sort (cons (point)
              (mapcar (lambda (ov)
                        (let ((value (overlay-get ov 'eerie-multicursor-point)))
                          (if (markerp value)
                              (marker-position value)
                            value)))
                      eerie--beacon-overlays))
        #'<))

(ert-deftest eerie-default-normal-keymap-is-vim-like ()
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "h")) 'eerie-left))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "j")) 'eerie-next))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "k")) 'eerie-prev))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "l")) 'eerie-right))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "m")) 'eerie-multicursor-start))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "u")) 'eerie-undo))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "d")) 'eerie-operator-delete))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "y")) 'eerie-operator-yank))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "f")) 'eerie-jump-char))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "W")) 'eerie-next-space))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "v")) 'eerie-visual-start))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "w")) 'eerie-jump-word-occurrence))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "C-v")) 'eerie-visual-block-start))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "/")) 'eerie-search-forward))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "?")) 'eerie-search-backward))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "n")) 'eerie-search-next))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "N")) 'eerie-search-prev))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "$")) 'eerie-goto-line-end))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "%")) 'eerie-jump-matching))
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "C-o")) 'eerie-jump-back))
  (should (eq (lookup-key eerie-visual-g-prefix-keymap (kbd "g"))
              'eerie-visual-goto-buffer-start))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "G")) 'eerie-visual-goto-buffer-end))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "f")) 'eerie-visual-jump-char))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "/")) 'eerie-visual-search-forward))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "n"))
              'eerie-visual-search-next))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "$")) 'eerie-visual-goto-line-end))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "%")) 'eerie-visual-jump-matching))
  (should (eq (lookup-key eerie-visual-state-keymap (kbd "m"))
              'eerie-visual-enter-multicursor))
  (should (eq (lookup-key eerie-multicursor-state-keymap (kbd "f"))
              'eerie-jump-char))
  (should (eq (lookup-key eerie-multicursor-state-keymap (kbd "W"))
              'eerie-next-space))
  (should (eq (lookup-key eerie-multicursor-state-keymap (kbd "v"))
              'eerie-visual-start))
  (should (eq (lookup-key eerie-multicursor-visual-state-keymap (kbd "v"))
              'eerie-multicursor-visual-exit))
  (should (eq (lookup-key eerie-multicursor-visual-state-keymap (kbd "."))
              'eerie-multicursor-match-next))
  (should (eq (lookup-key eerie-multicursor-visual-state-keymap (kbd ","))
              'eerie-multicursor-unmatch-last))
  (should (eq (lookup-key eerie-multicursor-visual-state-keymap (kbd "-"))
              'eerie-multicursor-skip-match))
  (should (eq (lookup-key eerie-multicursor-visual-state-keymap (kbd "f"))
              'eerie-visual-jump-char))
  (should (eq (lookup-key eerie-multicursor-visual-state-keymap (kbd "i"))
              'eerie-visual-inner-of-thing))
  (should (eq (lookup-key eerie-multicursor-state-keymap (kbd "<escape>"))
              'eerie-multicursor-cancel)))

(ert-deftest eerie-multicursor-start-enters-session-and-displays-menu ()
  (eerie-test-with-buffer "foo bar baz\n"
    (let (described-keymaps)
      (let ((eerie-keypad-describe-keymap-function
             (lambda (keymap)
               (push keymap described-keymaps))))
        (call-interactively #'eerie-multicursor-start))
      (should (eerie-multicursor-mode-p))
      (should eerie--multicursor-active)
      (should-not (region-active-p))
      (should described-keymaps))))

(ert-deftest eerie-multicursor-start-escape-cancels-session-and-clears-menu ()
  (eerie-test-with-buffer "foo bar baz\n"
    (let ((clear-calls 0))
      (let ((eerie-keypad-describe-keymap-function (lambda (&rest _)))
            (eerie-keypad-clear-describe-keymap-function
             (lambda ()
               (setq clear-calls (1+ clear-calls)))))
        (call-interactively #'eerie-multicursor-start)
        (execute-kbd-macro (kbd "<escape>")))
      (should (eerie-normal-mode-p))
      (should-not eerie--multicursor-active)
      (should-not eerie--beacon-overlays)
      (should (= clear-calls 1)))))

(ert-deftest eerie-visual-m-deletes-charwise-selection-via-key-sequence ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1)))
      (eerie-test-start-charwise-visual range-1)
      (execute-kbd-macro (kbd "md"))
      (should (eerie-normal-mode-p))
      (should (equal (buffer-string) " xx foo yy foo\n")))))

(ert-deftest eerie-canonical-multicursor-key-sequence-remains-live ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (execute-kbd-macro (kbd "mw.vd"))
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should (equal (buffer-string) " xx  yy foo\n"))))

(ert-deftest eerie-visual-m-dot-adds-next-match ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2)))
      (eerie-test-start-charwise-visual range-1)
      (execute-kbd-macro (kbd "m."))
      (should (bound-and-true-p eerie-multicursor-visual-mode))
      (should eerie--multicursor-active)
      (should (eerie--multiedit-active-p))
      (should (equal eerie--multiedit-primary range-2))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2)))
      (should (= (length eerie--multiedit-overlays) 1))
      (should (equal (cons (region-beginning) (region-end)) range-2)))))

(ert-deftest eerie-multicursor-dot-adds-next-match-from-new-entry-flow ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2)))
      (call-interactively #'eerie-multicursor-start)
      (eerie-test-start-charwise-multicursor-visual range-1)
      (call-interactively #'eerie-multicursor-match-next)
      (should (bound-and-true-p eerie-multicursor-visual-mode))
      (should eerie--multicursor-active)
      (should (equal eerie--multiedit-primary range-2))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2))))))

(ert-deftest eerie-multicursor-w-dot-keeps-both-word-matches-highlighted ()
  (eerie-test-with-buffer "defun foo ()\ndefun bar ()\n"
    (goto-char (point-min))
    (search-forward "def")
    (forward-char 1)
    (call-interactively #'eerie-multicursor-start)
    (execute-kbd-macro (kbd "w."))
    (should (bound-and-true-p eerie-multicursor-visual-mode))
    (should eerie--multicursor-active)
    (should (eerie--multiedit-active-p))
    (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                   (list (eerie-test-range-of "defun" 1)
                         (eerie-test-range-of "defun" 2))))
    (should (= (length eerie--multiedit-overlays) 1))
    (should (region-active-p))
    (should (equal (cons (region-beginning) (region-end))
                   (eerie-test-range-of "defun" 2)))))

(ert-deftest eerie-multicursor-w-dot-d-deletes-all-word-matches ()
  (eerie-test-with-buffer "defun foo ()\ndefun bar ()\n"
    (goto-char (point-min))
    (search-forward "def")
    (forward-char 1)
    (call-interactively #'eerie-multicursor-start)
    (execute-kbd-macro (kbd "w.d"))
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not (eerie--multiedit-active-p))
    (should-not (region-active-p))
    (should (equal (buffer-string) " foo ()\n bar ()\n"))))

(ert-deftest eerie-no-legacy-visual-search-multicursor-dispatcher ()
  (should-not (fboundp 'eerie-visual-search-next-or-multicursor)))

(ert-deftest eerie-no-legacy-open-above-below-commands ()
  (dolist (command '(eerie-open-above
                     eerie-open-above-visual
                     eerie-open-below
                     eerie-open-below-visual))
    (should-not (fboundp command))
    (should-not (assq command eerie-command-to-short-name-list)))
  (should-not (lookup-key eerie-beacon-state-keymap [remap eerie-open-above]))
  (should-not (lookup-key eerie-beacon-state-keymap [remap eerie-open-below])))

(ert-deftest eerie-multicursor-comma-removes-newest-match-via-key-sequence ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (execute-kbd-macro (kbd "mw.,d"))
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not (eerie--multiedit-active-p))
    (should-not (region-active-p))
    (should (equal (buffer-string) " xx foo yy foo\n"))))

(ert-deftest eerie-multicursor-dash-skips-next-match-via-key-sequence ()
  (eerie-test-with-buffer "foo aa foo bb foo cc foo\n"
    (execute-kbd-macro (kbd "mw.-.d"))
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not (eerie--multiedit-active-p))
    (should-not (region-active-p))
    (should (equal (buffer-string) " aa  bb foo cc \n"))))

(ert-deftest eerie-multicursor-new-flow-normal-delete-consumes-marked-targets ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (call-interactively #'eerie-multicursor-start)
    (eerie-test-start-charwise-multicursor-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multicursor-match-next)
    (call-interactively #'eerie-multicursor-visual-exit)
    (call-interactively #'eerie-operator-delete)
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not (eerie--multiedit-active-p))
    (should (equal (buffer-string) " xx  yy foo\n"))))

(ert-deftest eerie-multicursor-new-flow-normal-change-consumes-marked-targets ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (call-interactively #'eerie-multicursor-start)
    (eerie-test-start-charwise-multicursor-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multicursor-match-next)
    (call-interactively #'eerie-multicursor-visual-exit)
    (call-interactively #'eerie-operator-change)
    (insert "Z")
    (call-interactively #'eerie-insert-exit)
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not (eerie--multiedit-active-p))
    (should (equal (buffer-string) "Z xx Z yy foo\n"))))

(ert-deftest eerie-multicursor-new-flow-vi-paren-deletes-all-inner-objects ()
  (eerie-test-with-buffer "(foo) xx (foo)\n"
    (call-interactively #'eerie-multicursor-start)
    (eerie-test-start-charwise-multicursor-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multicursor-match-next)
    (call-interactively #'eerie-multicursor-visual-exit)
    (execute-kbd-macro (kbd "vi(d"))
    (should (eerie-multicursor-mode-p))
    (should eerie--multicursor-active)
    (should (equal (buffer-string) "() xx ()\n"))))

(ert-deftest eerie-left-and-right-stay-on-current-line ()
  (eerie-test-with-buffer "ab\ncd\n"
    (forward-line 1)
    (let ((origin (point)))
      (call-interactively #'eerie-left)
      (should (= (point) origin)))
    (goto-char (point-min))
    (goto-char (line-end-position))
    (let ((origin (point)))
      (call-interactively #'eerie-right)
      (should (= (point) origin)))))

(ert-deftest eerie-goto-line-end-uses-dollar ()
  (eerie-test-with-buffer "abc\ndef\n"
    (forward-char 1)
    (call-interactively #'eerie-goto-line-end)
    (should (= (point) (save-excursion
                         (goto-char (point-min))
                         (line-end-position))))))

(ert-deftest eerie-next-space-advances-on-current-line ()
  (eerie-test-with-buffer "foo bar baz\n"
    (call-interactively #'eerie-next-space)
    (should (= (point)
               (save-excursion
                 (goto-char (point-min))
                 (search-forward " ")
                 (1- (point)))))
    (let ((last-command 'eerie-next-space))
      (call-interactively #'eerie-next-space)
      (should (= (point)
                 (save-excursion
                   (goto-char (point-min))
                   (search-forward "bar ")
                   (1- (point))))))))

(ert-deftest eerie-next-space-falls-back-to-line-end ()
  (eerie-test-with-buffer "foo bar\n"
    (call-interactively #'eerie-next-space)
    (let ((last-command 'eerie-next-space))
      (call-interactively #'eerie-next-space)
      (should (= (point)
                 (save-excursion
                   (goto-char (point-min))
                   (line-end-position)))))))

(ert-deftest eerie-next-space-skips-current-word-boundary-space ()
  (eerie-test-with-buffer "targetword beta gamma\n"
    (search-forward "targetword")
    (should (eq (char-after) ?\s))
    (call-interactively #'eerie-next-space)
    (should (= (point)
               (save-excursion
                 (goto-char (point-min))
                 (search-forward "beta ")
                 (1- (point)))))))

(ert-deftest eerie-visual-start-enters-visual-state ()
  (eerie-test-with-buffer "alpha"
    (call-interactively #'eerie-visual-start)
    (should (eerie-visual-mode-p))
    (should (eq eerie--visual-type 'char))
    (should (region-active-p))))

(ert-deftest eerie-multiedit-match-next-adds-next-exact-match ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2)))
      (eerie-test-start-charwise-visual range-1)
      (call-interactively #'eerie-multiedit-match-next)
      (should (eerie-visual-mode-p))
      (should (equal eerie--multiedit-seed "foo"))
      (should (equal eerie--multiedit-primary range-2))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2)))
      (should (= (length eerie--multiedit-overlays) 1))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "foo")))))

(ert-deftest eerie-multiedit-match-next-repeats-forward ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2))
          (range-3 (eerie-test-range-of "foo" 3)))
      (eerie-test-start-charwise-visual range-1)
      (call-interactively #'eerie-multiedit-match-next)
      (call-interactively #'eerie-multiedit-match-next)
      (should (equal eerie--multiedit-primary range-3))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2 range-3)))
      (should (= (length eerie--multiedit-overlays) 2)))))

(ert-deftest eerie-multiedit-reverse-direction-before-first-match ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2)))
      (eerie-test-start-charwise-visual range-2)
      (call-interactively #'eerie-multiedit-reverse-direction)
      (call-interactively #'eerie-multiedit-match-next)
      (should (eq eerie--multiedit-direction 'backward))
      (should (equal eerie--multiedit-primary range-1))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2))))))

(ert-deftest eerie-multiedit-skip-match-advances-search-head ()
  (eerie-test-with-buffer "foo aa foo bb foo cc foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2))
          (range-4 (eerie-test-range-of "foo" 4)))
      (eerie-test-start-charwise-visual range-1)
      (call-interactively #'eerie-multiedit-match-next)
      (call-interactively #'eerie-multiedit-skip-match)
      (call-interactively #'eerie-multiedit-match-next)
      (should (equal eerie--multiedit-primary range-4))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2 range-4))))))

(ert-deftest eerie-multiedit-clear-on-visual-exit ()
  (eerie-test-with-buffer "foo xx foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-visual-exit)
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))
    (should-not eerie--multiedit-seed)
    (should-not eerie--multiedit-overlays)))

(ert-deftest eerie-multiedit-match-next-works-from-w-selection ()
  (eerie-test-with-buffer "foo x foo y foo\n"
    (eerie-test-with-read-keys '(?\C-g)
      (eerie-jump-word-occurrence nil))
    (call-interactively #'eerie-multiedit-match-next)
    (should (eerie-visual-mode-p))
    (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                   (list (eerie-test-range-of "foo" 1)
                         (eerie-test-range-of "foo" 2))))))

(ert-deftest eerie-multiedit-unmatch-last-removes-newest-target ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (let ((range-1 (eerie-test-range-of "foo" 1))
          (range-2 (eerie-test-range-of "foo" 2)))
      (eerie-test-start-charwise-visual range-1)
      (call-interactively #'eerie-multiedit-match-next)
      (call-interactively #'eerie-multiedit-match-next)
      (call-interactively #'eerie-multiedit-unmatch-last)
      (should (equal eerie--multiedit-primary range-2))
      (should (equal (eerie-test-sort-ranges eerie--multiedit-targets)
                     (list range-1 range-2)))
      (should (= (length eerie--multiedit-overlays) 1)))))

(ert-deftest eerie-multiedit-visual-delete-removes-all-targets ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-visual-delete)
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))
    (should (equal (buffer-string) " xx  yy foo\n"))))

(ert-deftest eerie-multiedit-visual-change-replays-insert-on-all-targets ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-visual-change)
    (insert "Z")
    (call-interactively #'eerie-insert-exit)
    (should (eerie-normal-mode-p))
    (should-not eerie--multiedit-replay-command)
    (should (equal (buffer-string) "Z xx Z yy foo\n"))))

(ert-deftest eerie-multiedit-visual-insert-replays-on-all-targets ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-visual-inner-of-thing)
    (insert "Z")
    (call-interactively #'eerie-insert-exit)
    (should (eerie-normal-mode-p))
    (should-not eerie--multiedit-replay-command)
    (should (equal (buffer-string) "Zfoo xx Zfoo yy foo\n"))))

(ert-deftest eerie-multiedit-visual-append-replays-on-all-targets ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-visual-bounds-of-thing)
    (insert "Z")
    (call-interactively #'eerie-insert-exit)
    (should (eerie-normal-mode-p))
    (should-not eerie--multiedit-replay-command)
    (should (equal (buffer-string) "fooZ xx fooZ yy foo\n"))))

(ert-deftest eerie-multicursor-spawn-from-multiedit-via-visual-n ()
  (eerie-test-with-buffer "foo xx foo yy foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (should (eerie-multicursor-mode-p))
    (should eerie--multicursor-active)
    (should-not (region-active-p))
    (should (eerie--multiedit-active-p))
    (should (= (length eerie--multiedit-overlays) 2))
    (should (= (length eerie--beacon-overlays) 1))
    (execute-kbd-macro (kbd "<escape>"))
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not eerie--beacon-overlays)))

(ert-deftest eerie-multicursor-replays-normal-commands-to-secondary-cursors ()
  (eerie-test-with-buffer "foo xx foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (eerie-test-run-multicursor-command #'eerie-left)
    (eerie-test-run-multicursor-command #'eerie-delete)
    (should (eerie-multicursor-mode-p))
    (should (equal (buffer-string) "fo xx fo\n"))))

(ert-deftest eerie-multicursor-charwise-visual-start-keeps-session-active ()
  (eerie-test-with-buffer "foo xx foo\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (execute-kbd-macro (kbd "v"))
    (should (bound-and-true-p eerie-multicursor-visual-mode))
    (should eerie--multicursor-active)
    (should (region-active-p))
    (dolist (ov eerie--beacon-overlays)
      (should (eq (plist-get (overlay-get ov 'eerie-multicursor-snapshot) :state)
                  'multicursor-visual)))))

(ert-deftest eerie-multicursor-vi-paren-deletes-all-inner-objects ()
  (eerie-test-with-buffer "(foo) xx (foo)\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (execute-kbd-macro (kbd "vi(d"))
    (should (eerie-multicursor-mode-p))
    (should eerie--multicursor-active)
    (should (equal (buffer-string) "() xx ()\n"))))

(ert-deftest eerie-multicursor-jump-char-uses-numbered-visible-hints ()
  (eerie-test-with-buffer "foo a x a\nfoo a x a\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (eerie-test-with-read-keys '(?a ?1)
      (execute-kbd-macro (kbd "f")))
    (should (eerie-multicursor-mode-p))
    (should (equal (eerie-test-multicursor-points)
                   (list (save-excursion
                           (goto-char (point-min))
                           (search-forward "a")
                           (1- (point)))
                         (save-excursion
                           (goto-char (point-min))
                           (forward-line 1)
                           (search-forward "a")
                           (1- (point))))))))

(ert-deftest eerie-multicursor-replays-insert-session-to-secondary-cursors ()
  (eerie-test-with-buffer "foo one\nfoo two\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (call-interactively #'eerie-append-end-of-line)
    (eerie--multicursor-prepare-insert-replay 'append-eol)
    (insert "!")
    (call-interactively #'eerie-insert-exit)
    (should (eerie-normal-mode-p))
    (should-not eerie--multicursor-active)
    (should-not eerie--beacon-overlays)
    (should (equal (buffer-string) "foo one!\nfoo two!\n"))))

(ert-deftest eerie-multicursor-jump-char-moves-all-cursors-on-their-lines ()
  (eerie-test-with-buffer "foo a x\nfoo b x\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (eerie-multicursor-jump-char ?x)
    (should (eerie-multicursor-mode-p))
    (should (equal (eerie-test-multicursor-points)
                   (list (save-excursion
                           (goto-char (point-min))
                           (search-forward "x")
                           (1- (point)))
                         (save-excursion
                           (goto-char (point-min))
                           (forward-line 1)
                           (search-forward "x")
                           (1- (point))))))))

(ert-deftest eerie-multicursor-next-space-advances-all-cursors ()
  (eerie-test-with-buffer "foo bar baz\nfoo zip zap\n"
    (eerie-test-start-charwise-visual (eerie-test-range-of "foo" 1))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (call-interactively #'eerie-multicursor-next-space)
    (should (equal (eerie-test-multicursor-points)
                   (list (save-excursion
                           (goto-char (point-min))
                           (search-forward "bar ")
                           (1- (point)))
                         (save-excursion
                           (goto-char (point-min))
                           (forward-line 1)
                           (search-forward "zip ")
                           (1- (point))))))
    (call-interactively #'eerie-multicursor-next-space)
    (should (equal (eerie-test-multicursor-points)
                   (list (save-excursion
                           (goto-char (point-min))
                           (line-end-position))
                         (save-excursion
                           (goto-char (point-min))
                           (forward-line 1)
                           (line-end-position)))))
    (call-interactively #'eerie-multicursor-next-space)
    (should (equal (eerie-test-multicursor-points)
                   (list (save-excursion
                           (goto-char (point-min))
                           (line-end-position))
                         (save-excursion
                           (goto-char (point-min))
                           (forward-line 1)
                           (line-end-position)))))))

(ert-deftest eerie-multicursor-next-space-advances-after-w-seeded-spawn ()
  (eerie-test-with-buffer "targetword beta gamma\ntargetword beta gamma\n"
    (let ((bounds (bounds-of-thing-at-point eerie-word-thing)))
      (eerie--jump-word-action bounds))
    (call-interactively #'eerie-multiedit-match-next)
    (call-interactively #'eerie-multicursor-spawn)
    (execute-kbd-macro (kbd "W"))
    (should (equal (eerie-test-multicursor-points)
                   (list (save-excursion
                           (goto-char (point-min))
                           (search-forward "beta ")
                           (1- (point)))
                         (save-excursion
                           (goto-char (point-min))
                           (forward-line 1)
                           (search-forward "beta ")
                           (1- (point))))))))

(ert-deftest eerie-visual-line-start-enters-linewise-visual-state ()
  (eerie-test-with-buffer "one\ntwo\n"
    (eerie-test-with-read-keys '(?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (eerie-visual-mode-p))
    (should (eq eerie--visual-type 'line))
    (should (equal '(expand . line) (eerie--selection-type)))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "one"))))

(ert-deftest eerie-visual-line-start-selects-current-line-at-buffer-edges ()
  (eerie-test-with-buffer "one\ntwo\nthree\n"
    (goto-char (point-min))
    (eerie-test-with-read-keys '(?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "one")))
  (eerie-test-with-buffer "one\ntwo\nthree\n"
    (goto-char (point-max))
    (forward-line -1)
    (end-of-line)
    (eerie-test-with-read-keys '(?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "three"))))

(ert-deftest eerie-visual-line-movement-keeps-anchor-line-selected ()
  (eerie-test-with-buffer "one\ntwo\nthree\n"
    (goto-char (point-min))
    (eerie-test-with-read-keys '(?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (call-interactively #'eerie-visual-next)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "one\ntwo"))
    (call-interactively #'eerie-visual-prev)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "one"))))

(ert-deftest eerie-visual-line-j-and-k-follow-buffer-direction ()
  (eerie-test-with-buffer "one\ntwo\nthree\nfour\n"
    (forward-line 2)
    (eerie-test-with-read-keys '(?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (call-interactively #'eerie-visual-prev)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "two\nthree"))
    (call-interactively #'eerie-visual-next)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "three"))))

(ert-deftest eerie-visual-line-start-jumps-to-visible-lines ()
  (eerie-test-with-buffer "one\ntwo\nthree\nfour\n"
    (eerie-test-with-read-keys '(?2 ?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (eerie-visual-mode-p))
    (should (eq eerie--visual-type 'line))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "one\ntwo\nthree"))))

(ert-deftest eerie-visual-line-start-reverse-hints-update-selection ()
  (eerie-test-with-buffer "one\ntwo\nthree\nfour\nfive\n"
    (forward-line 2)
    (eerie-test-with-read-keys '(?2 ?\; ?1 ?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (eerie-visual-mode-p))
    (should (eq eerie--visual-type 'line))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "three\nfour"))))

(ert-deftest eerie-visual-line-start-advances-by-logical-lines-when-lines-wrap ()
  (eerie-test-with-buffer
      (concat
       "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n"
       "BBBB\nCCCC\nDDDD\nEEEE\nFFFF\n")
    (delete-other-windows)
    (let ((right (split-window-right)))
      (window-resize right (- 20 (window-total-width right)) t)
      (select-window right))
    (setq truncate-lines nil)
    (visual-line-mode 1)
    (goto-char (point-min))
    (eerie-test-with-read-keys '(?1 ?1 ?1 ?1 ?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (eerie-visual-mode-p))
    (should (eq eerie--visual-type 'line))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   (concat
                    "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA\n"
                    "BBBB\nCCCC\nDDDD\nEEEE")))))

(ert-deftest eerie-visual-line-start-escape-exits-visual ()
  (eerie-test-with-buffer "one\ntwo\n"
    (eerie-test-with-read-keys '(?\e)
      (call-interactively #'eerie-visual-line-start))
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))))

(ert-deftest eerie-visual-line-start-fills-forward-nine-hints-when-buffer-has-more-lines ()
  (eerie-test-with-buffer
      (concat
       (mapconcat (lambda (n) (format "%02d" n)) (number-sequence 1 20) "\n")
       "\n")
    (delete-other-windows)
    (split-window-below)
    (eerie-test-set-window-body-height 12)
    (goto-char (point-min))
    (forward-line 5)
    (set-window-start (selected-window) (point-min))
    (eerie-test-with-read-keys '(?9 ?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   (mapconcat
                    (lambda (n) (format "%02d" n))
                    (number-sequence 6 15)
                    "\n")))))

(ert-deftest eerie-visual-line-start-fills-reverse-nine-hints-when-buffer-has-more-lines ()
  (eerie-test-with-buffer
      (concat
       (mapconcat (lambda (n) (format "%02d" n)) (number-sequence 1 20) "\n")
       "\n")
    (delete-other-windows)
    (split-window-below)
    (eerie-test-set-window-body-height 12)
    (goto-char (point-min))
    (forward-line 13)
    (forward-char 1)
    (goto-char (line-beginning-position))
    (set-window-start
     (selected-window)
     (save-excursion
       (goto-char (point-min))
       (forward-line 8)
       (point)))
    (eerie-test-with-read-keys '(?\; ?9 ?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   (mapconcat
                    (lambda (n) (format "%02d" n))
                    (number-sequence 5 14)
                    "\n")))))

(ert-deftest eerie-visual-goto-buffer-start-and-end-extend-char-selection ()
  (eerie-test-with-buffer "one\ntwo\nthree\n"
    (forward-line 1)
    (call-interactively #'eerie-visual-start)
    (let ((anchor (mark t)))
      (call-interactively #'eerie-visual-goto-buffer-start)
      (should (= (point) (point-min)))
      (should (= (mark t) anchor))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "one\n"))
      (call-interactively #'eerie-visual-goto-buffer-end)
      (should (= (point) (point-max)))
      (should (= (mark t) anchor))
      (should (string-prefix-p
               "two\nthree"
               (buffer-substring-no-properties (region-beginning) (region-end)))))))

(ert-deftest eerie-visual-goto-buffer-end-extends-line-selection ()
  (eerie-test-with-buffer "one\ntwo\nthree\n"
    (eerie-test-with-read-keys '(?\C-g)
      (call-interactively #'eerie-visual-line-start))
    (call-interactively #'eerie-visual-goto-buffer-end)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "one\ntwo\nthree"))))

(ert-deftest eerie-visual-goto-buffer-end-preserves-block-column ()
  (eerie-test-with-buffer "012345\nabcdef\nuvwxyz\n"
    (forward-char 3)
    (call-interactively #'eerie-visual-block-start)
    (call-interactively #'eerie-visual-goto-buffer-end)
    (should (= (current-column) 3))
    (should (= (save-excursion
                 (goto-char (mark t))
                 (current-column))
               4))))

(ert-deftest eerie-visual-search-next-extends-selection ()
  (eerie-test-with-buffer "alpha target beta target gamma\n"
    (call-interactively #'eerie-visual-start)
    (eerie-test-run-search #'eerie-visual-search-forward "target")
    (should (= (point)
               (save-excursion
                 (goto-char (point-min))
                 (re-search-forward "target" nil t 1)
                 (match-beginning 0))))
    (let ((first-end (region-end)))
      (call-interactively #'eerie-visual-search-next)
      (should (> (region-end) first-end)))))

(ert-deftest eerie-operator-delete-line-implements-dd ()
  (eerie-test-with-buffer "one\ntwo\n"
    (let ((unread-command-events (list ?d)))
      (call-interactively #'eerie-operator-delete))
    (should (equal (buffer-string) "two\n"))
    (should-not eerie--expand-overlays)
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))))

(ert-deftest eerie-operator-yank-line-implements-yy ()
  (eerie-test-with-buffer "one\ntwo\n"
    (let ((origin (point)))
      (let ((unread-command-events (list ?y)))
        (call-interactively #'eerie-operator-yank))
      (should (= (point) origin)))
    (goto-char (point-min))
    (let ((unread-command-events (list ?y)))
      (call-interactively #'eerie-operator-yank))
    (should (equal (current-kill 0) "one\n"))
    (should-not eerie--expand-overlays)
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))))

(ert-deftest eerie-jump-matching-visits-delimiter-pairs ()
  (eerie-test-with-buffer "(abc) [de] {fg} \"hi\" 'jk'"
    (goto-char 1)
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 5))
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 1))
    (goto-char 7)
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 10))
    (goto-char 12)
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 15))
    (goto-char 17)
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 20))
    (goto-char 22)
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 25))))

(ert-deftest eerie-jump-char-uses-numbered-visible-hints ()
  (eerie-test-with-buffer "A x A y A\n"
    (let ((target (save-excursion
                    (goto-char (point-min))
                    (search-forward "A x A y ")
                    (point))))
      (eerie-test-with-read-keys '(?2 ?\C-g)
        (eerie-jump-char nil ?A))
      (should (= (point) target))
      (should-not eerie--expand-overlays)
      (should (= (length (eerie--get-jump-stack 'back)) 1)))))

(ert-deftest eerie-jump-char-supports-semicolon-direction-reversal ()
  (eerie-test-with-buffer "A x A y A\n"
    (search-forward "A x ")
    (let ((target (point-min)))
      (eerie-test-with-read-keys '(?\; ?1 ?\C-g)
        (eerie-jump-char nil ?A))
      (should (= (point) target))
      (should-not eerie--expand-overlays)
      (should (= (length (eerie--get-jump-stack 'back)) 1)))))

(ert-deftest eerie-jump-char-participates-in-jump-history ()
  (eerie-test-with-buffer "A x A y A\n"
    (let ((origin (point))
          (target (save-excursion
                    (goto-char (point-min))
                    (search-forward "A x A y ")
                    (point))))
      (eerie-test-with-read-keys '(?A ?2 ?\C-g)
        (execute-kbd-macro (kbd "f")))
      (should (= (point) target))
      (call-interactively #'eerie-jump-back)
      (should (= (point) origin))
      (call-interactively #'eerie-jump-forward)
      (should (= (point) target)))))

(ert-deftest eerie-jump-word-occurrence-enters-visual-selection ()
  (eerie-test-with-buffer "foo x foo y foo\n"
    (let ((target-beg (save-excursion
                    (goto-char (point-min))
                    (search-forward "foo x foo y ")
                    (point)))
          (target-end (save-excursion
                        (goto-char (point-min))
                        (search-forward "foo x foo y foo")
                        (point))))
      (eerie-test-with-read-keys '(?2 ?\C-g)
        (eerie-jump-word-occurrence nil))
      (should (= (point) target-end))
      (should (region-active-p))
      (should (eerie-visual-mode-p))
      (should (eq eerie--visual-type 'char))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "foo"))
      (should (= (region-beginning) target-beg))
      (should (= (region-end) target-end))
      (should (equal (eerie--selection-type) '(expand . char)))
      (should-not eerie--expand-overlays)
      (should (= (length (eerie--get-jump-stack 'back)) 1)))))

(ert-deftest eerie-jump-word-occurrence-visual-movement-works ()
  (eerie-test-with-buffer "foo x foo\ntail line\n"
    (eerie-test-with-read-keys '(?1 ?\C-g)
      (eerie-jump-word-occurrence nil))
    (should (eerie-visual-mode-p))
    (call-interactively #'eerie-visual-next)
    (should (eerie-visual-mode-p))
    (should (= (line-number-at-pos) 2))
    (should (region-active-p))))

(ert-deftest eerie-jump-word-occurrence-visual-delete-works ()
  (eerie-test-with-buffer "foo x foo bar\n"
    (eerie-test-with-read-keys '(?1 ?\C-g)
      (eerie-jump-word-occurrence nil))
    (call-interactively #'eerie-visual-delete)
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))
    (should (equal (buffer-string) "foo x  bar\n"))))

(ert-deftest eerie-jump-word-occurrence-reverse-skips-current-word ()
  (eerie-test-with-buffer "foo x foo y foo\n"
    (search-forward "foo x ")
    (let ((target-beg (point-min))
          (target-end (save-excursion
                        (goto-char (point-min))
                        (search-forward "foo")
                        (point))))
      (eerie-test-with-read-keys '(?\; ?1 ?\C-g)
        (eerie-jump-word-occurrence nil))
      (should (= (point) target-end))
      (should (eerie-visual-mode-p))
      (should (= (region-beginning) target-beg))
      (should (= (region-end) target-end))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "foo")))))

(ert-deftest eerie-visual-jump-char-extends-selection ()
  (eerie-test-with-buffer "abc def ghi\n"
    (call-interactively #'eerie-visual-start)
    (eerie-test-with-read-keys '(?1 ?\C-g)
      (eerie-visual-jump-char nil ?d))
    (should (eerie-visual-mode-p))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "abc d"))
    (should (= (point)
               (save-excursion
                 (goto-char (point-min))
                 (search-forward "abc d")
                 (point))))))

(ert-deftest eerie-visual-jump-char-reverse-skips-current-cursor-char ()
  (eerie-test-with-buffer "abc ddd eee\n"
    (call-interactively #'eerie-visual-start)
    (eerie-test-with-read-keys '(?2 ?\C-g)
      (eerie-visual-jump-char nil ?d))
    (let ((current-end (point)))
      (eerie-test-with-read-keys '(?\; ?1 ?\C-g)
        (eerie-visual-jump-char nil ?d))
      (should (< (point) current-end))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "abc d")))))

(ert-deftest eerie-visual-jump-char-reverse-updates-within-same-loop ()
  (eerie-test-with-buffer "abc ddd eee\n"
    (call-interactively #'eerie-visual-start)
    (eerie-test-with-read-keys '(?2 ?\; ?1 ?\C-g)
      (eerie-visual-jump-char nil ?d))
    (should (eerie-visual-mode-p))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "abc d"))
    (should (= (point)
               (save-excursion
                 (goto-char (point-min))
                 (search-forward "abc d")
                 (point))))))

(ert-deftest eerie-visual-jump-char-extends-w-selection ()
  (eerie-test-with-buffer "foo x foo y z\n"
    (eerie-test-with-read-keys '(?1 ?\C-g)
      (eerie-jump-word-occurrence nil))
    (let ((initial-end (region-end)))
      (eerie-test-with-read-keys '(?1 ?\C-g)
        (eerie-visual-jump-char nil ?y))
      (should (eerie-visual-mode-p))
      (should (> (region-end) initial-end))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "foo y")))))

(ert-deftest eerie-visual-jump-char-reverse-skips-current-char-after-w ()
  (eerie-test-with-buffer "foo ayy z\n"
    (eerie-test-with-read-keys '(?\C-g)
      (eerie-jump-word-occurrence nil))
    (eerie-test-with-read-keys '(?2 ?\C-g)
      (eerie-visual-jump-char nil ?y))
    (let ((current-end (point)))
      (eerie-test-with-read-keys '(?\; ?1 ?\C-g)
        (eerie-visual-jump-char nil ?y))
      (should (< (point) current-end))
      (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                     "foo ay")))))

(ert-deftest eerie-visual-jump-char-reverse-updates-within-same-loop-after-w ()
  (eerie-test-with-buffer "foo ayy z\n"
    (eerie-test-with-read-keys '(?\C-g)
      (eerie-jump-word-occurrence nil))
    (eerie-test-with-read-keys '(?2 ?\; ?1 ?\C-g)
      (eerie-visual-jump-char nil ?y))
    (should (eerie-visual-mode-p))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "foo ay"))
    (should (= (point)
               (save-excursion
                 (goto-char (point-min))
                 (search-forward "foo ay")
                 (point))))))

(ert-deftest eerie-jump-word-occurrence-escape-exits-selection ()
  (eerie-test-with-buffer "foo x foo\n"
    (eerie-test-with-read-keys '(?\e)
      (eerie-jump-word-occurrence nil))
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))))

(ert-deftest eerie-jump-matching-handles-nested-openers ()
  (eerie-test-with-buffer "(())"
    (goto-char 2)
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 3))
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 2))))

(ert-deftest eerie-jump-matching-handles-eol-and-eof-delimiters ()
  (eerie-test-with-buffer "(x)\n"
    (goto-char (line-end-position))
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 1)))
  (eerie-test-with-buffer "(x)"
    (goto-char (point-max))
    (call-interactively #'eerie-jump-matching)
    (should (= (point) 1))))

(ert-deftest eerie-visual-jump-matching-extends-selection ()
  (eerie-test-with-buffer "(abc)"
    (goto-char (point-min))
    (call-interactively #'eerie-visual-start)
    (call-interactively #'eerie-visual-jump-matching)
    (should (= (point) 5))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "(abc"))))

(ert-deftest eerie-operator-change-inner-round-implements-ci-paren ()
  (eerie-test-with-buffer "(hello)"
    (goto-char 4)
    (let ((unread-command-events (list ?i (string-to-char "("))))
      (call-interactively #'eerie-operator-change))
    (should (equal (buffer-string) "()"))
    (should (eerie-insert-mode-p))
    (should (= (point) 2))))

(ert-deftest eerie-operator-yank-around-double-quote-implements-ya-quote ()
  (eerie-test-with-buffer "\"hello\""
    (goto-char 4)
    (let ((unread-command-events (list ?a (string-to-char "\""))))
      (call-interactively #'eerie-operator-yank))
    (should (equal (current-kill 0) "\"hello\""))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-operator-word-motions-support-dw-cw-yw ()
  (eerie-test-with-buffer "one two"
    (eerie-test-run-operator #'eerie-operator-delete ?w)
    (should (equal (buffer-string) "two"))
    (should (eerie-normal-mode-p)))
  (eerie-test-with-buffer "one two"
    (eerie-test-run-operator #'eerie-operator-change ?w)
    (should (equal (buffer-string) " two"))
    (should (eerie-insert-mode-p))
    (should (= (point) 1)))
  (eerie-test-with-buffer "one two"
    (eerie-test-run-operator #'eerie-operator-yank ?w)
    (should (equal (current-kill 0) "one "))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-operator-symbol-motions-support-b-and-w-variants ()
  (eerie-test-with-buffer "foo bar"
    (goto-char 5)
    (eerie-test-run-operator #'eerie-operator-delete ?B)
    (should (equal (buffer-string) "bar")))
  (eerie-test-with-buffer "foo bar"
    (eerie-test-run-operator #'eerie-operator-change ?W)
    (should (equal (buffer-string) " bar"))
    (should (eerie-insert-mode-p)))
  (eerie-test-with-buffer "foo bar"
    (eerie-test-run-operator #'eerie-operator-yank ?W)
    (should (equal (current-kill 0) "foo "))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-operator-line-start-motions-support-d0-c0-y0 ()
  (eerie-test-with-buffer "abc def"
    (search-forward "d")
    (backward-char)
    (eerie-test-run-operator #'eerie-operator-delete ?0)
    (should (equal (buffer-string) "def")))
  (eerie-test-with-buffer "abc def"
    (search-forward "d")
    (backward-char)
    (eerie-test-run-operator #'eerie-operator-change ?0)
    (should (equal (buffer-string) "def"))
    (should (eerie-insert-mode-p))
    (should (= (point) 1)))
  (eerie-test-with-buffer "abc def"
    (search-forward "d")
    (backward-char)
    (eerie-test-run-operator #'eerie-operator-yank ?0)
    (should (equal (current-kill 0) "abc "))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-operator-line-end-motions-support-d-dollar-c-dollar-y-dollar ()
  (eerie-test-with-buffer "abc def"
    (search-forward "d")
    (backward-char)
    (eerie-test-run-operator #'eerie-operator-delete ?$)
    (should (equal (buffer-string) "abc ")))
  (eerie-test-with-buffer "abc def"
    (search-forward "d")
    (backward-char)
    (eerie-test-run-operator #'eerie-operator-change ?$)
    (should (equal (buffer-string) "abc "))
    (should (eerie-insert-mode-p))
    (should (= (point) 5)))
  (eerie-test-with-buffer "abc def"
    (search-forward "d")
    (backward-char)
    (eerie-test-run-operator #'eerie-operator-yank ?$)
    (should (equal (current-kill 0) "def"))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-operator-find-motions-support-df-cf-yf ()
  (eerie-test-with-buffer "abc def ghi"
    (eerie-test-run-operator #'eerie-operator-delete ?f ?d)
    (should (equal (buffer-string) "ef ghi")))
  (eerie-test-with-buffer "abc def ghi"
    (eerie-test-run-operator #'eerie-operator-change ?f ?d)
    (should (equal (buffer-string) "ef ghi"))
    (should (eerie-insert-mode-p))
    (should (= (point) 1)))
  (eerie-test-with-buffer "abc def ghi"
    (eerie-test-run-operator #'eerie-operator-yank ?f ?d)
    (should (equal (current-kill 0) "abc d"))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-operator-till-motions-support-dt-ct-yt ()
  (eerie-test-with-buffer "abc def ghi"
    (eerie-test-run-operator #'eerie-operator-delete ?t ?d)
    (should (equal (buffer-string) "def ghi")))
  (eerie-test-with-buffer "abc def ghi"
    (eerie-test-run-operator #'eerie-operator-change ?t ?d)
    (should (equal (buffer-string) "def ghi"))
    (should (eerie-insert-mode-p))
    (should (= (point) 1)))
  (eerie-test-with-buffer "abc def ghi"
    (eerie-test-run-operator #'eerie-operator-yank ?t ?d)
    (should (equal (current-kill 0) "abc "))
    (should (eerie-normal-mode-p))))

(ert-deftest eerie-visual-yank-returns-to-normal ()
  (eerie-test-with-buffer "abc"
    (call-interactively #'eerie-visual-start)
    (call-interactively #'eerie-visual-right)
    (call-interactively #'eerie-visual-yank)
    (should (equal (current-kill 0) "a"))
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))))

(ert-deftest eerie-visual-left-and-right-stay-on-current-line ()
  (eerie-test-with-buffer "ab\ncd\n"
    (forward-line 1)
    (call-interactively #'eerie-visual-start)
    (let ((origin (point)))
      (call-interactively #'eerie-visual-left)
      (should (= (point) origin)))
    (call-interactively #'eerie-visual-exit)
    (goto-char (point-min))
    (goto-char (line-end-position))
    (call-interactively #'eerie-visual-start)
    (let ((origin (point)))
      (call-interactively #'eerie-visual-right)
      (should (= (point) origin)))))

(ert-deftest eerie-visual-goto-line-end-extends-selection ()
  (eerie-test-with-buffer "abc\ndef\n"
    (call-interactively #'eerie-visual-start)
    (call-interactively #'eerie-visual-goto-line-end)
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "abc"))))

(ert-deftest eerie-visual-bounds-of-thing-selects-square-object ()
  (eerie-test-with-buffer "[abc]"
    (goto-char 3)
    (call-interactively #'eerie-visual-start)
    (let ((unread-command-events (list (string-to-char "["))))
      (call-interactively #'eerie-visual-bounds-of-thing))
    (should (equal (buffer-substring-no-properties (region-beginning) (region-end))
                   "[abc]"))
    (should (eerie-visual-mode-p))))

(ert-deftest eerie-visual-block-start-enables-rectangle-mark-mode ()
  (eerie-test-with-buffer "abc\ndef\n"
    (call-interactively #'eerie-visual-block-start)
    (should (eerie-visual-mode-p))
    (should (eq eerie--visual-type 'block))
    (should (bound-and-true-p rectangle-mark-mode))))

(ert-deftest eerie-visual-block-start-selects-current-char-column ()
  (eerie-test-with-buffer "012345\nabcdef\n"
    (forward-char 2)
    (call-interactively #'eerie-visual-block-start)
    (should (equal (extract-rectangle (region-beginning) (region-end))
                   '("2")))))

(ert-deftest eerie-visual-block-exit-clears-rectangle-mode ()
  (eerie-test-with-buffer "012345\nabcdef\n"
    (forward-char 2)
    (call-interactively #'eerie-visual-block-start)
    (call-interactively #'eerie-visual-exit)
    (should (eerie-normal-mode-p))
    (should-not (region-active-p))
    (should-not (bound-and-true-p rectangle-mark-mode))))

(ert-deftest eerie-visual-block-movement-preserves-column ()
  (eerie-test-with-buffer "012345\nabcdef\nuvwxyz\n"
    (forward-char 3)
    (call-interactively #'eerie-visual-block-start)
    (call-interactively #'eerie-visual-next)
    (should (= (current-column) 3))
    (should (= (save-excursion
                 (goto-char (mark t))
                 (current-column))
               4))))

(ert-deftest eerie-visual-block-delete-removes-selected-column-via-key-sequence ()
  (eerie-test-with-buffer "012345\nabcdef\nuvwxyz\n"
    (forward-char 2)
    (execute-kbd-macro (kbd "C-v j d"))
    (should (eerie-normal-mode-p))
    (should (equal (buffer-string)
                   "01345\nabdef\nuvwxyz\n"))))

(ert-deftest eerie-visual-block-insert-replays-on-selected-lines-via-key-sequence ()
  (eerie-test-with-buffer "012345\nabcdef\nuvwxyz\n"
    (forward-char 2)
    (execute-kbd-macro (kbd "C-v j I Z <escape>"))
    (should (eerie-normal-mode-p))
    (should (equal (buffer-string)
                   "01Z2345\nabZcdef\nuvwxyz\n"))))

(ert-deftest eerie-visual-block-append-replays-on-selected-lines-via-key-sequence ()
  (eerie-test-with-buffer "012345\nabcdef\nuvwxyz\n"
    (forward-char 2)
    (execute-kbd-macro (kbd "C-v j A Z <escape>"))
    (should (eerie-normal-mode-p))
    (should (equal (buffer-string)
                   "012Z345\nabcZdef\nuvwxyz\n"))))

(ert-deftest eerie-multicursor-visual-exit-without-builder-keeps-multicursor ()
  (eerie-test-with-buffer "012345\nabcdef\n"
    (call-interactively #'eerie-multicursor-start)
    (forward-char 2)
    (call-interactively #'eerie-visual-block-start)
    (call-interactively #'eerie-multicursor-visual-exit)
    (should (eerie-multicursor-mode-p))
    (should eerie--multicursor-active)
    (should-not (region-active-p))
    (should-not (bound-and-true-p rectangle-mark-mode))))

(ert-deftest eerie-jump-back-and-forward-round-trip ()
  (eerie-test-with-buffer "alpha\nbeta\ngamma\n"
    (goto-char (point-min))
    (call-interactively #'eerie-goto-buffer-end)
    (should (= (point) (point-max)))
    (call-interactively #'eerie-jump-back)
    (should (= (point) (point-min)))
    (call-interactively #'eerie-jump-forward)
    (should (= (point) (point-max)))))

(ert-deftest eerie-jump-history-dedupes-repeat-noop-jumps ()
  (eerie-test-with-buffer "alpha\nbeta\n"
    (call-interactively #'eerie-goto-buffer-end)
    (should (= (length (eerie--get-jump-stack 'back)) 1))
    (call-interactively #'eerie-goto-buffer-end)
    (should (= (length (eerie--get-jump-stack 'back)) 1))))

(ert-deftest eerie-goto-line-records-pre-jump-location ()
  (eerie-test-with-buffer "one\ntwo\nthree\n"
    (search-forward "e")
    (let ((origin (point))
          (eerie-goto-line-function #'eerie-test-goto-second-line))
      (call-interactively #'eerie-goto-line)
      (should-not (= (point) origin))
      (call-interactively #'eerie-jump-back)
      (should (= (point) origin)))))

(ert-deftest eerie-jump-history-clears-forward-stack-after-new-jump ()
  (eerie-test-with-buffer "alpha\nbeta\ngamma\n"
    (let ((eerie-goto-line-function #'eerie-test-goto-second-line))
      (call-interactively #'eerie-goto-buffer-end)
      (call-interactively #'eerie-jump-back)
      (should (eerie--get-jump-stack 'forward))
      (call-interactively #'eerie-goto-line)
      (should-not (eerie--get-jump-stack 'forward))
      (should-error (call-interactively #'eerie-jump-forward) :type 'user-error))))

(ert-deftest eerie-mark-jumps-participate-in-jump-history ()
  (eerie-test-with-buffer "alpha\nbeta\ngamma\n"
    (let ((origin (point))
          (destination (point-max)))
      (push-mark destination t t)
      (call-interactively #'eerie-pop-to-mark)
      (should (= (point) destination))
      (call-interactively #'eerie-jump-back)
      (should (= (point) origin))
      (call-interactively #'eerie-jump-forward)
      (should (= (point) destination))
      (call-interactively #'eerie-unpop-to-mark)
      (should (= (point) origin))
      (call-interactively #'eerie-jump-back)
      (should (= (point) destination)))))

(ert-deftest eerie-search-commands-record-jumps-and-repeat ()
  (eerie-test-with-buffer "a foo b foo c foo\n"
    (let ((origin (point)))
      (eerie-test-run-search #'eerie-search-forward "foo")
      (let ((first (point)))
        (should (> first origin))
        (call-interactively #'eerie-search-next)
        (let ((second (point)))
          (should (> second first))
          (call-interactively #'eerie-jump-back)
          (should (= (point) first))
          (call-interactively #'eerie-jump-back)
          (should (= (point) origin))
          (call-interactively #'eerie-jump-forward)
          (should (= (point) first))
          (call-interactively #'eerie-jump-forward)
          (should (= (point) second)))))))

(ert-deftest eerie-search-backward-and-opposite-repeat-work ()
  (eerie-test-with-buffer "foo bar foo baz foo\n"
    (goto-char (point-max))
    (eerie-test-run-search #'eerie-search-backward "foo")
    (let ((last (point)))
      (call-interactively #'eerie-search-next)
      (let ((previous (point)))
        (should (< previous last))
        (call-interactively #'eerie-search-prev)
        (should (= (point) last))))))

(ert-deftest eerie-auto-records-non-eerie-jump-commands ()
  (eerie-test-with-buffer "alpha\nbeta\ngamma\n"
    (goto-char (point-min))
    (call-interactively #'end-of-buffer)
    (should (= (point) (point-max)))
    (call-interactively #'eerie-jump-back)
    (should (= (point) (point-min)))))

(ert-deftest eerie-global-mark-jumps-support-cross-buffer-round-trips ()
  (let ((buf-a (generate-new-buffer " *eerie-jump-a*"))
        (buf-b (generate-new-buffer " *eerie-jump-b*"))
        (global-mark-ring nil))
    (unwind-protect
        (save-window-excursion
          (with-current-buffer buf-a
            (insert "alpha\n")
            (goto-char (point-min))
            (forward-char 2)
            (fundamental-mode)
            (transient-mark-mode 1)
            (eerie-mode 1)
            (eerie--set-jump-stack 'back nil)
            (eerie--set-jump-stack 'forward nil))
          (with-current-buffer buf-b
            (insert "beta\n")
            (goto-char (point-min))
            (forward-char 3)
            (fundamental-mode)
            (transient-mark-mode 1)
            (eerie-mode 1)
            (eerie--set-jump-stack 'back nil)
            (eerie--set-jump-stack 'forward nil))
          (switch-to-buffer buf-a)
          (let ((origin (point))
                (target (with-current-buffer buf-b (point-marker))))
            (setq global-mark-ring (list target))
            (call-interactively #'eerie-pop-to-global-mark)
            (should (eq (current-buffer) buf-b))
            (should (= (point) 4))
            (call-interactively #'eerie-jump-back)
            (should (eq (current-buffer) buf-a))
            (should (= (point) origin))
            (call-interactively #'eerie-jump-forward)
            (should (eq (current-buffer) buf-b))
            (should (= (point) 4))))
      (when (buffer-live-p buf-a)
        (with-current-buffer buf-a
          (when (bound-and-true-p eerie-mode)
            (eerie-mode -1))))
      (when (buffer-live-p buf-b)
        (with-current-buffer buf-b
          (when (bound-and-true-p eerie-mode)
            (eerie-mode -1))))
      (when (buffer-live-p buf-a)
        (kill-buffer buf-a))
      (when (buffer-live-p buf-b)
        (kill-buffer buf-b)))))

(ert-deftest eerie-jumplists-are-isolated-per-window ()
  (let ((buf-a (generate-new-buffer " *eerie-win-a*"))
        (buf-b (generate-new-buffer " *eerie-win-b*")))
    (unwind-protect
        (save-window-excursion
          (switch-to-buffer buf-a)
          (insert "alpha\nbeta\ngamma\n")
          (goto-char (point-min))
          (fundamental-mode)
          (transient-mark-mode 1)
          (eerie-mode 1)
          (eerie--set-jump-stack 'back nil)
          (eerie--set-jump-stack 'forward nil)
          (let ((win-a (selected-window))
                (win-b (split-window-right)))
            (set-window-buffer win-b buf-b)
            (with-selected-window win-b
              (erase-buffer)
              (insert "one\ntwo\nthree\n")
              (goto-char (point-max))
              (fundamental-mode)
              (transient-mark-mode 1)
              (eerie-mode 1)
              (eerie--set-jump-stack 'back nil)
              (eerie--set-jump-stack 'forward nil))
            (with-selected-window win-a
              (call-interactively #'end-of-buffer))
            (with-selected-window win-b
              (call-interactively #'beginning-of-buffer))
            (with-selected-window win-a
              (call-interactively #'eerie-jump-back)
              (should (= (point) (point-min)))
              (should-not (eerie--get-jump-stack 'back)))
            (with-selected-window win-b
              (call-interactively #'eerie-jump-back)
              (should (= (point) (point-max)))
              (should-not (eerie--get-jump-stack 'back)))))
      (when (buffer-live-p buf-a)
        (with-current-buffer buf-a
          (when (bound-and-true-p eerie-mode)
            (eerie-mode -1))))
      (when (buffer-live-p buf-b)
        (with-current-buffer buf-b
          (when (bound-and-true-p eerie-mode)
            (eerie-mode -1))))
      (when (buffer-live-p buf-a)
        (kill-buffer buf-a))
      (when (buffer-live-p buf-b)
        (kill-buffer buf-b)))))

(provide 'eerie-vim-tests)
;;; eerie-vim-tests.el ends here
