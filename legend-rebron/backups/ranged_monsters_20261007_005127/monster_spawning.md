# Monster spawn test
The MonsterSpawner node in scenes/game_placeholder.tscn controls spawning.
Defaults: radius 20 m, outer radius 26 m, 6 initial monsters, continuous spawning every 2 seconds, cap 100 regular monsters. No waves or inter-wave breaks. Spawn batch starts at 2 and gains 1 every 90 seconds of active gameplay, capped at 12. Full populations skip spawning without building up a backlog. After 1200 seconds, regular spawning stops and one prototype boss appears (6000 HP). Defeating the boss clears the remaining monsters and shows Victory, with replay/lobby controls; completed runs are saved. New monster HP is 40 + 30*t + 6*t*t, where t is floor(active seconds)/60. HP scaling advances every second: 76 HP at 1 minute, 184 at 3 minutes, 340 at 5 minutes, 940 at 10 minutes. Existing monsters retain their spawn health. Damage, movement speed, and attack timing use the monster defaults. Pausing freezes progression. Players regenerate 1 HP per active second, up to Max HP. Death freezes the run and shows Game Over with time, monster kills, character/weapon levels, character, item stacks and final stats; Retry starts a fresh run and Main Menu returns to the lobby.
Spawn centers are at least 20.6 m away horizontally so their collision capsules are outside the 20 m boundary. Positions use the player's current location and random angles; ground and free space are checked. Monsters beyond 85 m despawn.

The cyan ground ring follows the player. It marks where monsters cannot initially spawn, not a barrier: monsters can walk into the ring afterwards. Orange markers and distance labels mark the original spawn point for 2 seconds. Debug HUD shows alive count and most recent spawn distance.

B toggles debug ring, markers and spawn HUD. Set Show Debug Radius = Off in the MonsterSpawner Inspector for normal gameplay. Release exports hide all helpers automatically. Hiding helpers does not disable spawning.

Placeholder monsters chase, attack for 8 damage every 1.2 seconds in melee range, and have 30 HP. All five weapons work with them and kills grant XP/combo. Player death ends the run; Retry restores full health and resets the encounter in a new game scene. The shared Model node in scenes/monster.tscn can be replaced with an imported asset later.

Run scenes/test_monster_spawning.tscn with --headless --fixed-fps 60 for checks. With graphics and -- --preview, it also saves first-person and overhead screenshots in backups.







