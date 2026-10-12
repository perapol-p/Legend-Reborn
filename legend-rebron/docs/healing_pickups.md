# Healing pickups and supplies

- Normal monster kills roll a 3% heart drop chance, raised to 6% when current HP is below 30% of maximum HP. Only accepted monster kills roll; training targets and repeated damage to dead monsters do not.
- Hearts heal 8% of the current maximum HP on contact within 1.5 m. They expire after 15 active seconds, freeze during pause/menu, and remain unconsumed at full HP. Flying enemy drops are placed on the terrain beneath them.
- Each stage has three supply chests. Approach within 3 m, look at a chest and press the rebindable Interact key (default E). Each chest heals 20% of maximum HP and refills 180 active seconds after use. Refills do not stack. A REFILLS IN mm:ss label shows the remaining cooldown; the lid closes when ready. Full health does not consume the chest. Range and line of sight are required.
- Healing is capped at maximum HP and cannot revive a dead player. Existing 1 HP per second passive regeneration is unchanged.
- Used chest flags and individual refill cooldowns, active heart positions/lifetimes and the independent drop RNG state are captured in the single normal-run save. Old saves without healing data start with fresh supplies. New runs reset supplies. Older saves with only a used-chest flag begin a 180 second cooldown for those chests. Cooldowns freeze during pause, menus and after the run finishes. Practice has three supplies for testing.
- UI shows healing amount, nearby chest interaction, and a refill countdown after use. Effects volume controls the pickup chime. No safe zone is added.

Checks: backups/verify_healing.gd (percent scaling/caps, real kill/drop, full HP, expiry, pause/death, chest guards and disk save); backups/verify_healing_continue.gd (fresh-process Continue/new Desert); backups/preview_healing.gd (actual E input, chest lid and rendered heart).

Refill checks: backups/verify_supply_refill.gd validates independent timers, reuse, no accumulation, full-health/pause/end guards, disk-save restoration and older save migration.
