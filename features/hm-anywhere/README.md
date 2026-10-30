# HM Anywhere (Gen 2)

Start → HM lists owned HMs and HM moves already known by a party member. Owning the HM lets a living party member perform it without learning it; normal badge and map requirements remain. Flash uses the engine’s current darkness context. Move names follow the active language. Supports Gold, Silver and Crystal; install hm_anywhere_gen2.zip.

Validation: `luajit tests/runtime.lua`; native PackMenu teaching and Start-menu Flash exercised by `mods/gen2/voxel-runtime/tests/gen2_gameplay_repair_probe.lua`.

Version 1.0.2 delegates contextual target and badge checks to the native Gen 2
dispatcher. Owning Cut without the Hive Badge no longer intercepts unrelated
interactions. The menu badge refusal uses the native Spanish catalog key.

Version **1.0.3** keeps Strength on the native boulder-NPC interaction path.
The native Strength prompt assumes its caller already found a boulder, so it
is no longer polled against empty floor, water, signs or doors. Badge checks,
manual HM-menu activation and native boulder scripts remain unchanged.
The live driver also owns Strength while checking empty indoor interactions
and native fishing nibble/bite messages with GEN2_ES enabled.

Version **1.0.4** fixes Fly city selection leaving the start menu open. It
uses the native Fly-map callbacks, queues the chosen flight, applies the
field fade and closes menus before the world runs the flight animation.
Cancel leaves the start menu available. `tests/runtime.lua` covers both
callbacks; `tests/fly_live.lua` opens the real Start → HM → Fly map, cancels,
reopens, selects Cherrygrove and verifies arrival with an empty menu stack.
The live flow passed on Gold, Silver and Crystal in disposable profiles,
without writing saves. Physical Android was not tested.

Version **1.0.5** extends automatic menu exit to CUT, SURF, STRENGTH, FLASH,
WATERFALL and WHIRLPOOL. Successful actions preserve the engine's queued field
script, apply its normal menu-exit fade and clear Start/HM menus so the world
can run the effect. Refused actions retain their menu/error context. Fly keeps
its existing destination/cancel flow. `tests/runtime.lua` checks all seven HMs;
`tests/menu_live.lua` exercises native Flash and Strength through Start → HM.
Native Flash/Strength completion and Fly cancel/arrival passed on Gold, Silver
and Crystal in disposable desktop profiles with GEN2_ES enabled. The Flash
capture confirms the world is visible again with no menus. No physical
Android testing was performed.

Version **1.1.0** adds owned field-use TMs: **Rock Smash, Headbutt, Dig and
Sweet Scent**. They appear in Start → HM without being taught and are never
consumed by field use. Learned Teleport appears there too (there is no native
Gen 2 Teleport TM). Native target, location and badge rules still apply. Rock
Smash uses the original object script and its real target; native contextual
rock/tree scripts recognize owned TMs through the same eligibility hook.
Softboiled and Milk Drink retain the native party HP-transfer interface.
Long translated labels fit a wider menu; eight visible rows scroll when needed.

This uses native machine metadata and move IDs, so GEN2_ES, Useful Bag,
Moveset Plus and Reusable Machines keep their normal names, teaching and
inventory behavior. `ownedHM` remains HM-only for existing integrations;
`ownedMachine` also exposes supported field TMs to companion mods.

1.1.0 release verification: native Gold Start → HM lists all four field TMs;
Rock Smash removes Cianwood's real rock with a Tackle-only party and preserves
both the TM inventory and learned moves. GEN2_ES, Useful Bag, Moveset Plus,
Reusable Machines and Widescreen Menus were loaded. Native Flash/Strength
completion and Fly cancellation/arrival also passed. Unit checks cover every
new action, eligibility, native Rock Smash script targeting and menu scrolling.

## Translation ownership

English source text stays in this mod. Spanish UI is supplied by GEN2_ES
through the engine string registry, in the `hm_anywhere_gen2` context. Native
move/item/type names and descriptions still come from localized game data.
Missing translations fall back to English. No Spanish dictionary or check
for a particular language mod is embedded here.
