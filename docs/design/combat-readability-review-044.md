# Combat readout finish review · 0.44

The user requested our strongest further improvements implemented directly.
This extension keeps the approved monumental painted world and animated 3D
figures, while making automatic skills, protection, damage and room progress
readable and providing a safe inspection pause.

The fresh, read-only Impeccable finish reviewer returned **disposition: ship**
for this extension. It opened all 27 native PNGs at original resolution and
sampled video frames 0000, 0149, 0155, 0220, 0240, 0300 and 0359.

| Reviewed behavior | Result |
| --- | --- |
| Typography, Large Text, materials and ink grounds | Match the incumbent system at all three sizes |
| Equipped skill state, cooldown, low Mana and casting | Match actual simulation values |
| Guard, Ward and chamber progress | Match; remaining foes include scheduled reinforcements, while the existing PACK ALIVE count includes spawned enemies |
| Rule inspection, Close, Back and Resume | Reachable and coherent; prior manual pause and saved intent are preserved |
| Inspection stops progression | Frames 0155 and 0220 are pixel-identical; subsequent sampled frames progress after Resume |
| Health feedback | Life changes immediately; healing clears the trace, inspection freezes it and Reduced Motion removes its movement |
| Camera and warning clearance | Inspected figures and warning footprints stay above controls |

The reviewer found no material regression attributable to the extension and
requested no fixes. This is a scoped UI/presentation review against the
incumbent DESIGN.md, without a newly approved comp or QUALITY BAR. Godot,
Mesa and Xvfb provided the evidence; the review does not certify physical
Android performance or the overall game's readiness for a public beta.

The local existing 31-suite regression passed all 3,455 checks, and the new
readability suite passed 57 checks, including cold restart from both active
and manually paused inspections. A narrow post-capture persistence correction
uses the same prior active intent for warm AFK resume and cold loading. Its
four additional checks compare full checkpoints after twelve seconds away;
no foreground or rendering behavior changed. The same reviewer confirmed this
narrow source correction with disposition `ship`; it did not reopen the visual
review or rerun the tests. Provenance retains the exact capture
source hashes separately from the final reviewed-source hashes. Five Android release-verifier unit tests
also passed. CI repeats all 32 suites together for the final commit; Android
runtime QA now exercises skill inspection and Back before the existing
first-clear, inventory, oath and restart flow.

[Implementation and reproduction](../COMBAT_READABILITY_044.md) ·
[capture provenance](../previews/combat-readability/provenance.json) ·
[final commit CI and downloadable packages](https://github.com/Philmenting/Emberfall-Ashen-Veil/pull/5)
