# Reusable Machines (Gen 2)

TMs remain in the bag after successful native move teaching. Ordinary items still consume normally, and explicitly tossing a TM still removes it. The mod also permits forgetting HM moves. Supports Gold, Silver and Crystal; install the individual reusable_machines_gen2.zip.

Validation: `luajit tests/runtime.lua`; native PackMenu teaching and Start-menu Flash exercised by `mods/gen2/voxel-runtime/tests/gen2_gameplay_repair_probe.lua`.


Version 1.0.2 connects forgettable HMs to the modern native
PackMenu → Game2.learnMoveOn → MoveDeleter teaching path. The earlier legacy
MoveLearnMenu adapter did not reach that path, so replacing CUT/SURF/etc.
was still refused when using a TM from Backpack with Moveset Plus enabled.
The native confirmation is adapted only while this mod is active; the old
move's identity and temporary definition are restored even if a callback
fails. The move list never gains a fifth slot. Native learning callbacks,
translated names and TM retention are preserved.

From `gen1recomp/`, `luajit ../mods/gen2/reusable-machines/tests/native_learning.lua`
checks the actual native controller together with Moveset Plus. The full
Backpack interaction driver is `../mods/gen2/moveset-plus/tests/bag_tm_live.lua`.

The native Backpack teaching probe passed on Gold, Silver and Crystal with
Moveset Plus and Useful Bag enabled. It checks refusal/cancel/direct learning,
replacement including an HM slot, and retained TM quantity. Native-controller
headless checks also cover callback errors and disabled-mod HM restrictions.
