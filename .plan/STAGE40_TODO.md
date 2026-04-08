# Stage 40 TODO

## Goal

Let plain visual selections enter the canonical multicursor session
directly with `m`, using the current selection as the exact-match seed.

## Tasks

- [x] Bind visual `m` to a dedicated multicursor entry command
- [x] Preserve the current charwise visual selection while switching into
  `multicursor-visual`
- [x] Seed the canonical exact-match builder from that restored visual
  selection
- [x] Keep the new visual-entry command alive across the multiedit and
  multicursor post-command cleanup hooks
- [x] Add regression coverage for direct visual `m` entry and the real
  `m.` key path
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
