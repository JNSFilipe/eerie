# Changelog

## Master

### Breaking Changes

* Hard rename: the shipped package, file graph, and Lisp surface now use
  `eerie` / `eerie-*` with no compatibility layer.
* Removed the legacy Eerie keypad state/module; `SPC` now dispatches
  directly through the dedicated leader map, and native which-key
  handles leader and multicursor help discovery.

Historical entries below are mechanically rewritten to the current
`eerie-*` package surface for consistency with this fork.

The `eerie-motion-overwrite-define-key` has been changed to
`eerie-motion-define-key`, and now works like the other key binding
helpers.

## 1.5.0 (2024-10-20)

### Features
* Add `eerie-pop-to-mark` and `eerie-unpop-to-mark`
* [#644](https://github.com/eerie-edit/eerie/pull/644) Add `eerie(-backward)-kill-{word,symbol}`
* [#691](https://github.com/eerie-edit/eerie/pull/619) Add options for selecting after eerie-insert and eerie-append
* [#609](https://github.com/eerie-edit/eerie/pull/609) Allow custom delete-region, insert functions

### Enhancements
* [#650](https://github.com/eerie-edit/eerie/pull/650) Add beacon fake cursors for symbols
* [#580](https://github.com/eerie-edit/eerie/pull/580) Add shim for magit-blame-mode
* [#639](https://github.com/eerie-edit/eerie/pull/639) Add missing command in eerie-shims of wgrep
* [#581](https://github.com/eerie-edit/eerie/pull/581) Add beacon remap for eerie-change-save
* [#571](https://github.com/eerie-edit/eerie/pull/571) Clarify selection expansion by word motion
* [#637](https://github.com/eerie-edit/eerie/pull/637) Add a shim for Macrostep
* eerie-shims: add shim for ddskk (eerie-prev)
* Fix SPC SPC in motion state

### Bugs fixed
* Fix eerie-line behavior in term, eshell, etc
* Fix duplicated fake cursors in beacon backward line
* Don't reset overwrite mode when enter insert state
* [#646](https://github.com/eerie-edit/eerie/pull/646) make eerie-minibuffer-quit compatible with `(setq icomplete-in-buffer t)`

## 1.4.5 (2024-02-11)

### Bugs fixed
* [#557](https://github.com/eerie-edit/eerie/issues/557) Fix the shim code for `wdired`.
* [#546](https://github.com/eerie-edit/eerie/issues/546) Fix `eerie-back-symbol` that unconditionally reverse direction.
* [#545](https://github.com/eerie-edit/eerie/issues/545) Fix position hint before tabs with width 2.
* [#539](https://github.com/eerie-edit/eerie/issues/539) Fix beacon change with consecutive characters.
* [#373](https://github.com/eerie-edit/eerie/issues/373) Do not cancel selection when entering beacon mode.
* [#514](https://github.com/eerie-edit/eerie/issues/514) Fix eerie-esc in `emacsclient -t`.

### Enhancements
* [#517](https://github.com/eerie-edit/eerie/pull/517) Consider local keybindings when moving commands for the Motion state.
* [#512](https://github.com/eerie-edit/eerie/pull/512) Add shim for realgud.
* [#503](https://github.com/eerie-edit/eerie/pull/503) Add shim for sly.

## 1.4.4 (2023-08-23)

### Bugs fixed

* Fix keypad command display priority
* Fix global mode initialization, which causes both normal and motion are enabled

## 1.4.3 (2023-07-11)

### Bugs fixed

* [#223](https://github.com/eerie-edit/eerie/pull/223) Fix the complete behavior in `eerie-open-above` when `tab-always-indent` is set to `'complete`.
* [#290](https://github.com/eerie-edit/eerie/issues/290) Clean up beacon overlays on mode diasbling.
* [#318](https://github.com/eerie-edit/eerie/pull/318) Skip string-fence syntax class in eerie--{inner,bounds}-of-string
* [#327](https://github.com/eerie-edit/eerie/pull/327) Fix two minore issue with cursor updating.
* Fix the order of beacons for `eerie-search`.
* Fix `eerie-line` mark bug.
* Fix literal key pad bug.
* Fix `eerie-goto-line` when there's no region available.

### Enhancements

* Add a variable `eerie-keypad-self-insert-undefined`, it controls whether to insert a key when it's undefined in keypad.
* Add keyboard layouts for Colemak-DH [#284](https://github.com/eerie-edit/eerie/pull/284), FWYR [#326](https://github.com/eerie-edit/eerie/pull/326),
* [#416](https://github.com/eerie-edit/eerie/pull/416) Add visual-line versions of some Eerie operations.

### Breaking Changes

* [#209](https://github.com/eerie-edit/eerie/pull/209) Make
  `eerie-keypad-start-keys` an association list to enhance customizability.
  See [CUSTOMIZATIONS](./CUSTOMIZATIONS) for more details.
* `eerie-quit` uses `quit-window` instead of `delete-window`.

## 1.4.2 (2022-03-13)

### Bugs fixed

* [#163](https://github.com/eerie-edit/eerie/issues/163) Fix using command with Meta key bindings in BEACON state.

### Enhancements

* Update the oldest supported Emacs version to 27.1.
* [#204](https://github.com/eerie-edit/eerie/pull/204) Allow using keypad in BEACON state.
* Add "MOVE AROUND THINGs" section to `eerie-tutor.el`.
* Update `eerie-goto-line` to expand `eerie-line`.

### Bugs fixed

* Fix `eerie-mark-symbol` in BEACON state.
* [#204](https://github.com/eerie-edit/eerie/pull/204) Fix keypad in telega.
* Fix no variable `eerie--which-key-setup` error when deactivating eerie.

## 1.4.1 (2022-02-16)

### Enhancements
* Add which-key support.
* Add custom variable `eerie-goto-line-function`.
* ~~Support specified leader keymap by altering `eerie-keymap-alist`.~~
* Support specifying the target of `eerie-leader-define-key` by altering `eerie-keymap-alist`.
* Add a variable `eerie-keypad-leader-dispatch`.

### Bugs fixed

* Fix keypad popup delay.
* Fix keypad popup when C-c is bound to other keymap.
* [#197](https://github.com/eerie-edit/eerie/issues/197) Fix `eerie-kill` for `select line` selection.
* [#198](https://github.com/eerie-edit/eerie/issues/198) Fix invalid mode states with poly mode.

## 1.4.0 (2022-01-24)

### Breaking Changes

#### Keypad Refactor
The rules of KEYPAD is slightly updated to eliminate the need for a leader system.
The overall usage is basically unchanged, use same keys for same commands.

* `eerie-leader-keymap` is removed.
* A new command `eerie-keypad` is introduced, bound to `SPC` in NORMAL/MOTION state.
* Press `SPC` to enter KEYPAD state.
* Add quick dispatching from `SPC <key>` to `C-c <key>`, where `<key>` is not one of x, c, h, m, g.

Check document or `eerie-tutor` for updated information.

### Enhancements
* Improve document for word movements.

### Bugs fixed
* Eerie is not enabled in existing buffers after `desktop-read`.

## 1.3.0 (2022-01-15)

### Enhancements
* [#155](https://github.com/eerie-edit/eerie/pull/155) [#166](https://github.com/eerie-edit/eerie/pull/166) [#158](https://github.com/eerie-edit/eerie/pull/158) Add `eerie-define-state` and `eerie-register-state` to allow user define custom state.
* Remap `describe-key` to `eerie-describe-key` which handles the dispatched keybinds.
* Allow leader in beacon state(still can not switch to keypad).
* [#164](https://github.com/eerie-edit/eerie/issues/164) Add fallback support for meta & control-meta prefix in keypad.

### Bugs fixed
* [#148](https://github.com/eerie-edit/eerie/issues/148) Wrap `regexp-quote` for raw search in `eerie-search`.
* [#144](https://github.com/eerie-edit/eerie/pull/144) [#145](https://github.com/eerie-edit/eerie/pull/145) [#151](https://github.com/eerie-edit/eerie/pull/151) Improve wording in `eerie-tutor`.
* [#153](https://github.com/eerie-edit/eerie/pull/153) Avoid executing symbol-name w.r.t lambda func.
* In some cases previous state can't be stored, when dispatching to a keymap with keypad.

## 1.2.1 (2021-12-22)

### Bugs fixed
* `hl-line-mode` is not restored correctly after beacon state.
* Using `eerie-grab` in beacon kmacro recording causes residual overlays.
* [#138](https://github.com/eerie-edit/eerie/issues/138) eerie-global-mode does not work after being turned off.
* Wrong count in search indicator when searching same contents cross buffers.
* Better initial state detection.
* [#143](https://github.com/eerie-edit/eerie/issues/143) Wrong column beacon positions when secondary selection is not started with line beginning.

## 1.2.0 (2021-12-16)

### Breaking Changes

#### Changes for THING register
The built-in thing definition shipped by eerie should be more close to what Emacs gives us.
So two previously added, complex things are removed. A helper function is added, so you can easily
register new thing with Emacs things, functions, syntax descriptions or regexp pairs.

- A helper function `eerie-thing-register` is provided, check its document for usage.
- Thing `indent` and `extend` has been removed.
- Variable `eerie-extend-syntax`(undocumented) has been removed.
- Add custom variable `eerie-thing-selection-directions`.
- `eerie-bounds-of-thing` will create a backward selection by default.

### Enhancements
* Remove paredit shims, no longer needed.
* [#110](https://github.com/eerie-edit/eerie/issues/110) Only disable hint overlay for modes in `eerie-expand-exclude-mode-list`.
* Add custom variable `eerie-motion-remap-prefix.`
* Remove `dash.el` and `s.el` from dependencies.
* Add more defaults to `eerie-mode-state-list`.
* `eerie-swap/sync-grab` will grab on current position, thus you can go
  back to previous position with `eerie-pop-grab` later.
* Improve char-thing table format for thing-commands.
* Improve default state detection.

## 1.1.1 (2021-12-06)

### Enhancements
* Prevent user call `eerie-mode` directly.

### Bugs fixed
* Fix for disabling `eerie-global-mode`.

## 1.1.0 (2021-12-06)

### Features
* [#99](https://github.com/eerie-edit/eerie/pull/99) Add `eerie-tutor`.

### Breaking Changes
* rename bmacro -> beacon.

### Enhancements
* Add `eerie-expand-hint-counts`.
* Add more defaults to `eerie-mode-state-list`.
* Improve color calculation in beacon state.
* Support change char in beacon state (as the fallback behaviour for change, by default).
* Support `expand char` selection in beacon state.
* Support `kill` in beacon state.
* Add thing `sentence`, default bound to `.`.

### Bugs fixed
* Fix expand for `eerie-line`.
* Fix nils displayed in keypad popup.
* Fix C-S- and C-M-S- in keypad.
* Eval `eerie-motion-overwrite-define-key` multiple times cause invalid remap.
* Set `undo-tree-enable-undo-in-region` for undo-tree automatically.

## 1.0.1 (2021-11-30)
### Bugs fixed
* `SPC SPC` doesn't work in motion state.

## 1.0.0 (2021-11-28)
Initial release.
