# Cast and bow bodyphrases · 0.48

These are native authored poses on the existing 29-bone rig. No third-party
cast or bow animation was imported. The source-based Vowkeeper phrase and
its blade-floor correction are unchanged; its separate provenance remains in
[../SOURCE.md](../SOURCE.md). This work was produced by an ordinary-agent
fallback under the Impeccable asset-producer workflow.

## Change

Arcanist opens the left step while loading the right leg, coils the chest
against the pelvis, then turns the hips first into a forward left-palm throw.
The front knee catches the delivery before the return. The staff hand follows
its loaded shoulder. Signature uses the same support with a higher delivery.
`Actor.projectile_origin()` now supplies the actual casting hand to the
world's existing release call; Ranger retains its bow origin.

Ranger widens the left step, sinks into rear support and draws while the hips
resist the chest turn. After release the pull hand separates and the body
holds its support briefly. Its rise starts with the returning step, preventing
the pelvis from pulling the landed boot off the floor. The bow hand, string
and nock continue to use the shared native bindings.

Neither phrase changes simulation, actor world position, damage, cooldown,
release threshold, flight duration, camera or Reduced Motion behavior.

## Ordinary timing

The normal 300-ms attack retains its 85-ms projectile lead: native preparation
reaches its release pose at 215 ms. At 30 FPS the fixture samples that threshold
at 233.333 ms; this sample is not a changed release threshold.

| Phase | Arcanist preparation | Ranger preparation |
| --- | --- | --- |
| Gather | 0–47.3 ms | 0–51.6 ms |
| Load / draw | 47.3–81.7 ms | 51.6–154.8 ms |
| Held support | 81.7–118.25 ms | 154.8–215 ms |
| Hip-led drive | 118.25–169.85 ms | — |
| Contact approach | 169.85–215 ms | — |

The existing recovery is 340 ms. Ranger follows through for 105.4 ms, holds
support until 136 ms, returns through 265.2 ms and settles by 340 ms. Arcanist
catches the throw through 74.8 ms, returns through 265.2 ms and then settles.

## Bounded native proof

[proof.json](proof.json) records the source commit and hashes, candidate hash,
engine, exact source frames, target yaws and attack/release ages. The source
baseline is `5fe18facda9a8a8dcbd0b86e8e7eb605ce748154`; both runs used an
isolated fully imported copy of that source, Godot 4.7.2 and 1200×536 frames.
Only the hero's animation library/contact curves changed. Four 24-frame
ordinary first/guardian fights were recorded; all 96 paired camera, actor,
attack/release, life and mana rows matched exactly. Effects were hidden as
labelled QA. The comparison movie used two original-pixel views side by side,
30 FPS, 96 frames and 3.2 seconds, without resizing or slowing the action.

| Segment | Source frame range | Start / load / release / return |
| --- | --- | --- |
| Arcanist first fight | 42–65 | 44 / 47 / 51 / 59 |
| Arcanist guardian | 27–50 | 29 / 32 / 36 / 44 |
| Ranger first fight | 39–62 | 41 / 44–45 / 48 / 54–56 |
| Ranger guardian | 42–65 | 44 / 47–48 / 51 / 59 |

The root's original-pixel phase inspection approved integration: Arcanist
showed deeper loading and a changed torso diagonal; Ranger guardian showed
wider support and a distinct return. This was **not finish acceptance**.
The frozen garments and corpses still obscured knee motion in the first fight.
Combined figures, ordinary fights and effects-restored motion remain subject
to the complete review. Excursion values and functional checks are not visual
quality evidence. No performance claim comes from these concurrent captures.

The earlier live-environment exploratory capture was superseded because world
edits occurred during recording. The corrected comparison used the same
candidate with frozen environment sources; it was an evidence correction,
not a second design revision. Large raw frame trees are intentionally omitted
from the repository; their manifest and reproducible fixture are retained.

## Reproduce

Use isolated, imported copies for each desired source revision. The same
fixture can load another project through an absolute script path; that
project must contain `tests/attack_gameplay_preview.gd` and its dependencies.
The fixture advances the same normal simulation through all three classes
before capturing only the four bounded Arcanist/Ranger phrases.

```sh
XDG_DATA_HOME=/tmp/emberfall-bodyphrase-data DISPLAY=:107 \
  /path/to/Godot_v4.7.2-stable_linux.x86_64 \
  --path /path/to/isolated-source \
  --script /path/to/repo/tools/art/bodyphrase_probe_scene.gd \
  --audio-driver Dummy -- \
  --capture-dir=/tmp/emberfall-bodyphrase-proof --proof-label=SOURCE-REVISION
```

The command writes 96 native PNGs and `trace.json`; the latter contains the
exact clocks and transforms for pairwise comparison. Use a separate data and
output path for each source. The fixture retains the actual scene camera and
simulated 1/30-s steps. Renderer settling does not advance combat.

The unmodified Character suite passed all 167 checks against the scratch
candidate, including real 60-Hz support/landing, whole-skin floor clearance,
early release continuity and bow grip. Production integration passes **172 Character checks and 50 Craft checks,
0 failures**, with five additional cases for the continuous palm/bow emitter
and the real Arcanist projectile. At the observed real 60-Hz launch (frame
126), the bolt origin is exactly at the casting hand, 1.512 m from the staff
tip, with release age zero. Both fixture scripts pass native parser checks.
No existing contact or floor tolerance was relaxed.
