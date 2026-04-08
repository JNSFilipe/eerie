# Stage 37 TODO

## Goal

Replace the old visual multi-edit builder keys with the new canonical
`.` / `,` / `-` match-building flow inside `multicursor-mark`.

## Tasks

- [x] Freeze the first charwise selection inside multicursor mode as
  the immutable match seed
- [x] Bind `.` to add the next exact match of the seed
- [x] Bind `,` to remove the newest marked match
- [x] Bind `-` to skip the next exact match without adding it
- [x] Remove the old visual `m` / `;` / `s` / `n` builder path from the
  shipped keymaps
- [x] Add ERT coverage for add, repeated add, unmark, skip, and
  duplicate suppression
- [x] Update README, AGENTS, and `.plan/PLAN.md`
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
