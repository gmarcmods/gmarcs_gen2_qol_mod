# Happiness (Gen 2)

For Gold, Silver and Crystal. Open Bill's PC and choose **HAPPINESS** to set
the first Pokémon in your party to maximum happiness (255), for free.
Only the first slot changes. Eggs are refused. Save the game normally to keep
the change; ordinary gameplay can lower happiness again.

With the updated GEN2_ES enabled, the option is **FELICIDAD** and messages are Spanish.
The language mod owns that wording; Happiness reads the public string registry
and falls back to English without a translation. No locale detection is needed.
No dependencies or special permissions. Install the individual
`happiness_gen2.zip` through the engine's mod manager and enable it.

Checks: `luajit mods/gen2/happiness/tests/runtime.lua` from the workspace.
Live driver: `tests/live.lua`, using a disposable identity without saving.
Verified in the desktop engine on Gold, Silver and Crystal, including Spanish
on Gold/Crystal. Physical Android testing has not been performed.
