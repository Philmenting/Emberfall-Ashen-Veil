# Repository cleanup and clean-checkout validation — 053

Completed local validation on 6 October 2026 with Godot 4.7.2. The active development integration is collected in [PR #5](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5), targeting `main`.

## Cleanup and export corrections

- The root README describes the current game and rebuild/test commands. Its previous development reports are preserved in `HISTORY.md`, with their relative links intact.
- The native65 GLB embeds its textures. Twelve generated PNGs totaling 27.91 MiB, their generated import descriptors, Blender backups and editor/build caches are excluded from Git. A fresh import regenerated the twelve PNGs byte-for-byte.
- Eleven unused identity-extraction prototypes and their unused extraction tool were moved to a separate local archive with SHA-256 inventory. They had no runtime/test references. Active characters, regional props, source conversion and licenses remain included.
- All four Android export presets explicitly include `death-grounding.json`, `staff-grip053.json` and the three supplied source licenses. These `FileAccess` dependencies were previously absent from the package.
- The two remaining legacy model import descriptors now contain Godot 4.7.2's generated defaults. No original model geometry was changed by this normalization.
- CI includes both source-avatar suites, exports a resource package and checks the production rig from that package outside the checkout. Obsolete target-branch filters were removed; PR checks target `main`.
- Presentation and equipment tests inspect the eight actually visible native65 source surfaces, their skin bindings and independent PBR materials. Legacy actors retain their geometry and rarity-accent checks. Arcanist equipment statistics remain tested; imported PBR rarity tints remain unimplemented.

## Completed validation

The test checkout began without editor cache or extracted native65 PNGs. Large immutable binary assets were hardlinked to avoid duplicating source archives; import outputs and test saves were separate. The final 722 runtime/test inputs match the working source byte-for-byte.

| Check | Result |
| --- | --- |
| Fresh editor import | Exit 0; no script, parse or shader errors |
| Full isolated regression | 36 Godot suites, 3,983 checks, 0 failures; both Node checks pass |
| Exported resource package | Exit 0; actual native65 rig and runtime JSON load outside the checkout, 10 checks, 0 failures |
| Android release unit tests | 5 tests pass |
| Play source/listing check | Pass; separate publication gates still apply |
| Staged whitespace check | Pass; manufacturer license bytes remain preserved verbatim |

[Full regression log](reference-053/repository-regression.log) · [Exported resource smoke log](reference-053/repository-export-smoke.log) · [Actual staff-grip geometry evidence and limits](nyra-staff-grip-correction-053.md).

Older development PRs #2–4 are ancestors of the preserved development branch. PR #1 contains eight distinct historical prototype commits; its exact tip `1b560f1cc45cc726ce8b1d4962e121640134d47b` is preserved by the annotated [graphics archive tag](https://github.com/Philmenting/Emberfall-Ashen-Veil/tree/archive/graphics-prototype-2026-10-06). Those prototypes are not merged into the active game. All four superseded PRs are closed.

These are functional, import and resource-export checks, not an Android APK/device run or a visual Beta acceptance. Existing package version `0.48.0-beta.1` / Android code `54` remains unchanged.
