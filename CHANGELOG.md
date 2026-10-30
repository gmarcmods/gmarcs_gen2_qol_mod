# Changelog

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
