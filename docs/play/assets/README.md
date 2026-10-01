# Store assets for 0.39

- `icon-512.png`: existing original game icon, 512×512 PNG.
- `feature-graphic.png`: 1024×500 RGB PNG; a new Godot composition using the actual dungeon, Nyra and Bell Warden.
- `screen-01-classes.png` through `screen-04-loot.png`: 1280×720 RGB captures of the actual English game UI and regular combat values.

These are renderer captures, not a claim that a physical Android device was tested.
No equipment, player health or combat numbers were inflated for the store scenes.

Re-render with Godot 4.7.2:

```sh
godot --path . tests/store_graphic.tscn
godot --path . tests/beta_preview.tscn -- --capture-dir=/absolute/path/to/captures
```

Copy the 1280×720 welcome, expedition, guardian and loot captures to the four screenshot files. The source icon is `assets/app_icon.png`.
