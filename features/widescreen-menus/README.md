# Widescreen Menus (Gen 2)

A separate optional interface mod for Gold, Silver and Crystal. Install
`exports/gen2/widescreen_menus_gen2.zip`, enable it and restart.
No voxel renderer is required. Disable WIDESCREEN MENUS in its options to
restore the original framing.

The native control panel keeps its original pixel art, font and controls.
On landscape screens it sits beside a contextual information panel; portrait
screens stack them. Small screens fall back to the native layout. Touch-safe
playfield bounds and integer font scaling are respected.

Supported native screens: party, Pokémon summary (including SELECT move
details), Pokédex, Pokémon and item PC, pack, options, trainer card, Pokégear,
mail reading/composition and move tutor. Party and PC selection show the
selected Pokémon's information; the Pokédex respects seen/caught restrictions.
Eggs keep their hidden identity. Modal choices, naming keyboards and dialogue
keep their native placement and interaction. This is responsive framing of
native menus, not a replacement of their navigation or game logic.

Useful Bag retains its own fullscreen backpack artwork and TM/HM information.
Moveset Plus retains its five-move learning comparison. Install Moveset Plus
for accuracy in battle and native SELECT details; this mod also includes
accuracy and full descriptions in its summary detail pane. Names and move
data come from the current game/translation; supplemental GEN2_ES labels are
Spanish. Native conversations over a menu retain the responsive base.

## Connected regional maps

After the player first enters Kanto (including Route 27), Pokégear, wall maps
and Fly show both original region maps together: side by side in landscape,
stacked in portrait. Before that visit, the native regional behavior remains.
Use the normal up/down controls to browse locations across both regions; the
player marker stays on the actual region. The phone and radio still use the
player's real location.

The unlock belongs to the save slot and persists through normal game saves.
Existing saves migrate from a current Kanto location, a visited Kanto flypoint
or the Hall of Fame. Fly merges **only genuinely visited** destinations and
keeps the native confirmation, cancellation and flight callbacks. It grants
no badges, destinations or access flags. At very small resolutions, one map
is shown at a time, following the selected location. Disabling the mod restores
native regional limits and Fly lists.

## Verification

From the workspace root:

```sh
luajit mods/gen2/widescreen-menus/tests/layout.lua
```

From `gen1recomp/`:

```sh
luajit ../mods/gen2/widescreen-menus/tests/native.lua
luajit ../mods/gen2/widescreen-menus/tests/connected_maps.lua
POKEPORT_GAME=gold POKEPORT_DRIVER=../mods/gen2/widescreen-menus/tests/live.lua \
  POKEPORT_SHOT_DIR=/tmp/wide-menus-gold love .
```

Create the screenshot directory first and use an isolated Love identity with
an imported game cache. The live driver uses disposable Pokémon and does not
save. It captures fourteen menu views in landscape and portrait, plus dialogue over
a summary. Headless tests check bounds, fallback, modal composition, disabling,
and hidden-data privacy. Physical Android testing has not been performed.

Release checks (2026-10-18): Gold/Silver/Crystal passed the initial ten-view
landscape/portrait and modal suite; the final expanded fourteen-view suite
passed on Gold with GEN2_ES, Useful Bag and Moveset Plus enabled. Menus keep
the native behavior; these checks do not claim every possible gameplay flow.

Release 1.1.0: `tests/maps_live.lua` passed on Gold/Silver/Crystal with Spanish
loaded. Captures cover Pokégear, wall maps and Fly in both orientations and
both cursor regions. The probe verifies first entry on Route 27, persistence
on return to Johto, native region preservation and visited-only cross-region
Fly callbacks. It runs the native UI with the independent voxel pass disabled.

## Display density compatibility (1.1.1)

Responsive layouts use physical pixels and convert once to the engine's LOVE
window units. This supports the current engine and its previous framebuffer
coordinate contract. Pokégear cards without a combined regional map use their
native centered layout: no empty extra information panel. Single-region Fly
maps use the available screen instead of sharing space with that empty panel.
Combined Johto/Kanto maps keep both native panels at consistent physical sizes.

`tests/dpi_live.lua` exercises clock, empty phone, map and Fly before/after the
Kanto unlock at landscape/portrait sizes and 1x/2.625x density through the real
Game2 compositor. Captured native geometry must match across densities.

## Translation ownership

English source text stays in this mod. Spanish UI is supplied by GEN2_ES
through the engine string registry, in the `WIDESCREEN_MENUS_GEN2` context. Native
move/item/type names and descriptions still come from localized game data.
Missing translations fall back to English. No Spanish dictionary or check
for a particular language mod is embedded here.
