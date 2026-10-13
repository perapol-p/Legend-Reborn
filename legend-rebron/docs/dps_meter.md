# DPS meter

The HUD shows only the DPS number at the top-right edge (16 px from the top, 24 px from the right). There is no bar, background panel, suffix or peak display. The counter is hidden at zero DPS, during pause and after the run finishes.

- DPS is actual target HP removed in the last one active second, across all weapon hits, projectile hits, area damage and tornado pulses. Overkill is capped at remaining HP; ignored/dead targets and misses do not contribute.
- The one-second damage window freezes during pause and ends after the run finishes. DPS returns to zero once the player has not dealt damage for a full active second.
- Damage uses the same last-one-second active window. After a full second without damage the number disappears.
- Peak DPS is stored in the normal run save and restored by Continue. The live one-second window starts empty on scene load. Older saves default to a peak of zero.
- No damage multipliers, hit logic, item bonuses or weapon cooldowns are changed.

Validation: backups/verify_dps.gd checks actual HP loss, overkill, ignored/dead targets, area damage, rolling-window expiration, pause, fresh-scene save restoration, layout and rendered output.
