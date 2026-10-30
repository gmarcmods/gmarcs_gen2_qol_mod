# Gmarc's Gen 2 QoL Mod

One installable mod for Gold, Silver and Crystal that carries twelve quality of
life features which otherwise ship separately.

Product id `gmarcs_gen2_qol_mod`.

## Install

Import the ZIP from the mod list, enable it for Gold, Silver and Crystal, then
restart. Disable the standalone mods it replaces first: the manifest conflicts
with all twelve, so the launcher refuses to run two copies of the same feature.

## Contents

| Feature | Version | Order |
| --- | --- | --- |
| Unique Menu Icons | 1.5.0 | 0 |
| Touch Tools | 1.2.2 | 30 |
| Run Mode | 1.0.1 | 40 |
| Quality of Life | 1.3.3 | 90 |
| Gen 3 Box | 1.27.4 | 100 |
| Useful Bag | 2.0.4 | 100 |
| Reusable Machines | 1.0.2 | 130 |
| Trade Evolutions | 1.0.0 | 140 |
| Happiness | 1.0.1 | 150 |
| Moveset Plus | 1.0.2 | 250 |
| Widescreen Menus | 1.1.2 | 300 |
| HM Anywhere | 1.1.2 | 610 |

Order is the ascending priority the standalone mods used, preserved inside the
pack. The pack itself loads at priority 300.

## How this repository is built

`features/`, `main.lua` and `SOURCES.json` are generated from `sources.json` by
`tools/assemble.py`, and are committed: the files that ship are readable,
diffable and blameable here.

`SOURCES.json` records each feature's source name, version, commit and a
content digest, so any build is traceable.

Rebuilding needs the twelve source mods checked out locally. They are never
committed here:

```sh
# sources.json says where each one lives inside the sources root
export QOL_SOURCES_ROOT=/path/to/checkouts
python3 tools/assemble.py            # regenerate features/ + main.lua
python3 tools/assemble.py --check    # fail if the committed tree is stale
```

`--check` regenerates into a temporary tree and compares it file by file, so the
committed copy cannot drift from the sources.

## How a feature is isolated

Each feature runs against a per-feature `mod` proxy generated in `main.lua`:

- `mod.path` and `mod:read` resolve inside `features/<name>/`
- option keys become `"<feature>.<key>"`, so twelve schemas coexist in one
  options screen without collisions
- `mod.exports` is captured per feature and merged afterwards, because several
  sources replace the table wholesale

## Declared patches

Two features gate themselves on their own export id
(`game.mods.exports.MOVESET_PLUS_GEN2`, `WIDESCREEN_MENUS_GEN2`), which does not
exist under a merged id; without a patch they would load and silently do
nothing. Those call sites are patched to the product id. The patches live in
`sources.json` and are applied only when the exact source text is present
exactly once, so an upstream change fails the assembly instead of producing a
quiet regression.

## Verification

The load test runs the generated pack against the game engine's modules and
checks that every feature installs, that option keys stay namespaced, and that
the Gen 2 catch overflow reaches box 13. Run it from an engine checkout that has
this pack inside its mods directory:

```sh
luajit mods/gmarcs_gen2_qol_mod/tests/load.lua
```

It reports the feature, option and hook counts and prints `QoL product load PASS`.

## Notes

- **Gen 3 Box** declares Gen 1, 2 and 3 support and brings its own
  per-generation branch. It also carries the catch fix: a ball is thrown into
  the next box with room when the party is full and the box the game looks at
  is full, so the throw is refused only when every box really is full.
- **Quality of Life** contributes only `DEVICE CLOCK` here; its Pack and EXP bar
  are Gen 1 replacements and stay inert on Gen 2.

## Known limitations

- Verified by the load test and by targeted feature tests; not yet played
  through on hardware.
- Toggles saved under the standalone mod ids do not carry over, because option
  keys are namespaced to the pack. Set them once after switching.
- The pack ships only what `scripts/export-mods.py` packages. Screenshots and
  other per-source material stay in the source repositories.
- No ROMs, saves or imported asset packs are ever included.
