# Stage 43 TODO

## Goal

Audit the shipped cleanup surface and strengthen the test safety net
before deleting or consolidating code.

## Tasks

- [x] Add Stage 43 through Stage 46 to `.plan/PLAN.md`
- [x] Add or rewrite canonical end-to-end regressions in
  `tests/eerie-vim-tests.el`
- [x] Audit likely cleanup candidates into keep/refactor/delete groups
- [x] Record the candidate list and risk notes in this stage file
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite

## Audit Result

### Keep

- `eerie-multiedit-match-next`
- `eerie-multiedit-unmatch-last`
- `eerie-multiedit-skip-match`
- `eerie-multiedit-reverse-direction`
- `eerie-multicursor-start`
- `eerie-multicursor-match-next`
- `eerie-multicursor-unmatch-last`
- `eerie-multicursor-skip-match`
- `eerie-multicursor-visual-exit`
- `eerie-multicursor-cancel`
- `eerie-multicursor-jump-char`
- `eerie-multicursor-next-space`
- `eerie-find-ref`
- `eerie-clipboard-yank`
- `eerie-clipboard-kill`
- `eerie-clipboard-save`
- `eerie-comment`
- `eerie-page-up`
- `eerie-page-down`
- `eerie-forward-slurp`
- `eerie-backward-slurp`
- `eerie-raise-sexp`
- `eerie-transpose-sexp`
- `eerie-split-sexp`
- `eerie-join-sexp`
- `eerie-splice-sexp`
- `eerie-wrap-round`
- `eerie-wrap-square`
- `eerie-wrap-curly`
- `eerie-wrap-string`
- `eerie-open-above`
- `eerie-open-above-visual`
- `eerie-open-below`
- `eerie-open-below-visual`
- `eerie-change-save`
- `eerie-replace-save`
- `eerie-replace-pop`

### Refactor

- `eerie-multicursor-spawn` because it is still the promotion bridge from
  the old multiedit target set into multicursor normal
- `eerie-multiedit-clear` because it is a legacy teardown helper that
  still backs the canonical visual-exit path

### Delete

- `eerie-visual-search-next-or-multicursor` because the shipped keymaps
  no longer bind it and plain visual search repeat is the canonical
  behavior

### Risk Notes

- Keep the `eerie-multiedit-*` engine in place until Stage 44 finishes
  replacing the last compatibility-path tests with canonical key
  sequences.
- Do not remove `eerie-multicursor-spawn` until the promotion behavior is
  split cleanly from the remaining visual-exit and replay paths.
- `eerie-visual-search-next-or-multicursor` is safe to delete only after a
  final pass confirms no external docs or tests still reference it.
