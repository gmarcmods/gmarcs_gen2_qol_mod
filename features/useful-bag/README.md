# Useful Bag (Gen 2) 2.0.3

For modern gen1recomp running Gold, Silver or Crystal. This replaces the old
Gen 1 based port with enhancements to the native `src.ui.gen2.PackMenu`.

- Keeps the four original pockets: Items, Balls, Key Items and TM/HM.
  Native item attributes determine the pocket; there are no hand-maintained
  medicine/ball classification lists.
- Raises each pocket's capacity to 999 distinct items, and bag stacks to 999.
  Native shops, script gifts, held-item returns and PC withdrawals all call
  the same modified bag admission function. Shop quantity selectors still
  buy at most 99 per transaction; repeated purchases can reach 999.
- START opens sorting by name or quantity. Works with keyboard/controller
  START bindings and Android's on-screen START. SELECT still performs the
  native manual reorder. Left/Right changes pockets.
- Fullscreen bag enabled by default, retaining the original backpack picture,
  patterned sidebar and pocket plaque for the active edition/pocket. It uses native bitmap fonts, translated
  item names and descriptions, fills the available playfield and shows more
  rows in portrait orientation. It respects the engine's touch-control area.
- Disable FULLSCREEN BAG MENUS in this mod's options to use the native pack
  graphics/layout. Very small playfields also use that compact layout.
- Native use/give/toss/register, TM teaching, battle item use and chooser
  callbacks remain the engine's implementation. Catch-tutorial menus are
  untouched. Sorting never opens during an item action/message/reorder.
- Additional sorting/navigation labels appear in Spanish with GEN2_ES.

PC storage capacity/layout are the game's native ones; this version does not
claim to enlarge the PC. The mod supplies no items and does not make TMs
reusable. Expanded inventory is intended for gen1recomp saves; original
cartridge save export remains subject to cartridge pocket/quantity limits.

## Install

Import `exports/gen2/useful_bag_gen2.zip` using the engine's Mods menu, enable
**Useful Bag (Gen 2)** for your game, then restart. Check that the displayed
version is **2.0.3**. Existing inventory and save layout are preserved.

## Development and verification

This folder owns its Git history. The original 1.0.0 source is retained in the
baseline commit. `gen1recomp/mods/useful_bag_gen2` links to this folder for
local testing; installed copies can shadow a development source.

From `gen1recomp/`:

```sh
luajit ../mods/gen2/useful-bag/tests/native.lua
python3 tools/modkit.py gen2check ../mods/gen2/useful-bag
```

`tests/live.lua` runs on an imported native game, verifies the loaded exports,
adds 60 distinct items to each pocket, checks 999 stack admission/rejection,
makes a native mart purchase and native PC withdrawal, and captures real
landscape/portrait, sorting and quantity dialogs. Its injected inventory is
held in a separate save table; it does not write a save. Set POKEPORT_SHOT_DIR
to an existing directory and POKEPORT_DRIVER to that file when launching Love.

Validated live on Gold, Silver and Crystal with gmarcs_gen2_voxel_mod, Johto in First
Person, GEN2_ES, HM Anywhere and Reusable Machines loaded. Screenshot checks
are desktop Love checks, not physical Android-device validation.

Build the individual ZIP from the workspace root:

```sh
scripts/export-mods.py useful_bag_gen2
```

The 2.0.3 artwork restoration was visually checked in native Gold in landscape
and portrait, including pocket switching. It calls the engine's PackGfx
methods at their original tile coordinates to preserve native palettes.


Version 2.0.2 shows each TM/HM move's native translated type in compact and
fullscreen lists. The type occupies the second line, with quantities kept
separate. The native Backpack → party → move-learning flow is covered by
`../moveset-plus/tests/bag_tm_live.lua`, including cancellation, incompatible
Pokémon, already-known moves, free slots, declining/replacing moves and HM
replacement with Reusable Machines 1.0.2. Moveset Plus remains optional.

The 2.0.2 integration passed on Gold/Silver/Crystal with Moveset Plus, Reusable
Machines and the voxel mods loaded. English/Spanish type rows were visually
inspected in compact, fullscreen landscape and portrait views. These are
desktop Love results, not physical Android-device tests.

Version **2.0.3** keeps the fullscreen backpack behind native TM teaching
text and yes/no prompts. The widescreen base is no longer redrawn as a
compact pack during the dialogue overlay pass. Selected TMs/HMs show native
power, accuracy (percentage value) and base PP in the detail area, in both
compact and fullscreen layouts; type remains on the list row and the move
description is retained. PWR/POT is power, ACC/PRE is accuracy; `--` denotes
status/variable power or unavailable accuracy. Labels follow GEN2_ES.
The fullscreen list reserves space for these details even in small windows.

`tests/tm_flow_live.lua` exercises party cancellation, incompatible/known
moves, free-slot learning, declining/replacing a fifth move and reusable
TM/HM behavior. It also captures the four-move dialogue in landscape and
portrait and rejects a compact base repaint. Passed on Gold/Silver/Crystal
with Moveset Plus, Reusable Machines, GEN2_ES where enabled, and voxel mods.
Final Gold captures include a damaging TM and the corrected artwork/footer
spacing. These checks use desktop Love; physical Android remains untested.
