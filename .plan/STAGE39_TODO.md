# Stage 39 TODO

## Goal

Remove obsolete old-flow assumptions and sync the repo docs and tests to
the new canonical multicursor mode.

## Tasks

- [x] Remove or repurpose stale old-flow helpers, bindings, and short
  names
- [x] Update README to describe normal `m`, `.` / `,` / `-`, and the
  persistent multicursor menu
- [x] Update AGENTS and `.plan/PLAN.md` to reflect the shipped redesign
- [x] Update the interactive demo buffer for the new flow
- [x] Add regression coverage for exit behavior, state transitions, and
  direct normal-mode edits of promoted marked targets
- [x] Add regression coverage for the real `m w .` builder path so it
  keeps the marked set highlighted and lets `d` consume all matches
- [x] Re-run the batch load smoke test
- [x] Re-run the full ERT suite
