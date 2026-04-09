# Meow Cleanup Refactor Implementation Plan

> **Status:** Completed on 2026-04-09. The canonical execution record
> lives in `.plan/PLAN.md` and `.plan/STAGE43_TODO.md` through
> `.plan/STAGE46_TODO.md`; this document remains as the original
> implementation plan snapshot.

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove non-shipped leftover Meow code and refactor the remaining live Vim-fork code into a smaller, clearer, non-redundant implementation without changing shipped behavior.

**Architecture:** Treat the current normal/visual/multicursor workflow plus the existing ERT suite as the behavioral contract. First strengthen end-to-end coverage around canonical key-sequence paths, then remove dead or superseded internal paths in small slices, then consolidate duplicated live helpers in `meow-command.el` and adjacent files without redesigning the user-facing model.

**Tech Stack:** Emacs Lisp, ERT, batch Emacs, ripgrep, git

---

### Task 1: Audit Shipped Entry Points And Strengthen The Safety Net

**Files:**
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE43_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE44_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE45_TODO.md`
- Create: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE46_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/meow-vim-tests.el`

- [ ] **Step 1: Add stage-tracker placeholders for the cleanup work**

Update `.plan/PLAN.md` to add Stage 43 through Stage 46 and set the
next active stage to the cleanup audit. Create four new stage TODO
files with unchecked tasks matching this plan.

- [ ] **Step 2: Add or rewrite end-to-end tests for canonical workflows that still lean on internal helpers**

Prefer real key-sequence coverage over direct helper calls where the
current suite still depends on non-canonical internals.

```elisp
(ert-deftest meow-canonical-multicursor-key-sequence-remains-live ()
  (meow-test-with-buffer "foo xx foo yy foo\n"
    (execute-kbd-macro (kbd "m w . v d"))
    (should (equal (buffer-string) " xx  yy foo\n"))))
```

- [ ] **Step 3: Run the focused audit tests**

Run: `emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el --eval "(ert-run-tests-batch-and-exit '(or meow-canonical-multicursor-key-sequence-remains-live meow-visual-m-enters-multicursor-from-charwise-selection meow-visual-block-insert-replays-on-selected-lines-via-key-sequence meow-jump-char-participates-in-jump-history))"`

Expected: PASS for the newly added canonical key-sequence tests. If a
test already passes on the first run, keep it as a safety-net
regression and continue.

- [ ] **Step 4: Generate a reachability checklist for cleanup candidates**

Run:

```bash
rg -n "meow-multiedit-|meow-multicursor-spawn|meow-visual-search-next-or-multicursor" meow-command.el meow-keymap.el tests/meow-vim-tests.el README.md AGENTS.md .plan/PLAN.md
rg -n "defun meow-(find-ref|clipboard-|comment|page-up|page-down|forward-slurp|backward-slurp|raise-sexp|transpose-sexp|split-sexp|join-sexp|splice-sexp|wrap-round|wrap-square|wrap-curly|wrap-string|open-above|open-below|change-save|replace-save|replace-pop)" meow-command.el
```

Expected: a concrete candidate list grouped into `keep`, `refactor`,
and `delete` in `STAGE43_TODO.md`.

- [ ] **Step 5: Run the full suite before starting deletions**

Run:

```bash
emacs -Q --batch -L . -l meow.el
emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS, establishing the pre-cleanup baseline.

- [ ] **Step 6: Mark Stage 43 complete and advance the tracker**

Update `.plan/STAGE43_TODO.md` with the final keep/refactor/delete
classification, mark its tasks complete, and move `.plan/PLAN.md` to
the next active cleanup stage.

- [ ] **Step 7: Commit the audit baseline**

```bash
git add .plan/PLAN.md .plan/STAGE43_TODO.md .plan/STAGE44_TODO.md .plan/STAGE45_TODO.md .plan/STAGE46_TODO.md tests/meow-vim-tests.el
git commit -m "Audit cleanup candidates and strengthen safety tests"
```

### Task 2: Remove Non-Canonical Multiedit And Multicursor Compatibility Paths

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-command.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-keymap.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/meow-vim-tests.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE43_TODO.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE44_TODO.md`

- [ ] **Step 1: Delete compatibility entry points that are not part of the shipped workflow**

Candidates to remove if the audit confirms they are unreachable from
the canonical flow:

- `meow-visual-search-next-or-multicursor`
- old multiedit-direction helpers that are no longer bound or
  documented
- compatibility allowlist entries that only exist for those dead paths

- [ ] **Step 2: Replace internal-helper tests with canonical key-sequence tests**

Any test that currently exists only to pin dead compatibility commands
should be rewritten against the shipped `m`, `.`, `,`, `-`, `v`, and
`ESC` flow or removed if it no longer describes shipped behavior.

```elisp
;; Replace direct helper invocation:
(call-interactively #'meow-multiedit-match-next)

;; With a shipped path:
(execute-kbd-macro (kbd "m w ."))
```

- [ ] **Step 3: Run focused multicursor and multiedit regressions**

Run: `emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el --eval "(ert-run-tests-batch-and-exit '(or meow-visual-m-dot-adds-next-match meow-multicursor-start-enters-session-and-displays-menu meow-multicursor-new-flow-v-promotes-to-normal-multicursor meow-multicursor-w-dot-d-deletes-all-word-matches))"`

Expected: PASS with no remaining references to removed compatibility
commands.

- [ ] **Step 4: Run the full suite**

Run:

