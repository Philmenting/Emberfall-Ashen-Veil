# Combined oaths and guardian phases — 0.40

Prepare one or two oaths at the camp table. The expedition freezes its class, equipped stats, oath rules and guardian rules at departure. Changing preparation does not rewrite a running expedition. Its actual costs and rewards appear in the table and combat controls.

| Oath | Risk | Reward and synergy |
| --- | --- | --- |
| Unmended | Healing from Guard, signature skills and wells is disabled. | +30% gold/XP and an additional Rare drop. New oath runs gain 15% damage while Guard is active; Vowkeeper accumulates its guard reserve faster. Protective class skills and Bastion gear offer a different route to survival. |
| Cinder | Enemies deal 25% more damage. | A guaranteed Epic class amulet, 15% more damage from damaging techniques and 25% stronger class effects. Cinder equipment adds critical chance. |
| Hollow | Mana costs rise 35%. | +20% gold/XP and technique cooldowns are 20% shorter. Tide equipment reduces technique costs; Veil equipment further reduces technique cooldowns. |

Currency bonuses add: Unmended + Hollow gives +50% gold/XP. Each extra drop is awarded once. Every pair retains both risks; selecting all three is rejected. Legacy single-oath checkpoints retain the exact original rules, without receiving new combination buffs.

All four guardians change at two-thirds and one-third Life. The threshold crossing cancels the old warning and starts the next phase's geometry. The same circle, annulus and lane definitions drive damage, automatic escape and the rendered footprint.

| Guardian | Phase 1 | Phase 2 | Phase 3 |
| --- | --- | --- | --- |
| Bell Warden | Crowned Vigil: ring with a safe center. | Crown Break: ring plus a lane through its center. | Final Toll: overlapping split rings plus a final cleave. |
| Silt Abbot | Low Water: tide lane or cross-current. | Broken Levee: parallel currents with a gap. | Black Undertow: drowning ring and crossing current. |
| Mourning Queen | Dormant Roots: three graves in a row or line. | Grief in Bloom: triangular grave formation. | Grave Convergence: outer ring and central eruption. |
| Cinder Sovereign | Banked Furnace: crossing lanes. | Riven Forge: cross and central fireball. | Ashen Overload: ring and narrow cleaves. |

Watch, skip, restart and offline repeat use the same simulation. A combined-oath repeat retains the departure stats, class and rules across a cold restart until the player explicitly changes preparation or ends oath farming at the table. Independent farming retains its separate chosen goal. In-progress older saves are not assigned new phase flags.

`combined_oaths_phases_smoke.gd` checks strict contract encoding, every pair, rewards, technique costs, phase boundaries, warning reconstruction, watch/skip/offline parity and 24 immutable legacy checkpoint outcomes. `main_combined_rules_smoke.gd` checks the actual UI/factory, cold saves, repeat context and reward protection. `world_framing_smoke.gd` projects every guardian phase/variant outline through the camera at closed Fold, open Fold and compact layouts without modifying the simulation.
