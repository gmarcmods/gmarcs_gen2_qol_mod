# Gmarc's Gen 2 QoL Mod

One installable mod for Gold, Silver and Crystal that carries the Gen 2 quality
of life features that used to ship as separate products.

Product id `gmarcs_gen2_qol_mod`. Assemble, verify, export:

```sh
python3 tools/assemble.py                      # regenerate features/ + main.lua
python3 tools/assemble.py --check              # fail if the tree is stale
cd ../../../gen1recomp && luajit ../mods/gen2/qol-all/tests/load.lua
python3 scripts/export-mods.py gmarcs_gen2_qol_mod
```

## This repository owns the assembled files

`features/`, `main.lua` and `SOURCES.json` are generated from the source mods
listed in [sources.json](sources.json) and then **committed**. The files that
ship are readable, diffable and blameable here; the sources stay authoritative
in their own repositories. Each feature entry chunk is copied unchanged except
for the small, declared patches in `sources.json`.

`python3 tools/assemble.py --check` regenerates into a temporary tree and fails
when the committed copy no longer matches the sources, so the checked-in files
cannot drift silently.

## Contents

| Feature | Source | Version | Priority |
| --- | --- | --- | --- |
| Unique Menu Icons | `mods/gen1/unique-menu-icons` | 1.5.0 | 0 |
| Touch Tools | `mods/shared/touch-tools` | 1.2.2 | 30 |
| Run Mode | `mods/gen2/run-mode` | 1.0.1 | 40 |
| Quality of Life | `mods/shared/quality-of-life` | 1.3.3 | 90 |
| Gen 3 Box | `mods/gen1/gen3-box` | 1.27.4 | 100 |
| Useful Bag | `mods/gen2/useful-bag` | 2.0.4 | 100 |
| Reusable Machines | `mods/gen2/reusable-machines` | 1.0.2 | 130 |
| Trade Evolutions | `mods/gen2/trade-evolutions` | 1.0.0 | 140 |
| Happiness | `mods/gen2/happiness` | 1.0.1 | 150 |
| Moveset Plus | `mods/gen2/moveset-plus` | 1.0.2 | 250 |
| Widescreen Menus | `mods/gen2/widescreen-menus` | 1.1.2 | 300 |
| HM Anywhere | `mods/gen2/hm-anywhere` | 1.1.2 | 610 |

Priority order is the ascending order the standalone mods used, preserved
inside the product. The product itself loads at priority 300 so it still lands
after the voxel mod (100) and Johto in First Person (200).

`SOURCES.json` records the source path, version, commit and a content digest
per feature, so a rebuild is always traceable.

## How a feature is isolated

Each feature runs against a per-feature `mod` proxy generated in `main.lua`:

- `mod.path` and `mod:read` resolve inside `features/<name>/`
- option keys become `"<feature>.<key>"`, so eight schemas coexist in one
  options screen without collisions
- `mod.exports` is captured per feature and merged afterwards, because several
  sources replace the table wholesale

Features that gate themselves on their own export id
(`game.mods.exports.MOVESET_PLUS_GEN2`, `WIDESCREEN_MENUS_GEN2`) would silently
do nothing inside a merged product, so those two call sites are patched to the
product id. The patches are declared in `sources.json` and applied only if the
exact source text is still present exactly once; an upstream change fails the
assembly instead of producing a quiet regression.

## Notes on two sources

- **Gen 3 Box** declares `games: ["gen1","gen2","gen3"]` at 1.27.4 and brings its
  own per-generation branch, so it runs here unchanged. The 1.3.0 release kept
  on the phone predates that support.
- Quality of Life contributes only `DEVICE CLOCK` on Gen 2; its Pack and EXP
  bar are Gen 1 replacements and stay inert, by design.

## Still open

- Options are namespaced, so toggles saved under the old separate mod ids do
  not carry over. A migration that copies `options.modOptions[<old id>]` into
  the new keys is not implemented yet.
- The product has been load-tested against the real engine modules; it has not
  yet been played on hardware with the voxel mod and Johto in First Person
  enabled.
