# Pending work

## Gen 1 QoL product

The Gen 1 counterpart will reuse this assembly. Sources already in the
workspace: `mods/gen1/{hm-anywhere,reusable-machines,run-mode,useful-bag,unique-menu-icons,gen3-box,modern-bag,move-relearn}`
plus `mods/shared/{touch-tools,quality-of-life}`.

Still to fetch: nothing known — the phone's remaining mods (Pokémon Bank,
Multiple Save Slots) were deliberately dropped from scope.

## Options migration

Toggles saved under the old separate mod ids do not carry over: option keys are
now `<feature>.<key>`. A migration would copy `options.modOptions[<old id>]`
into the new keys on first load.

## On-device verification

The product is load-tested against the real engine modules but has not been
played on hardware. Installing it means disabling the individual mods it
replaces first, since duplicates would double-wrap every hook.
