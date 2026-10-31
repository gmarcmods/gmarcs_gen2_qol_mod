# Changelog

## 1.3.0

- **All Encounters.** Routes now carry every species Gold, Silver or Crystal
  puts there, not just the running game's. A new option, `ENCOUNTERS FROM`,
  picks ALL (the three merged) or one game's lists. Vanilla still rolls first,
  so levels, rates, repels, swarms and roamers are the running game's; only the
  species changes, and scripted encounters and the Bug-Catching Contest keep
  their own tables. Rarity follows the cartridge's slot order, with a species
  keeping its best slot across the chosen games.

## 1.2.1

- Quality of Life 1.4.0 vendored (caught icon and place names). Both features
  are Gen 1 only, so Gen 2 behaviour is unchanged.

## 1.2.0

- **Menu icons are colourful by default.** The icon colour mode now defaults to
  UNIQUE COLORS instead of ORIGINAL; ORIGINAL and GBC RED are still there.
- Every option is in the pack's list with a name that says what it does, and a
  one-line explanation: box access, healing, touch, animations, wallpaper,
  slot shading, header band, cries, overworld sprites, peeking, cursor wrap,
  run mode and speed, trade-evolution levels, bag menus, widescreen and the
  device clock.

## 1.1.1

- **Menu icons, and every other feature's art, now load.** The per-feature
  proxy scoped `mod:read` but not `mod.assets`, and the engine's
  `assets:path`/`assets:image` close over the real mod root. So each feature
  looked for its art at the pack root instead of `features/<name>/` and drew
  nothing, silently. `mod.assets` is now scoped like `read`.
- Added `tests/assets.lua`: loads the pack and asserts every registered icon
  points at a file inside its own feature folder.

## 1.1.0

- **Move Relearn** added: relearn any move a Pokémon could have learned, from
  the party menu. It loads after Moveset Plus, which owns the same screens.
- The manifest now names this repository (`github`) so the launcher can check
  for and install updates, and releases ship the ZIP as
  `gmarcs_gen2_qol_mod-<version>.zip`, which is the name the updater prefers.

## 1.0.5

- **Every feature's toggles now reach the options screen.** The engine's
  `options:define` replaces a mod's schema, so each feature was overwriting the
  one before it and only the last feature's rows survived. The generated proxy
  now accumulates one schema for the whole pack (21 rows across the seven
  features that have toggles).

## 1.0.4

Packaging only.

- Vendored folders no longer carry the original mods' `manifest.json`,
  `meta.json`, `mod.card`, readme or changelog. Those files held upstream
  `github` links, and the pack ships code, art and licences, nothing else.
- The pack manifest has never had a `github` field, so the launcher has nothing
  to check or follow.

## 1.0.3

Documentation only.

- The readme now lists the features, the trade-evolution table with levels and
  the original authors, instead of build notes.

## 1.0.2

- **A Poké Ball is no longer refused when the party is full and the current box
  is full while another box has room.** Gen 3 Box hands the throw to the next
  box with room; the "BOX is full" message now appears only when every box is
  full, which is the one case the cart's rule is honest about. This is the
  pre-throw gate in `BattleState:useItem`, not the deposit.

## 1.0.1

Documentation and packaging only; the mod behaves exactly as 1.0.0.

- The readme, `sources.json` and `SOURCES.json` no longer describe an author's
  local folder layout. Rebuilding now takes a `--sources-root` (or
  `QOL_SOURCES_ROOT`) pointing at the source mod checkouts, and the load test
  resolves the pack from its own path instead of a fixed one.

## 1.0.0

First release. One install for Gold, Silver and Crystal:

- Run Mode, Useful Bag, Reusable Machines, Trade Evolutions, Happiness,
  Moveset Plus, Widescreen Menus, HM Anywhere, Gen 3 Box, Touch Tools,
  Unique Menu Icons and the Quality of Life device clock.
- Gen 3 Box 1.27.4 carries the Gen 2 catch-overflow fix: with the party full
  and BOX 1-12 full, a caught mon continues into BOX 13 and 14 instead of
  reporting that every box is full.
- Moveset Plus and Widescreen Menus are patched to recognise the product id,
  which a merged mod needs because both gate themselves on their own export id.
- Manifests declare the twelve standalone ids as conflicts, so the launcher
  refuses to run two copies of the same feature.
