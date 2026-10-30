# Moveset Plus (Gen 2)

Move information for modern gen1recomp's Gold, Silver and Crystal, using the
native menu frames, bitmap font and active translation. No voxel mod is required.

## Install and use

Import `exports/gen2/moveset_plus_gen2.zip` through the game's Mods menu,
enable **Moveset Plus (Gen 2)** and restart. It can coexist with GEN2_ES,
Reusable Machines and the authored voxel renderer.

In battle, the move selection box shows type, base power, accuracy and current/maximum PP.
In the Pokémon summary moves page, SELECT details also show accuracy between
the native stats and description.
When learning a move with four known moves, the comparison displays all five
moves with PP, type, power and accuracy. The selected move's full description
appears beside or below the list, depending on screen dimensions.

- Up/Down: select one of the five moves.
- Left/Right: turn description pages when the full text needs more space.
- A on an old move: use the game's normal replacement process.
- A on the new move: open the game's stop-learning confirmation.
- B: return through the game's normal cancellation process.

Accuracy is displayed as `95/100`, since the native bitmap font has no percent
glyph. Power `---` follows the native summary screen convention for status or
special-damage moves. Stats are base move values, not predicted damage.

Learning callbacks remain native; HM restrictions are preserved when Reusable
Machines is disabled. The actual
Pokémon moveset never receives a fifth slot. The ordinary Move Deleter menu is
unchanged. Both field learning (including machines) and battle learning use the
comparison screen.

## Translation and rendering

Names, descriptions and type names come from the active game data at draw time.
Native string keys are reused where available; GEN2_ES receives Spanish labels
for the additional information and controls. Other translations can translate
these labels through their normal Strings mappings. Descriptions wrap and page
without truncating their content.

The battle information also appears in the voxel battle HUD. Outside learning,
the mod forwards existing renderer methods. It does not change world assets,
battle geometry, combat rules or save data.

## Development and verification

This folder owns its Git history. `main.lua` wraps the native Gen 2 battle and
learning interfaces; `lib/Info.lua` resolves stats and translations;
`lib/Panel.lua` draws responsive native-style comparison panels.

From `gen1recomp/`:

```sh
luajit ../mods/gen2/moveset-plus/tests/native.lua
python3 tools/modkit.py gen2check ../mods/gen2/moveset-plus
POKEPORT_GAME=gold POKEPORT_DRIVER=../mods/gen2/moveset-plus/tests/live.lua \
  POKEPORT_SHOT_DIR=/tmp/moveset-plus love .
```

The live driver uses test Pokémon and does not save. Use an isolated identity
with an imported game cache when running it. Desktop Gold, Silver and Crystal
were checked live in English and Spanish, including landscape/portrait
learning, paged full descriptions, native cancellation/replacement and
2D/voxel battles. Physical Android testing has not been performed.

Silver/Crystal verification (2026-10-16): both editions were freshly imported
from the user's English ROMs into isolated identities. Each ran `tests/live.lua`
once with GEN2_ES enabled and once with it disabled. All four runs completed
with `MOVESET PLUS LIVE PASS`. Screenshots were inspected for the original
Spanish labels/descriptions, native English labels and battle type/power/PP.
No runtime changes were required. The probe uses source press/release edges
and waits for fixed-tick consumption so variable render timing cannot turn a
single intended tap into a held button.


The real Backpack-to-TM flow is exercised by `tests/bag_tm_live.lua` with
Useful Bag and Reusable Machines enabled, rather than calling learnMoveOn
directly. Reusable Machines 1.0.2 fixes native HM replacement in this path;
Useful Bag 2.0.2 adds move types to TM/HM list rows. Moveset Plus's comparison
still delegates confirmation and cancellation to the native learning flow.

The Backpack integration probe passed on Gold, Silver and Crystal (desktop),
covering translated type labels in both bag layouts, party cancellation,
incompatible/already-known moves, free slots, incoming-move decline, ordinary
replacement and replacing CUT with a TM while retaining the reusable TM.

## Translation ownership

English source text stays in this mod. Spanish UI is supplied by GEN2_ES
through the engine string registry, in the `MOVESET_PLUS_GEN2` context. Native
move/item/type names and descriptions still come from localized game data.
Missing translations fall back to English. No Spanish dictionary or check
for a particular language mod is embedded here.
