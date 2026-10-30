# Pending work

## Options migration

Toggles saved under the standalone mod ids do not carry over: option keys are
now `<feature>.<key>`. A migration would copy the old per-mod buckets into the
new keys on first load.

## On-device verification

The pack is load-tested against the engine modules and its feature tests pass,
but it has not been played through on hardware. Installing it means disabling
the standalone mods it replaces first, since duplicates would double-wrap every
hook (the manifest conflicts with them, so the launcher refuses the pair).

## Gen 1 pack

A Gen 1 counterpart can reuse this assembly unchanged: same `sources.json`
shape, same assembler, same proxy. It needs its own `manifest.json` and its own
source list; the sources it would draw on already exist as separate mods.
