# Stage 43 TODO

## Goal

Audit the shipped cleanup surface and strengthen the test safety net
before deleting or consolidating code.

## Tasks

- [x] Add Stage 43 through Stage 46 to `.plan/PLAN.md`
- [x] Add or rewrite canonical end-to-end regressions in
  `tests/meow-vim-tests.el`
- [x] Audit likely cleanup candidates into keep/refactor/delete groups
- [x] Record the candidate list and risk notes in this stage file
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite

## Audit Result

### Keep

- `meow-multiedit-match-next`
- `meow-multiedit-unmatch-last`
- `meow-multiedit-skip-match`
- `meow-multiedit-reverse-direction`
- `meow-multicursor-start`
- `meow-multicursor-match-next`
- `meow-multicursor-unmatch-last`
- `meow-multicursor-skip-match`
- `meow-multicursor-visual-exit`
- `meow-multicursor-cancel`
- `meow-multicursor-jump-char`
- `meow-multicursor-next-space`
- `meow-find-ref`
- `meow-clipboard-yank`
- `meow-clipboard-kill`
- `meow-clipboard-save`
- `meow-comment`
- `meow-page-up`
- `meow-page-down`
- `meow-forward-slurp`
- `meow-backward-slurp`
- `meow-raise-sexp`
- `meow-transpose-sexp`
- `meow-split-sexp`
- `meow-join-sexp`
- `meow-splice-sexp`
- `meow-wrap-round`
- `meow-wrap-square`
- `meow-wrap-curly`
- `meow-wrap-string`
- `meow-open-above`
- `meow-open-above-visual`
- `meow-open-below`
- `meow-open-below-visual`
- `meow-change-save`
- `meow-replace-save`
- `meow-replace-pop`

### Refactor

- `meow-multicursor-spawn` because it is still the promotion bridge from
  the old multiedit target set into multicursor normal
- `meow-multiedit-clear` because it is a legacy teardown helper that
  still backs the canonical visual-exit path

### Delete

- `meow-visual-search-next-or-multicursor` because the shipped keymaps
  no longer bind it and plain visual search repeat is the canonical
  behavior

### Risk Notes

- Keep the `meow-multiedit-*` engine in place until Stage 44 finishes
  replacing the last compatibility-path tests with canonical key
  sequences.
- Do not remove `meow-multicursor-spawn` until the promotion behavior is
  split cleanly from the remaining visual-exit and replay paths.
- `meow-visual-search-next-or-multicursor` is safe to delete only after a
  final pass confirms no external docs or tests still reference it.
