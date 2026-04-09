# Stage 44 TODO

## Goal

Remove non-canonical multiedit and multicursor compatibility paths that
no longer serve the shipped workflow.

## Tasks

- [ ] Delete dead compatibility entry points confirmed by Stage 43
- [ ] Replace internal-helper tests with canonical key-sequence tests
- [ ] Remove dead keymap declarations or compatibility allowlist entries
- [ ] Re-run focused multicursor and multiedit regressions
- [ ] Re-run the batch load smoke test
- [ ] Re-run the full ERT suite
