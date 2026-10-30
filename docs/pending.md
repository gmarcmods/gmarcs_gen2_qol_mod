# Pending work

## Gen 3 Box for Gen 2

`gen3_box` (upstream `MadeinTaly/gen1recomp-gen3-boxes`, currently 1.3.0 on the
phone, 1.8.0 in the mod index) is a Ruby/Sapphire-style storage screen built on
Gen 1's twelve boxes of twenty, `src.pokemon.Boxes` and `src.ui.Screens`. It has
no `games` field and no generation branch, so it cannot join this product as
it stands.

To include it the screen has to be ported over Gen 2's native PC boxes:

- source of truth for the box model (Gen 2 box count, capacities, cursor and
  party transfer rules)
- the per-species pic lookup used for the grid, which differs between
  generations
- the start-menu and Pokemon Center entry points in Gold/Silver/Crystal
- options (`OPEN FROM`) and the strings used by the port

Until then it stays a Gen 1 mod and belongs in the Gen 1 QoL product instead.

## Gen 1 QoL product

The Gen 1 counterpart will reuse this assembly: sources already in the
workspace are `mods/gen1/{hm-anywhere,reusable-machines,run-mode,useful-bag,unique-menu-icons}`
plus `mods/shared/{touch-tools,quality-of-life}` and `gen3_box`.

Installed on the phone but not yet in the workspace: Move Relearn
(`ShaneMcGovernIE/relearn_moves`), Multiple Save Slots
(`masterwebx/gen1recomp-multi-save-slots`), Gen1ModernBag
(`wild1walker/Gen1ModernBag`), Gen1BillsBox (`wild1walker/Gen1BillsBox`).
Fetch and vendor them before that product is assembled.
