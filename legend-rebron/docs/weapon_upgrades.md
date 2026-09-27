# Weapon upgrade test (reference-based)
Reference: C:/test/ref for project/Screenshot 2026-09-28 003817.png.
Use U, or Tab to release the cursor and click Weapon level up in TEST CONTROLS. Each weapon has its own level 1-5, retained when switching 1-5. New runs reset all weapon levels. This does not grant player XP or trigger item rewards.
HUD shows weapon level and the unlocked ability. MAX disables the upgrade button.

| Weapon | LV1 | LV2 | LV3 | LV4 | LV5 |
| --- | --- | --- | --- | --- | --- |
| Sword | Wide slash | Slow wave | Bigger wave | Hold LMB rapid waves | Faster rapid waves |
| Katana | Slash + dash | Pulling tornado | +50% dash distance | 2 tornadoes, 2 rounds | 3 tornadoes, 5 rounds |
| Gun | Slow fire | Fast fire | Hold/release LMB for stronger, faster burst without ammo consumption | A hit grants one RPG, RMB fires it | Explosive bullets |
| Bow | 1 arrow | 3 arrows | 6 piercing arrows | 6 upper + 6 lower arrows | No reload, hold LMB |
| Spellbook | Magic wave | Bigger wave | Tornado | RMB warp | Nuke plus 3 magic waves and tornado simultaneously |

Higher levels retain earlier features. Gun RPG storage is capped at one; RPG/explosion secondary hits do not generate another rocket. Gun has 12-round magazines and automatic reload. Charge for at least 0.45 seconds then release: automatically fire a 2-5 second powered burst where aiming still follows the mouse. Tap LMB for normal shots at LV3+. Bow has 4 volleys before auto reload through LV4. LV5 eliminates reload.

The image leaves numeric tuning unspecified. Prototype choices: sword LV5 is faster than LV4 (both table cells say rapid waves); warp 8 m / 3 s cooldown; nuke radius 8 m; RPG radius 4 m; gun bullet explosions radius 3 m. Basic attack damage continues to use ATK and critical stats, not the discarded flat +20%/level scheme.

Damage/projectile size, firing rates, pulls, penetration, ammo and collision are functional; meshes/effects are simple placeholders.
Replace art in scenes/weapons; gameplay is in weapon_combat.gd, weapon_projectile.gd and weapon_tornado.gd. UI ability text is in weapon_progression.gd.

Tests: scenes/test_weapon_upgrade.tscn exercises all 25 steps, actual hits, projectile counts, tornado rounds/pull, piercing, charge ammo, RPG consumption, splash and safe warp. -- --preview saves screenshots to backups/upgrade_*.png when using graphics.
