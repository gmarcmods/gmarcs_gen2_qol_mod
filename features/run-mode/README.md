# Run Mode (Gen 2)

Hold or toggle B to run in Gold, Silver and Crystal. The running rules and
saved speed settings are unchanged. RUN MODE opens the engine's standard
mod-options page, also used from the mod manager, instead of a Gen 1-only
options renderer. The normal options-change event updates the running cache.

English labels remain in the schema; GEN2_ES owns their Spanish translations
in `RUN_MODE_GEN2.options`, plus the `RUN_MODE_GEN2` main-menu entry. Without
that catalog the UI stays English. No translation dependency is required.

Validation from `gen1recomp/`:
`luajit ../mods/gen2/run-mode/tests/localization.lua`.
