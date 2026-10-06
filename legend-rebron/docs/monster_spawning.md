# Monster spawn test
The MonsterSpawner node in scenes/game_placeholder.tscn controls spawning.
Defaults: radius 20 m, outer radius 26 m, 6 initial monsters, continuous spawning every 2 seconds, no cap on the total alive population. No waves or inter-wave breaks. Spawn batch starts at 2 and gains 1 every 90 seconds of active gameplay, capped at 12. Spawning still requires safe ground and free space. After 900 seconds, one prototype boss appears (10000 HP) and regular spawning continues with escalating overtime pressure. Defeating the boss clears the remaining monsters and shows Victory, with replay/lobby controls; completed runs are saved. New monster HP is 40 + 6*t + 0.6*t*t, where t is floor(active seconds)/60. HP scaling advances every second: 46.6 HP at 1 minute, 63.4 at 3 minutes, 85 at 5 minutes, 160 at 10 minutes. Existing monsters retain their spawn health. Damage, movement speed, and attack timing use the monster defaults. Pausing freezes progression. Players regenerate 1 HP per active second, up to Max HP. Death freezes the run and shows Game Over with time, monster kills, character/weapon levels, character, item stacks and final stats; Retry starts a fresh run and Main Menu returns to the lobby.
Spawn centers are at least 20.6 m away horizontally so their collision capsules are outside the 20 m boundary. Positions use the player's current location and random angles; ground and free space are checked. Monsters beyond 85 m despawn.

The cyan ground ring follows the player. It marks where monsters cannot initially spawn, not a barrier: monsters can walk into the ring afterwards. Orange markers and distance labels mark the original spawn point for 2 seconds. Debug HUD shows alive count and most recent spawn distance.

B toggles debug ring, markers and spawn HUD. Set Show Debug Radius = Off in the MonsterSpawner Inspector for normal gameplay. Release exports hide all helpers automatically. Hiding helpers does not disable spawning.

Placeholder monsters chase, attack for 8 damage every 1.2 seconds in melee range, and have 30 HP. All five weapons work with them and kills grant XP/combo. Player death ends the run; Retry restores full health and resets the encounter in a new game scene. The shared Model node in scenes/monster.tscn can be replaced with an imported asset later.

Run scenes/test_monster_spawning.tscn with --headless --fixed-fps 60 for checks. With graphics and -- --preview, it also saves first-person and overhead screenshots in backups.








## Ranged enemy roles
Before 05:00, only melee enemies spawn. From 05:00 to 09:59, spawn weights are melee 80%, archer 20%. From 10:00, weights are melee 74%, archer 18%, flying fire wisp 8%. These are per-spawn probabilities, not guaranteed quotas. There are no population caps for archers, flyers or the total enemy population. Spawn weights remain fixed after their time unlocks.
Archers use 70% of the time-scaled melee HP, keep about 11 m away, retreat inside 6 m, and can shoot out to 18 m. Their arrows deal 6 damage, travel at 16 m/s, and follow a mild gravity arc. Each attack has a 0.55-second visible windup, followed by at least 2.8 seconds cooldown.
Flying enemies use 60% of melee HP and hover about 2.2 m above the player ground level. They approach to about 5 m, and only fire within 7.5 m. Fireballs deal 8 damage, travel at 10 m/s, expire within 10 m, and do not home or splash. Windup is 0.65 seconds; cooldown is at least 3.4 seconds. Wings flap and the cast glows before firing.
Both roles need line of sight, lock the aim position at the start of windup so dodging works, and use colliding projectiles blocked by terrain but passing through other monsters, including the boss. Ranged aiming also ignores friendly monsters so a crowd does not block firing. Projectiles report the shooter's position to the red damage-direction HUD. Both roles remain in the monsters group for weapon damage, XP and run-summary kill counts. Their spawn times use active gameplay time; pausing does not unlock new types.


Each enemy gains movement speed based on its own time alive, not global run time: base_speed * (1 + 0.10 * alive_seconds / 60). New enemies start at their role's base speed, then gain 10% of that base speed per active minute, with no speed ceiling. The same rule applies to melee, archers, flyers and the boss. Pausing freezes enemy age. There are no per-type population caps; regular spawning continues during the boss fight from 15 minutes, with pressure, health and spawn rate rising (see balance_15_minutes.md).



