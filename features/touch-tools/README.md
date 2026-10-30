# Touch Tools

Replaces **Touch Speed**: disable/remove that old mod before enabling this one.

Install `exports/shared/touch_tools.zip` in gen1recomp's Mods screen and enable
**Touch Tools**, then restart the game. One mod supports Red/Blue/Yellow and
Gold/Silver/Crystal; no engine rebuild, voxel mod or companion is required.

Tap the native **…** button in the upper-right corner for a compact vertical
menu. Nothing floats in the middle of the game. The panel stays inside the
safe area in portrait and landscape; tapping outside closes it.

- **SPEED** switches between real 1x and native 4x fast-forward.
- **SAVE / LOAD** use native quick save/load and their normal safety guards.
- **COLOR** cycles the native display palette.
- **ZOOM + / −** adjust the active survey, third-person or battle camera.
  First person adjusts the lens without replacing companion effects. In 2D,
  these use native zoom steps.
- **VOXEL** appears only with gmarcs_gen2_voxel_mod, GEN2_VOXEL or Dramatic Shape and cycles
  **3D → 1ST → 3RD → 3D**. It saves the normal renderer preferences and respects
  cutscene/warp gates. Without a voxel renderer this row offers native **TILT**.

Controls hide with the native touch interface, during layout editing and when
its controller visibility rules apply. Custom touch skins retain their own
controls. Native link/minigame speed locks remain authoritative. Dragging off
a row cancels the action; menu touches never reach camera gestures. Speed and
first-person lens changes last for the session. Disabling this internal-wrapper
mod takes effect on restart.

## Development

`luajit tests/test_corner_menu.lua` and `luajit tests/test_touch_tools.lua` check toggling, native locks, touch ownership,
multi-touch, cancellation, rotation, and visibility. Run `tests/live.lua` through
`POKEPORT_DRIVER` with `POKEPORT_TOUCH=1` against disposable imported profiles
to check the real engine callbacks and capture portrait/landscape UI.

Release 1.2.0: desktop touch probes passed in Red, Gold, Silver and Crystal,
including speed locks, native corner taps, mode changes, lens zoom and actual
quick save/load in disposable profiles. Portrait/landscape captures inspected.
These checks do not substitute for testing on a physical Android device.

The corner menu also opens VOXEL SETTINGS for the active renderer's own option
schema. Renderer discovery accepts the exported library as well as known IDs,
so a renderer rename does not disconnect the controls.
