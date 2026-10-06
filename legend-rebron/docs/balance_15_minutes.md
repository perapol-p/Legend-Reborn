# 15-minute survival balance
Boss arrival: 15:00 of active gameplay. Defeating it wins; dying shows Game Over. There is no automatic win or loss at the time boundary. Gameplay continues into overtime until one result occurs.

ATK bonuses: Common +3, Rare +6, Epic +12, Legendary +20. Other item bonuses, Luck, crit, XP and weapon levels retain their current rules. Bow volley damage is per victim: first arrow full, further arrows from the same shot 35%. Every victim receives its own full first hit, including piercing; a new volley starts fresh. Critical flags and damage notifications use the scaled damage actually applied.

Regular monster HP before overtime: 40 + 6*t + 0.6*t*t, where t is floor(active seconds)/60. At 0/5/10/15 minutes this is 40/85/160/265 HP. Archers use 70%, flyers 60%. Example ATK builds of 10/22/43/84 at those times take approximately 4/3/3/3 ordinary sword hits to kill a melee enemy, before crit. These are tuning examples, not guaranteed player progression.

Loot: Epic unlocks at both 2:00 and LV8; Legendary at both 5:00 and LV15. Common/Rare are available at the start. Weight checkpoints are 0:00=75/25/0/0, 2:00=65/27/8/0, 5:00=55/30/12/3, 10:00 onward=35/35/23/7. Luck modifies eligible weights; five eligible offers without Epic or Legendary make the sixth include an Epic. Items still come from level-up choices, not passive timed grants.

Overtime o=max(0,active_seconds-900)/60. New monster HP multiplies by (1+0.30*o)^2. All living monsters and the boss use pressure p=1+0.25*o: movement speed and damage multiply by p; attack cooldown divides by p. Enemy age still separately adds 10% base movement speed per minute alive. The boss has a fixed 10,000 HP and does not heal or expand its HP during combat.

Spawning continues during the boss fight. Normal batches are 2+floor(seconds/90), capped at 12. Overtime adds 2 per minute, capped at an extra 8. Interval is max(1 second,2/p). Total population and individual ranged populations have no caps. Archer unlock stays 5:00, flyer 10:00. Ground/free-space validation still applies, and non-boss enemies farther than 85 m despawn. Pausing freezes timers, age and pressure.
