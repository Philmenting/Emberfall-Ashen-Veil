# Store assets for 0.40

- `icon-512.png`: existing original game icon, 512×512 PNG.
- `feature-graphic.png`: 1024×500 RGB PNG; a Godot brand composition using the actual painted dungeon, Nyra and Bell Warden.
- `screen-01-classes.png` through `screen-04-loot.png`: 1280×720 RGB captures of the actual English game UI and regular combat values.

These are renderer captures, not a claim that a physical Android device was tested.
No equipment, player health or combat numbers were inflated for the store scenes.
The paused guardian frame is reached by advancing the same normal first expedition.
The separate `.impeccable/review` and Android art fixtures use extra Life for late-region inspection and are excluded from this store set.

The 16-second `docs/previews/success-loop/emberfall-gameplay-040.mp4` is exported from 384 actual gameplay frames at 24 FPS, with editorial cuts through travel and the later phase. It shows camp, the first fight, the first guardian, its final phase and earned relic. The original game score is mixed into the export; captured combat sound effects are not claimed. This is a deterministic source export, not an Android screen recording or device frame-rate measurement.

Re-render with Godot 4.7.2:

```sh
godot --path . tests/store_graphic.tscn
godot --path . tests/beta_preview.tscn -- --capture-dir=/absolute/path/to/captures
```

Copy the 1280×720 welcome, expedition, guardian and loot captures to the four screenshot files. The source icon is `assets/app_icon.png`.
