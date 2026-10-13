# Staff fireball and tornado progression

The internal weapon ID remains spellbook for compatibility with existing saves; the displayed weapon is Staff.

| Level | Fireballs per cast | Cooldown | Tornado chance per cast |
| --- | --- | --- | --- |
| 1 | 1 | 0.65 s | 0% |
| 2 | 1, larger hit radius | 0.65 s | 0% |
| 3 | 1 | 0.65 s | 25% |
| 4 | 1 | 0.50 s | 50% |
| 5 | 1 | 0.35 s | 100% |

A tornado is an extra effect on a successful cast roll, never a replacement for the fireball. It appears at the existing aimed spell point (up to 12 m). Each tornado keeps the existing 3.5 m radius, 2.5 s duration and 45% of the cast's damage per pulse, sharing the cast's critical status. Chance uses the saved run RNG. Fireball damage and travel speed stay unchanged. LV5 replaces the previous multi-projectile/nuke volley with one faster fireball plus guaranteed tornado. Warp remains available at LV4/5.

Holding LMB repeats casts at the new cooldowns. The original staff casting animation scales its playback speed to complete within the faster cooldown. Existing blue/purple VFX remain enabled. HUD ability descriptions reflect the new chances.

Validation: backups/verify_staff_chance.gd exercises repeated actual casts at all five levels, checks one projectile each time, chance procs, exact guaranteed LV5 tornadoes, increasing hold-fire rates, release behavior and saved weapon-level restoration.
