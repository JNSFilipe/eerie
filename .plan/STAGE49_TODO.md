# Stage 49 TODO

## Goal

Rename the package entry point and module graph from `meow` to `eerie`
so the renamed package loads again.

## Tasks

- [ ] Rename `meow.el` to `eerie.el`
- [ ] Rename every shipped `meow-*.el` module to `eerie-*.el`
- [ ] Update file headers, `require`, `provide`, and `declare-function`
  references to `eerie-*`
- [ ] Update `Eask` package metadata, file globs, and test script to the
  renamed package
- [ ] Run `emacs -Q --batch -L . -l eerie.el`
- [ ] Commit the renamed module graph

## Completed

- None yet.
