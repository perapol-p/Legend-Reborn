# Placeholder weapons
LMB attacks. 1-5 selects sword, katana, gun, bow, spellbook. T summons/replaces one 100 HP training dummy. The arena starts empty. Knight/Ninja use their catalog weapon; unassigned characters start with sword for testing.

Replace Model children in scenes/weapons/*.tscn with imported art. arms.tscn is shared across all five weapons. Preserve scene roots and camera-relative coordinates (-Z forward, Godot units). These models are blockouts, with procedural swing/recoil animations; skeletal animation can be added later.

scripts/weapon_combat.gd contains WEAPONS tuning and attack logic. Damage scales with ATK/critical stats. Hits feed combo; kills give 3 XP once. Melee checks a forward arc, range and obstruction. Gun uses hitscan. Bow and spellbook launch swept-collision projectiles. Pausing freezes combat; cursor release cancels pending strikes. Switching retains cooldown and cancels pending strikes.

Damageable bodies implement take_damage(amount): 0 ignored, 1 damaged, 2 killed. Optional aim_point() returns a world-space melee aim point. World/targets use collision layer 1.

Run scenes/test_weapon_combat.tscn headlessly for integration tests. Add -- --preview with a rendering display to save previews to backups/weapon_*.png.

