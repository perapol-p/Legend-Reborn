# Staff progression
Staff uses internal ID spellbook. Each level-up item is followed by Cast Speed, Storm Cooldown, or Explosion Size.

Normal casting starts at a 0.65 second interval. Cast Speed adds 10% speed per rank. Explosion retains a 27 m base radius and gains 15% per rank.

A storm batch appears at a random grounded, unobstructed position within 10 m horizontally of the player each cooldown. Points are sampled uniformly over the disk using the saved run RNG. Each storm remains at its spawn point for 2.5 seconds, with a 3.5 m damage radius and 45% normal cast damage per pulse. It does not orbit or follow the player. Base cooldown is 8 seconds, divided by 1.10 per Storm Cooldown rank, with a 0.5 second minimum. Every five selected Storm Cooldown upgrades add one storm per spawn: ranks 0-4 spawn 1, 5-9 spawn 2, 10-14 spawn 3, and so on. Each storm gets an independent random position within 10 m. A batch uses one shared cooldown. Pause freezes timers. Continue restores timers and active finite storms. Previous orbiting-storm ranks migrate to cooldown ranks; obsolete orbit effects are removed.

Balance lives in weapon_progression.gd and is shared by combat and Tab stats. Gameplay HUD and Level Up contain no detailed weapon stats.
