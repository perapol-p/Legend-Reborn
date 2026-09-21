# Character progression

Press C to open the character panel. C or Escape closes it. The panel pauses the game and releases the mouse. New builds start with 3 points. Defeating an enemy gives 50 EXP by default; every level grants 3 points. EXP thresholds start at 100 and rise by 50 each level. Upgrade cost is 1 + floor(rank / 5), with a maximum of 50 ranks per stat.

| Stat | Base | Per rank | Effect |
| --- | --- | --- | --- |
| Hp | 100 | +20 | Maximum health |
| Atk | 10 | +2 | Weapon damage multiplier = Atk / 10 |
| Spd | 100% | +3% | Ground movement and airborne steering |
| Stamina | 100 | +15 | Maximum action energy |
| Def | 0 | +5 | Damage taken = raw damage * 100 / (100 + Def) |

Original template damage/healing is multiplied by 20 for the player's 100-HP scale. Enemy health and weapon resource values stay on their original scale. Attack scaling uses a per-hit payload, leaving shared equipment resources unchanged.

Light/heavy attacks cost 15/25, dodge costs 25, gadget attack costs 20, jump costs 10, blocking a hit costs 12, and sprinting costs 18 per second. Stamina regenerates 24 per second after a 0.8-second delay, slower while guarding. Perfect parries remain free. A failed block allows damage through.

Progress is stored separately in user://character_progression.cfg. Level, EXP, points and stat ranks persist across death and restart; health and stamina refill on respawn. Tune BASE/STEP and points in progression.gd, action costs in player_charbody3D.gd, and recovery in player_stats.gd. Enemy experience_reward is editable in the Inspector.

The interface and five SVG icons are original native assets. No external art dependencies. Files present before installation were backed up in the stats-backup directory at the project root.