# Quality of Life

Locally maintained fork. Install `exports/shared/quality_of_life.zip`.
On Gold/Silver/Crystal this mod leaves the native Pack, EXP bar and field
prompts in control; its Gen 1 replacements are not installed. Upstream
auto-updates are disabled to preserve local fixes. See [maintenance notes](docs/maintenance.md).

Quality of Life adds optional conveniences and a Gen II-style Pack while
leaving the original maps, saves, item effects, and engine files unchanged.

## Gen II battle EXP bar

The player's battle HUD includes Generation II's eight-tile experience bar.
It shows the active Pokémon's progress from its current level to the next,
fills from right to left, animates when experience is awarded, and rolls back
to an empty bar when a new level is reached. Level 100 displays a full bar.
The track replaces the straight section of the player's HUD underline while
retaining the HUD's own arrow and corner as its ends. It therefore moves and
scales as part of that HUD, including when Dramatic Shape snaps the status
panel to a window edge. In the widescreen battle layout it expands across the
player panel rather than floating at its edge.

The fill uses the blue from Pokémon Crystal's EXP-bar palette in **OG
RED/BLUE/YELLOW**, **SGB**, **SGB INV**, and **ADVANCED** colour modes. **OG**,
**OG INV**, and **CLASSIC** draw the same bar in monochrome so blue is never
introduced into a monochrome display mode. The feature uses no copied or
generated ROM graphics.

## Gen II Pack

The Pack is divided into Item, Ball, Key Item, and TM/HM pockets. Press Left or
Right to change pockets. Each pocket remembers its cursor and scroll position,
shows five entries, and displays a description for the selected item. Press
Select to start or finish moving an item within its pocket; A also finishes a
move and B cancels it.

The layout applies both in the overworld and during battle. Gen I has no held
items, so the Gen II `GIVE` command is intentionally absent. The original Gen I
USE, TOSS, targeting, battle-turn, and capture behavior remains in charge.

### PC item storage

The Player's PC follows Gen II's two storage layouts. **Deposit Item** opens the
four-pocket Pack so items are selected from their normal pocket. **Withdraw
Item** and **Toss Item** use the PC's single 50-stack storage list with four
visible rows and a live item-description box. Quantity prompts and result
messages use the same lower text panel without covering item names.

## Field-move interaction prompts

Press **A** while facing a valid field object:

- A cuttable tree asks **Use CUT?**
- Surfable water asks **Use SURF?**
- A Strength boulder asks **Use STRENGTH?**

Choose **YES** to run the normal field move. Choose **NO** or press B to leave
the object unchanged. The shortcut only appears when a party Pokémon knows the
move and the corresponding badge has been obtained:

| Move | Required badge |
| --- | --- |
| Cut | Cascade Badge |
| Surf | Soul Badge |
| Strength | Rainbow Badge |

The mod delegates Cut and Surf to the game's existing field-move checks and
effects. Strength activates the same map-local Strength state used by ordinary
boulder pushing. It resets when the map changes, just as it does when activated
through the party menu.

## Options

Open the F10 mod manager, select **Quality of Life**, then **OPTIONS**:

Every feature is independent. Turning one option off restores the original
behavior for that feature without disabling the other Quality of Life
features.

| Option | Default |
| --- | --- |
| `CUT PROMPT` | On |
| `SURF PROMPT` | On |
| `STRENGTH PROMPT` | On |
| `GEN II PACK` | On |
| `EXP BAR` | On |

The original party-menu commands remain available whether these shortcuts are
enabled or disabled.

## Installation

Import `quality_of_life-1.3.2.zip` from the launcher's **MODS** tab, enable the
mod, and restart the game. Red, Blue, and Yellow are supported.

## Development

```bash
luajit mods/QUALITY_OF_LIFE/tests/quality_of_life_test.lua
python3 tools/modkit.py validate mods/QUALITY_OF_LIFE --strict
python3 tools/modkit.py pack mods/QUALITY_OF_LIFE -o quality_of_life-1.3.2.zip
```
