# Item prototype

All 20 item names and bonuses come from item1.png and item2.png. Display names may change later; stable IDs drive ownership. `icon` is optional and currently empty. No artwork is required.

- `data/item_catalog.json`: item names, rarity colors, additive bonuses, base stats, XP/rarity tuning, five weapon types and known character mappings.
- `scripts/run_state.gd`: per-run level/XP, unique ownership, weighted choices, queued level-up rewards, computed stats.
- `scripts/reward_overlay.gd`: mandatory pick-one overlay. Pauses the game while selecting.
- `scripts/item_widgets.gd`: name-only inventory badges with colored borders and bonus tooltips.
- `scripts/game_placeholder.gd`: connects HUD, inventory, rewards and pause ownership.

## Rules

At level 1 there is no reward. Advancing from level 1 to 2 offers three distinct unowned items; pick one. Rejected items stay in the pool. A claimed stable item ID never appears again during the run. Different items with the same stat add together. When only two or one remain, offer the remaining count. When all 20 are owned, leveling continues without opening an empty reward dialog.

A fresh gameplay scene starts a fresh run. There is no between-run item save yet.

Rarity starts at level 2: Common 70%, Rare 23%, Epic 6%, Legendary 1%. It interpolates to level 20: Common 15%, Rare 30%, Epic 35%, Legendary 20%, then stays there. Each card first rolls an available rarity, then a uniform item in it; both owned items and earlier cards are excluded. Empty rarity groups are omitted and probabilities renormalize, so these are weights before exclusions, not guaranteed final card percentages. Luck is displayed only and does not affect these weights yet.

Temporary base stats: HP 100, MP 50, ATK 10, Speed 100 points, Luck 0%, crit chance 5%, crit damage 150%. Bonuses are additive; crit chance and crit damage add percentage points. There is no real damage or movement system yet; stats and HUD update immediately. HP currently displays the full maximum because damage is not implemented.

XP threshold: 10 at level 1, plus 5 per subsequent level. `add_xp(amount)` handles multiple levels and queues one choice per level. The L button grants exactly enough XP for the next level. XP drops from monsters remain unimplemented.

Only one character-bound base weapon is modeled. Known examples map Knight/อัศวิน to Sword and Ninja/นินจา to Katana. The existing Daddy/Mommy/Son characters are left unassigned until their mapping is supplied. Weapon attack/evolution behavior is not implemented.

## Testing

Open `scenes/game_placeholder.tscn` and run the scene. J/K/R test combo; L tests level-up; 1/2/3 choose an item; Esc opens the pause menu (locked while choosing).

Automated checks:
- `--headless --path <project> --script res://scripts/test_items.gd`
- `--headless --path <project> res://scenes/test_game_ui.tscn --quit-after 600`
- `--headless --path <project> --script res://scripts/test_combo.gd`

Run the UI test without --headless to also capture HUD, reward and inventory PNGs under backups. The backup directory is excluded from Godot importing with .gdignore.
