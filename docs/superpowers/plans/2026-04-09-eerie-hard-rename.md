# Eerie Hard Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename the shipped package surface from `meow` to `eerie` with no compatibility layer, while preserving the current modal behavior.

**Architecture:** Treat this as a mechanical identity rename with the current ERT suite as the behavioral contract. Rename the load entry point and test harness first, then rename the module graph and Lisp symbols, then finish by updating canonical docs and auditing the remaining shipped surface for stale `meow` references.

**Tech Stack:** Emacs Lisp, ERT, batch Emacs, ripgrep, git

---

### Task 1: Create Rename Trackers And A Renamed Test Harness

**Files:**
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE48_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE49_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE50_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE51_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/tests/meow-vim-tests.el` -> `/Users/jfilipe/Documents/GitHub/meow/tests/eerie-vim-tests.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/tests/meow-interactive-demo.el` -> `/Users/jfilipe/Documents/GitHub/meow/tests/eerie-interactive-demo.el`

- [ ] **Step 1: Add stage placeholders for the hard rename**

Update `.plan/PLAN.md` to add Stage 48 through Stage 51 and set the
next active stage to the rename work. Create the four stage TODO files
with unchecked tasks that mirror this plan.

- [ ] **Step 2: Rename the test files before the package exists**

Use `git mv` to rename the test suite and the interactive demo:

```bash
git mv tests/meow-vim-tests.el tests/eerie-vim-tests.el
git mv tests/meow-interactive-demo.el tests/eerie-interactive-demo.el
```

- [ ] **Step 3: Write the failing entry-point test**

In `tests/eerie-vim-tests.el`, rename the test package load to
`(require 'eerie)` and rename at least one canonical test function to
the `eerie-...` form, for example:

```elisp
(require 'eerie)

(ert-deftest eerie-default-normal-keymap-is-vim-like ()
  (should (eq (lookup-key eerie-normal-state-keymap (kbd "h")) 'eerie-left)))
```

- [ ] **Step 4: Run the focused renamed test to verify RED**

Run:

```bash
emacs -Q --batch -L . -L tests -l tests/eerie-vim-tests.el --eval "(ert-run-tests-batch-and-exit 'eerie-default-normal-keymap-is-vim-like)"
```

Expected: FAIL because `eerie` does not exist yet, typically with
`Cannot open load file` or missing `eerie-*` symbols.

- [ ] **Step 5: Commit the tracker and red-test setup**

```bash
git add .plan/PLAN.md .plan/STAGE48_TODO.md .plan/STAGE49_TODO.md .plan/STAGE50_TODO.md .plan/STAGE51_TODO.md tests/eerie-vim-tests.el tests/eerie-interactive-demo.el
git commit -m "Prepare eerie rename tracker and tests"
```

### Task 2: Rename The Entry Point And Module Graph

**Files:**
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-beacon.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-beacon.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-cheatsheet.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-cheatsheet.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-cheatsheet-layout.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-cheatsheet-layout.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-command.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-command.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-core.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-core.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-esc.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-esc.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-face.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-face.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-helpers.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-helpers.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-keymap.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-keymap.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-keypad.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-keypad.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-shims.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-shims.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-thing.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-thing.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-tutor.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-tutor.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-util.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-util.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-var.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-var.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/meow-visual.el` -> `/Users/jfilipe/Documents/GitHub/meow/eerie-visual.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/Eask`

- [ ] **Step 1: Rename every shipped module file with `git mv`**

Run the `git mv` commands listed above so the file graph matches the new
package identity before feature renaming starts.

- [ ] **Step 2: Update the entry-point file header and module requires**

In `eerie.el`, change:

```elisp
;;; eerie.el --- Yet Another modal editing -*- lexical-binding: t; -*-
(require 'eerie-var)
...
(provide 'eerie)
```

Also update the commentary to use `eerie-global-mode`.

- [ ] **Step 3: Update every module header, `require`, `provide`, and `declare-function` reference**

Mechanically rename feature references across the renamed module files:

```elisp
(require 'meow-var)          ;; old
(require 'eerie-var)         ;; new

(declare-function meow-left "meow-command")   ;; old
(declare-function eerie-left "eerie-command") ;; new

(provide 'meow-command)      ;; old
(provide 'eerie-command)     ;; new
```

- [ ] **Step 4: Update package metadata in `Eask`**

Change:

```lisp
(package "eerie" "1.5.0" "Yet Another modal editing")
(package-file "eerie.el")
(files "eerie-*.el" "eerie.el")
(script "test" "emacs -Q --batch -L . -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit")
```

Keep the website URL unchanged unless the repository path is renamed in
the same task, which is out of scope here.

- [ ] **Step 5: Run the renamed package load smoke test**

Run:

```bash
emacs -Q --batch -L . -l eerie.el
```

Expected: PASS. The renamed entry point and module graph should load
cleanly, even before every renamed test passes.

- [ ] **Step 6: Commit the renamed module graph**

```bash
git add eerie.el eerie-*.el Eask
git commit -m "Rename package entry point and module graph to eerie"
```

### Task 3: Rename The Lisp Symbol Surface And Make The Renamed Tests Pass

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/eerie.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/eerie-*.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/eerie-vim-tests.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/eerie-interactive-demo.el`

- [ ] **Step 1: Run the renamed suite to verify RED on missing `eerie-*` symbols**

Run:

```bash
emacs -Q --batch -L . -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: FAIL with unresolved `eerie-*` symbols or stale `meow-*`
references.

- [ ] **Step 2: Mechanically rename the Lisp symbol surface**

Rename `meow-` to `eerie-` across the shipped code and renamed tests.
This includes:

- commands such as `meow-left` -> `eerie-left`
- modes such as `meow-global-mode` -> `eerie-global-mode`
- faces such as `meow-normal-indicator` -> `eerie-normal-indicator`
- variables such as `meow--multicursor-active` ->
  `eerie--multicursor-active`
- helpers such as `meow-normal-define-key` ->
  `eerie-normal-define-key`

Do the same for renamed test names and helpers:

```elisp
(ert-deftest eerie-visual-line-start-advances-by-logical-lines-when-lines-wrap ()
  ...)
```

- [ ] **Step 3: Update the interactive demo and test helpers to the new surface**

Ensure `tests/eerie-interactive-demo.el` and the ERT helpers use only
`eerie-*` symbols and the new `(require 'eerie)` entry point.

- [ ] **Step 4: Run focused renamed regressions**

Run:

```bash
emacs -Q --batch -L . -L tests -l tests/eerie-vim-tests.el --eval "(ert-run-tests-batch-and-exit '(or eerie-default-normal-keymap-is-vim-like eerie-visual-line-start-advances-by-logical-lines-when-lines-wrap eerie-multicursor-start-enters-session-and-displays-menu eerie-jump-char-participates-in-jump-history))"
```

Expected: PASS.

- [ ] **Step 5: Run the full renamed suite**

Run:

```bash
emacs -Q --batch -L . -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS.

- [ ] **Step 6: Commit the renamed symbol surface**

```bash
git add eerie.el eerie-*.el tests/eerie-vim-tests.el tests/eerie-interactive-demo.el
git commit -m "Rename Lisp symbol surface to eerie"
```

### Task 4: Update Canonical Docs And Audit The Remaining Shipped Surface

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/README.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/AGENTS.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE48_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE49_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE50_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE51_TODO.md`

- [ ] **Step 1: Update the canonical docs to `eerie`**

Update all canonical user-facing references:

- `README.md`
- `AGENTS.md`
- `.plan/PLAN.md`
- `.plan/STAGE48_TODO.md` through `.plan/STAGE51_TODO.md`

Examples:

```emacs-lisp
(require 'eerie)
(eerie-global-mode 1)
```

- [ ] **Step 2: Audit the shipped surface for stale `meow` references**

Run:

```bash
rg -n "\\bmeow\\b|meow-" eerie.el eerie-*.el Eask README.md AGENTS.md .plan tests/eerie-vim-tests.el tests/eerie-interactive-demo.el
rg --files | rg '(^|/)meow'
```

Expected:

- no stale `meow` references in the shipped package, canonical docs, or
  renamed tests
- no remaining `meow*.el` or `tests/meow-*` files

Historical process docs under `docs/superpowers/specs/` and
`docs/superpowers/plans/`, plus legacy upstream `.org` reference
material, do not need to be renamed in this task.

- [ ] **Step 3: Run final verification**

Run:

```bash
emacs -Q --batch -L . -l eerie.el
emacs -Q --batch -L . -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS.

- [ ] **Step 4: Commit the canonical doc and tracker rename**

```bash
git add README.md AGENTS.md .plan/PLAN.md .plan/STAGE48_TODO.md .plan/STAGE49_TODO.md .plan/STAGE50_TODO.md .plan/STAGE51_TODO.md
git commit -m "Update docs and trackers for eerie rename"
```

### Task 5: Final Packaging Audit And Integration

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/Eask`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/eerie.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/CHANGELOG.md`

- [ ] **Step 1: Re-check package metadata after the full rename**

Verify `Eask` and `eerie.el` still agree on:

- package name
- version
- package entry file
- test script path

- [ ] **Step 2: Add a short changelog note about the hard rename**

Record that the package surface was renamed from `meow` to `eerie`
without a compatibility layer.

- [ ] **Step 3: Run one final shipped-surface audit**

Run:

```bash
rg -n "\\bmeow\\b|meow-" eerie.el eerie-*.el Eask README.md AGENTS.md CHANGELOG.md tests/eerie-vim-tests.el tests/eerie-interactive-demo.el .plan
```

Expected: no shipped `meow` package surface remains.

- [ ] **Step 4: Commit the final packaging pass**

```bash
git add Eask eerie.el CHANGELOG.md
git commit -m "Finalize eerie package rename"
```
