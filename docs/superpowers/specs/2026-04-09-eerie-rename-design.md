# Eerie Hard Rename Design

## Goal

Rename the package identity from `meow` to `eerie` everywhere that
defines the shipped Emacs package surface.

After this change, the canonical entry point must be:

```emacs-lisp
(require 'eerie)
(eerie-global-mode 1)
```

There will be no compatibility layer for `meow`.

## Chosen Approach

Use a full hard rename in one pass:

- rename every shipped `meow-*.el` file to `eerie-*.el`
- rename `meow.el` to `eerie.el`
- rename every `meow-*` Lisp symbol to `eerie-*`
- rename every provided and required feature from `meow*` to `eerie*`
- update package metadata, tests, and canonical docs to the new name

This is intentionally a pure identity rename, not a behavior redesign.

## Scope

### Code Surface

- File names
  - `meow.el` becomes `eerie.el`
  - every `meow-*.el` module becomes `eerie-*.el`
- Emacs feature names
  - `(provide 'meow)` becomes `(provide 'eerie)`
  - `(require 'meow-foo)` becomes `(require 'eerie-foo)`
- Lisp symbols
  - all public and internal `meow-*` functions, variables, faces, modes,
    commands, and helpers become `eerie-*`
  - all internal state symbols such as mode-state predicates and local
    vars follow the same rename
- Package metadata
  - package name in `Eask`
  - package header and metadata in the entry-point file

### Verification Surface

- rename the test file and test package requires to `eerie`
- keep the shipped behavior identical after the rename
- keep the current ERT suite as the behavioral contract, only changing
  names and paths as required by the rename

### Documentation Surface

- update `README.md` to use `eerie`
- update `AGENTS.md` to use `eerie`
- update `.plan/PLAN.md` and new stage tracker files to describe the
  rename work
- update the interactive smoke instructions and test helpers to use
  `eerie`

## Explicit Non-Goals

- no compatibility aliases such as `(provide 'meow)` or `defalias`
  wrappers from `meow-*` to `eerie-*`
- no git remote rename
- no local checkout directory rename
- no behavior changes beyond what is required to keep the renamed
  package loading and working
- no attempt to rewrite historical process documents whose purpose is to
  preserve the earlier cleanup record

## Rename Rules

### Public Package Contract

After the rename:

- users load the package with `(require 'eerie)`
- users enable it with `(eerie-global-mode 1)`
- customization helpers become `eerie-normal-define-key`,
  `eerie-visual-define-key`, `eerie-leader-define-key`, and
  `eerie-register-jump-command`

### Module Graph

The repo must load through `eerie.el` only. The old `meow.el` entry
point must not remain in the tree.

Each renamed module must:

- keep its original responsibility
- update its file header to match the new filename
- update its `require`, `provide`, and `declare-function` references to
  the renamed modules and symbols

### Docs And Test Contract

The canonical docs and the ERT suite must describe `eerie`, not
`meow`.

The tests should continue to prove the same modal workflow, but under
the renamed package and symbol surface.

## Risks And Controls

### Risk: Partial rename leaves broken load graph

Control:

- treat the entry-point file and module `require` / `provide` graph as a
  single rename unit
- add a failing load-path regression before implementation

### Risk: Symbol rename breaks tests in subtle ways

Control:

- keep the existing behavioral assertions and only change the symbol and
  file names needed to load the renamed package
- run the full suite after the rename

### Risk: Docs lag behind shipped package name

Control:

- update `README.md`, `AGENTS.md`, `.plan/PLAN.md`, and the active stage
  file in the same change set

## Success Criteria

The rename is complete when all of the following are true:

- the package loads with `emacs -Q --batch -L . -l eerie.el`
- the ERT suite loads and passes from the renamed test file and renamed
  package entry point
- there is no shipped `meow` package surface left in the repo
- `README.md`, `AGENTS.md`, and `.plan/*` describe `eerie` as the
  canonical package name
- no compatibility alias layer remains
