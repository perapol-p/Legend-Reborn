# Monster spawn test
The MonsterSpawner node in scenes/game_placeholder.tscn controls spawning.
Defaults: radius 20 m, outer radius 26 m, 4 initial monsters, continuous spawning every 2 seconds, cap 16. No waves or inter-wave breaks. Spawn batch starts at 1 and gains 1 every 10 seconds of active gameplay. New monsters start at 30 HP and gain 5 HP per 10-second step. Damage, movement speed, and attack timing use the monster defaults. Pausing freezes progression; death resets it.
Spawn centers are at least 20.6 m away horizontally so their collision capsules are outside the 20 m boundary. Positions use the player's current location and random angles; ground and free space are checked. Monsters beyond 85 m despawn.

The cyan ground ring follows the player. It marks where monsters cannot initially spawn, not a barrier: monsters can walk into the ring afterwards. Orange markers and distance labels mark the original spawn point for 2 seconds. Debug HUD shows alive count and most recent spawn distance.

B toggles debug ring, markers and spawn HUD. Set Show Debug Radius = Off in the MonsterSpawner Inspector for normal gameplay. Release exports hide all helpers automatically. Hiding helpers does not disable spawning.

Placeholder monsters chase, attack for 8 damage every 1.2 seconds in melee range, and have 30 HP. All five weapons work with them and kills grant XP/combo. Test death restores health, respawns the player and resets the encounter. The shared Model node in scenes/monster.tscn can be replaced with an imported asset later.

Run scenes/test_monster_spawning.tscn with --headless --fixed-fps 60 for checks. With graphics and -- --preview, it also saves first-person and overhead screenshots in backups.


