# Eerie Project Layout Reorganization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move the shipped `eerie` package into `lisp/`, remove stale legacy root docs and tracked backup junk, and keep the package fully green under the cleaner layout.

**Architecture:** Treat this as a mechanical repository reorganization with the current smoke test and ERT suite as the behavioral contract. Move the shipped Elisp and update packaging first, then update canonical commands/docs to the new load path, then delete stale legacy files and finish with an audit pass.

**Tech Stack:** Emacs Lisp, ERT, Eask, batch Emacs, ripgrep, git

---

### Task 1: Create Reorg Trackers And A Red Load-Path Test

**Files:**
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE52_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE53_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE54_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/eerie-vim-tests.el`

- [ ] **Step 1: Add Stage 52 through Stage 54 to the tracker**

Update `.plan/PLAN.md` to add the reorganization stages, mark Stage 52
active, and describe the `lisp/` move plus the legacy-doc deletion
scope. Create `STAGE52_TODO.md`, `STAGE53_TODO.md`, and
`STAGE54_TODO.md` with unchecked tasks that match this plan.

- [ ] **Step 2: Write the failing load-path test change**

In `tests/eerie-vim-tests.el`, change the top-level require to load the
entry point from the future source directory:

```elisp
(require 'eerie nil nil)
```

Keep the file itself in `tests/`; do not move it.

- [ ] **Step 3: Run the red smoke-style load**

Run:

```bash
emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el --eval "(ert-run-tests-batch-and-exit 'eerie-default-normal-keymap-is-vim-like)"
```

Expected: FAIL because `lisp/` does not exist yet and the package cannot
be loaded from the future path.

- [ ] **Step 4: Commit the tracker bootstrap**

```bash
git add .plan/PLAN.md .plan/STAGE52_TODO.md .plan/STAGE53_TODO.md .plan/STAGE54_TODO.md tests/eerie-vim-tests.el
git commit -m "Prepare project layout reorganization tracker"
```

### Task 2: Move The Shipped Package Into `lisp/`

**Files:**
- Create: `/Users/jfilipe/Documents/GitHub/meow/lisp/`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-beacon.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-beacon.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-cheatsheet.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-cheatsheet.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-cheatsheet-layout.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-cheatsheet-layout.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-command.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-command.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-core.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-core.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-esc.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-esc.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-face.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-face.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-helpers.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-helpers.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-keymap.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-keymap.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-keypad.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-keypad.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-shims.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-shims.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-thing.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-thing.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-tutor.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-tutor.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-util.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-util.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-var.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-var.el`
- Rename: `/Users/jfilipe/Documents/GitHub/meow/eerie-visual.el` -> `/Users/jfilipe/Documents/GitHub/meow/lisp/eerie-visual.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/Eask`

- [ ] **Step 1: Move every shipped Elisp file with `git mv`**

Run:

```bash
mkdir -p lisp
git mv eerie.el lisp/eerie.el
git mv eerie-beacon.el lisp/eerie-beacon.el
git mv eerie-cheatsheet.el lisp/eerie-cheatsheet.el
git mv eerie-cheatsheet-layout.el lisp/eerie-cheatsheet-layout.el
git mv eerie-command.el lisp/eerie-command.el
git mv eerie-core.el lisp/eerie-core.el
git mv eerie-esc.el lisp/eerie-esc.el
git mv eerie-face.el lisp/eerie-face.el
git mv eerie-helpers.el lisp/eerie-helpers.el
git mv eerie-keymap.el lisp/eerie-keymap.el
git mv eerie-keypad.el lisp/eerie-keypad.el
git mv eerie-shims.el lisp/eerie-shims.el
git mv eerie-thing.el lisp/eerie-thing.el
git mv eerie-tutor.el lisp/eerie-tutor.el
git mv eerie-util.el lisp/eerie-util.el
git mv eerie-var.el lisp/eerie-var.el
git mv eerie-visual.el lisp/eerie-visual.el
```

- [ ] **Step 2: Update `Eask` to the new source directory**

Change `Eask` to:

```lisp
(package-file "lisp/eerie.el")
(files "lisp/eerie*.el" "lisp/eerie.el")
(script "test" "emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit")
```

- [ ] **Step 3: Run the renamed package load smoke test**

Run:

```bash
emacs -Q --batch -L lisp -l lisp/eerie.el
```

Expected: PASS.

- [ ] **Step 4: Run the focused test to verify the new load path**

Run:

```bash
emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el --eval "(ert-run-tests-batch-and-exit 'eerie-default-normal-keymap-is-vim-like)"
```

Expected: PASS.

- [ ] **Step 5: Commit the source-directory move**

```bash
git add lisp Eask tests/eerie-vim-tests.el
git commit -m "Move eerie package sources into lisp"
```

### Task 3: Update Canonical Commands And Docs To `lisp/`

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/README.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/AGENTS.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE52_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE53_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE54_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/eerie-interactive-demo.el`

- [ ] **Step 1: Update the README commands**

Change every canonical load example in `README.md` to use `lisp/`, for
example:

```sh
emacs -Q -L lisp tests/eerie-interactive-demo.el --eval "(require 'eerie)" --eval "(eerie-global-mode 1)"
```

and:

```sh
emacs -Q --batch -L lisp -l lisp/eerie.el
```

- [ ] **Step 2: Update AGENTS and `.plan/*` verification commands**

Replace root-level `-L .` / `-l eerie.el` verification snippets with the
new `lisp/` form everywhere in the canonical tracker/docs:

```sh
emacs -Q --batch -L lisp -l lisp/eerie.el
emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

- [ ] **Step 3: Update the interactive demo header comment**

In `tests/eerie-interactive-demo.el`, change the manual launch comment
to:

```elisp
;;   emacs -Q -L lisp tests/eerie-interactive-demo.el --eval "(require 'eerie)" --eval "(eerie-global-mode 1)"
```

- [ ] **Step 4: Run the full ERT suite under the new documented command**

Run:

```bash
emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS.

- [ ] **Step 5: Commit the canonical command updates**

```bash
git add README.md AGENTS.md .plan/PLAN.md .plan/STAGE52_TODO.md .plan/STAGE53_TODO.md .plan/STAGE54_TODO.md tests/eerie-interactive-demo.el
git commit -m "Update docs for lisp source layout"
```

### Task 4: Delete Legacy Root Docs And Tracked Backup Files

**Files:**
- Delete: `/Users/jfilipe/Documents/GitHub/meow/README.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/COMMANDS.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/CUSTOMIZATIONS.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/EXPLANATION.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/FAQ.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/GET_STARTED.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/KEYBINDING_COLEMAK.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/KEYBINDING_DVORAK.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/KEYBINDING_DVP.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/KEYBINDING_QWERTY.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/KEYBINDING_QWERTZ.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/TUTORIAL.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/VIM_COMPARISON.org`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/#FAQ.org#`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/tests/#meow-interactive-demo.el#`
- Delete: `/Users/jfilipe/Documents/GitHub/meow/tests/#meow-vim-tests.el#`

- [ ] **Step 1: Audit canonical references before deletion**

Run:

```bash
rg -n -- "README\\.org|COMMANDS\\.org|CUSTOMIZATIONS\\.org|EXPLANATION\\.org|FAQ\\.org|GET_STARTED\\.org|KEYBINDING_|TUTORIAL\\.org|VIM_COMPARISON\\.org|#FAQ\\.org#|#meow-interactive-demo\\.el#|#meow-vim-tests\\.el#" README.md AGENTS.md .plan Eask tests .github docs
```

Expected: either no matches, or only matches inside the new reorg spec
and plan documents under `docs/superpowers/`.

- [ ] **Step 2: Delete the stale docs and tracked backup files**

Run:

```bash
git rm README.org COMMANDS.org CUSTOMIZATIONS.org EXPLANATION.org FAQ.org GET_STARTED.org KEYBINDING_COLEMAK.org KEYBINDING_DVORAK.org KEYBINDING_DVP.org KEYBINDING_QWERTY.org KEYBINDING_QWERTZ.org TUTORIAL.org VIM_COMPARISON.org
git rm '#FAQ.org#' 'tests/#meow-interactive-demo.el#' 'tests/#meow-vim-tests.el#'
```

- [ ] **Step 3: Verify the root is cleaner**

Run:

```bash
find . -maxdepth 1 -mindepth 1 | sort
```

Expected: no shipped `eerie*.el` files at the root, no legacy root
`.org` docs, and no tracked backup junk.

- [ ] **Step 4: Commit the stale-file cleanup**

```bash
git add -u
git commit -m "Remove stale legacy docs and backup files"
```

### Task 5: Final Audit And Tracker Closeout

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE52_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE53_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE54_TODO.md`

- [ ] **Step 1: Run the final stale-path audit**

Run:

```bash
rg -n -- "-L \\.|eerie\\.el|eerie-\\*\\.el|README\\.org|COMMANDS\\.org|CUSTOMIZATIONS\\.org|EXPLANATION\\.org|FAQ\\.org|GET_STARTED\\.org|KEYBINDING_|TUTORIAL\\.org|VIM_COMPARISON\\.org" README.md AGENTS.md .plan Eask tests .github docs
```

Expected: no stale root-layout references remain in the canonical docs,
package config, tests, or tracker files. Historical process docs under
`docs/superpowers/` may still contain old paths and do not need to be
rewritten.

- [ ] **Step 2: Re-run final verification**

Run:

```bash
emacs -Q --batch -L lisp -l lisp/eerie.el
emacs -Q --batch -L lisp -L tests -l tests/eerie-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS.

- [ ] **Step 3: Close the tracker**

Update `.plan/PLAN.md` and `STAGE52_TODO.md` through `STAGE54_TODO.md`
to mark the reorg complete, set the active stage back to none, and
record any deferred cleanup that remains.

- [ ] **Step 4: Commit the final tracker closeout**

```bash
git add .plan/PLAN.md .plan/STAGE52_TODO.md .plan/STAGE53_TODO.md .plan/STAGE54_TODO.md
git commit -m "Finalize project layout reorganization"
```
