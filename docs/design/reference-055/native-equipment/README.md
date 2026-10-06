# Native PBR equipment finish, quality pass 055

The actual native PBR materials now receive the equipped rarity accents. The
hidden legacy mesh is not used as an appearance proof. One helper belongs to
each actor; visible body, accessories and held weapons get independent material
overrides while retaining the original texture, mesh and skin resources.

| Slot | Arcanist | Vowkeeper | Ranger |
| --- | --- | --- | --- |
| Weapon | Existing held staff | Existing held sword | Existing held bow |
| Helmet | Bronze forehead circlet | Existing steel shoulder protection | Native hood |
| Chest | Coat bodice, facing and split tails | Native torso and fitted breastplate | Native torso and shoulder garment |
| Gloves | Existing bronze shoulder protection | Existing fitted steel bracers | Native bracers |
| Boots | Native footwear | Native footwear | Native footwear |
| Amulet | Existing gem and bronze garment bindings | Native belt details | Native belt details |

The unhooded Vowkeeper has no separate native helmet, and Arcanist has no
separate glove mesh. Those two ranks are echoed on the existing upper/arm armor
listed above. No helmet, glove, jewelry or replacement body geometry is added.
Ranger's exposed-hand material, and every class's actual skin, face, hair,
eyebrows and eyes, remain unchanged.

The six observed slot groups are independent. Higher ranks add restrained
multiplicative pigment accents and at most 0.032 roughness polish; dark cloth
keeps its original lightness. Metallic values, emission and all texture
references remain unchanged. Common and unequip restore the exact original
styled albedo and roughness from a stable per-actor baseline, so repeat equip
operations cannot accumulate tint or polish. The helper adds no lights,
geometry, shader passes or material next passes.

The real native consumer suite passed **129 checks, 0 failures**, with actual
Godot process exit 0. `smoke.log` includes the 129 successful assertions covering
all three classes and six slots, exact Common/unequip restores, repeats, Rare
versus Legendary, unchanged source geometry/skin/textures and human features,
peer isolation, actual live `HeroArt` portrait isolation, and class switching.
`receipt.json` records helper/test and log hashes. This is a headless material
and ownership proof, not a perceptual screenshot comparison or device benchmark.