```bash
emacs -Q --batch -L . -l meow.el
emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS.

- [ ] **Step 5: Mark Stage 44 complete and record what was deleted**

Update `.plan/STAGE44_TODO.md` and `.plan/PLAN.md` with the exact
compatibility paths removed and any intentionally retained leftovers.

- [ ] **Step 6: Commit the compatibility-path cleanup**

```bash
git add meow-command.el meow-keymap.el tests/meow-vim-tests.el .plan/PLAN.md .plan/STAGE43_TODO.md .plan/STAGE44_TODO.md
git commit -m "Remove non-canonical multiedit compatibility paths"
```

### Task 3: Remove Unreachable Upstream Commands And Stale Internal Surface

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-command.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-var.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-beacon.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-tutor.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/meow-vim-tests.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE45_TODO.md`

- [ ] **Step 1: Build the exact removal list from the Stage 43 audit**

Likely candidates, subject to confirmed non-reachability:

- upstream clipboard helpers not used by shipped keymaps
- page-up/page-down helpers not used by shipped states
- sexp wrap/slurp/barf helpers not used by shipped states
- open-above/open-below variants not used by shipped states
- replace-save/replace-pop paths not used by shipped Vim defaults

- [ ] **Step 2: Remove dead command definitions and corresponding indicator/config references**

Delete the command implementation, then remove matching entries from
`meow-var.el`, beacon remaps, and tutor references if they only exist
for deleted commands.

```elisp
;; Remove dead indicator names once the command is gone:
(meow-change-save . "chg-save")
(meow-open-below . "open ↓")
```

- [ ] **Step 3: Add or adjust tests for any edge that turns out to still be live**

If removing a candidate exposes an indirectly-live dependency, stop and
add a behavioral test for the shipped path before deciding whether to
keep or refactor that code.

- [ ] **Step 4: Run focused load and replay coverage**

Run: `emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el --eval "(ert-run-tests-batch-and-exit '(or meow-multicursor-replays-insert-session-to-secondary-cursors meow-visual-block-insert-replays-on-selected-lines-via-key-sequence meow-operator-change-inner-round-implements-ci-paren meow-jump-matching-visits-delimiter-pairs))"`

Expected: PASS.

- [ ] **Step 5: Run the full suite**

Run:

```bash
emacs -Q --batch -L . -l meow.el
emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS.

- [ ] **Step 6: Mark Stage 45 complete and commit**

```bash
git add meow-command.el meow-var.el meow-beacon.el meow-tutor.el tests/meow-vim-tests.el .plan/PLAN.md .plan/STAGE45_TODO.md
git commit -m "Prune unreachable upstream command surface"
```

### Task 4: Consolidate Live Replay, Visual, And State-Cleanup Helpers

**Files:**
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-command.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-var.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/meow-util.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/tests/meow-vim-tests.el`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/README.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/AGENTS.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- Modify: `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE46_TODO.md`

- [ ] **Step 1: Consolidate replay-target handling**

Merge duplicated marker/column targeting logic used by:

- multiedit insert and append replay
- multicursor insert replay setup
- block visual `I` and `A`

into one internal helper path.

```elisp
(defun meow--replay-target-goto (target)
  "Restore TARGET for replay.

TARGET is either a marker or a (MARKER . COLUMN) pair."
  ...)
```

Preserve the existing block-visual behavior exactly: `I` must still
target the rectangle's left edge by column, and `A` must still target
the rectangle's right edge by column instead of degrading into raw
marker-only replay.

- [ ] **Step 2: Consolidate visual finish and state-reset helpers**

Reduce duplicated cleanup logic for:

- visual finish/exit
- multiedit reset/deactivate
- multicursor cancel and replay teardown

without changing any state transition visible to the user.

- [ ] **Step 3: Remove redundant allowlists and overlapping compatibility branches**

Collapse repeated command allowlists and state checks where the
canonical workflow now has a single live path.

- [ ] **Step 4: Run focused regression groups after each consolidation slice**

Run subsets as you go, then the full suite once the consolidation is
done.

```bash
emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el --eval "(ert-run-tests-batch-and-exit '(or meow-visual-block-append-replays-on-selected-lines-via-key-sequence meow-visual-block-insert-replays-on-selected-lines-via-key-sequence meow-multicursor-replays-insert-session-to-secondary-cursors meow-visual-line-start-jumps-to-visible-lines meow-multicursor-vi-paren-deletes-all-inner-objects))"
```

Expected: PASS after each slice.

- [ ] **Step 5: Sync docs and final stage trackers**

Update:

- `/Users/jfilipe/Documents/GitHub/meow/README.md`
- `/Users/jfilipe/Documents/GitHub/meow/AGENTS.md`
- `/Users/jfilipe/Documents/GitHub/meow/.plan/PLAN.md`
- `/Users/jfilipe/Documents/GitHub/meow/.plan/STAGE46_TODO.md`

Only document actual resulting behavior or explicit remaining
deferred work.

- [ ] **Step 6: Run final verification**

Run:

```bash
emacs -Q --batch -L . -l meow.el
emacs -Q --batch -L . -L tests -l tests/meow-vim-tests.el -f ert-run-tests-batch-and-exit
```

Expected: PASS with a smaller, clearer live surface.

- [ ] **Step 7: Commit the consolidation pass**

```bash
git add meow-command.el meow-var.el meow-util.el tests/meow-vim-tests.el README.md AGENTS.md .plan/PLAN.md .plan/STAGE46_TODO.md
git commit -m "Refactor live Vim workflow helpers"
```
