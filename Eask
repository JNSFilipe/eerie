;; -*- mode: eask; lexical-binding: t -*-

(package "eerie"
         "1.5.0"
         "Yet Another modal editing")

(website-url "https://www.github.com/DogLooksGood/eerie")
(keywords "convenience" "modal-editing")

(package-file "lisp/eerie.el")
(files "lisp/eerie*.el" "lisp/eerie.el")

(script "test" "emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit")

(source 'gnu)
(source 'melpa)

(depends-on "emacs" "30.1")

(development
 (depends-on "macrostep")
 (depends-on "wdired")
 (depends-on "edebug")
 (depends-on "magit")
 (depends-on "wgrep")
 (depends-on "grep")
 (depends-on "company")
 (depends-on "corfu")
 (depends-on "polymode")
 (depends-on "cider")
 (depends-on "sly")
 (depends-on "realgud")
 (depends-on "undo-tree")
 (depends-on "diff-hl")
 (depends-on "skk")
 (depends-on "eat")
 (depends-on "ediff"))

(setq network-security-level 'low)  ; see https://github.com/jcs090218/setup-emacs-windows/issues/156#issuecomment-932956432

(add-hook 'eask-before-compile-hook
           (lambda ()
             ;; TODO: Enable this when clean up all compile warnings.
             (setq byte-compile-error-on-warn nil)))
