# Stage 49 TODO

## Goal

Rename the package entry point and module graph from `meow` to `eerie`
so the renamed package loads again.

## Tasks

- [x] Rename `meow.el` to `eerie.el`
- [x] Rename every shipped `meow-*.el` module to `eerie-*.el`
- [x] Update file headers, `require`, `provide`, and `declare-function`
  references to `eerie-*`
- [x] Update `Eask` package metadata, file globs, and test script to the
  renamed package
- [x] Run `emacs -Q --batch -L . -l eerie.el`
- [x] Commit the renamed module graph

## Completed

- Renamed the shipped entry point and module graph from `meow*.el` to
  `eerie*.el`.
- Updated the file headers plus `require`, `provide`, and module-string
  references needed for the renamed feature graph to load.
- Updated `Eask` to package `eerie`, load `eerie.el`, glob `eerie-*.el`,
  and run `tests/eerie-vim-tests.el`.
- Verified `emacs -Q --batch -L . -l eerie.el` passes.
