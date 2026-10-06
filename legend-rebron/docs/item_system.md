# Item and movement prototype

## Items
The 20 names come from item1.png / item2.png; bonuses are tuned for the survival game. Edit data/item_catalog.json to change names, colors, effects or optional icon paths. Stable IDs track item types independently of their display names.

Items can repeat across level-up rounds without a stack cap. Each selection adds one stack and every stack adds the listed bonus. Pencil x10 adds 20 ATK (30 total with base ATK of 10). Different items' bonuses also add together. Inventory shows one colored name badge per type, with its stack count.

Each level-up offers three distinct types. Owned types remain eligible. Pick one; the other two return to the pool. Types remain eligible after being acquired, subject to their rarity unlock level. Pending multi-level rewards are queued; stale button callbacks cannot claim a later offer.

Rarity unlocks: Common LV1, Rare LV5, Epic LV12, Legendary LV25. Locked rarities are removed from the pool, not merely given a low chance. Weights interpolate from Common/Rare/Epic/Legendary = 85/15/0/0 at level 2 to 60/28/10/2 at level 60, then remain constant. A zero/locked weight is excluded before constructing the three choices. Within each offer, already shown types are excluded, with weights renormalized as needed. Luck is displayed as a percentage and does not modify reward weights yet.

ATK bonuses per Common/Rare/Epic/Legendary stack are 2/5/10/15; Max HP bonuses are 10/20/35/60. Crit chance bonuses are 0.5/1/2/3 points and crit damage 2/4/6/10 points. HP/ATK/crit/luck are stored stats used by combat. Speed bonuses now scale actual FPS movement relative to the base Speed of 100. Crit bonuses add percentage points. A fresh run clears levels and stacks. No between-run item save.

XP threshold is temporarily 10 + 5 per existing level above 1. The test level button supplies enough XP for the next level. Monsters and XP drops are not implemented.

## FPS prototype
scenes/game_placeholder.tscn now contains a native 3D arena and scenes/fps_player.tscn. Arena geometry, static collisions, ramps, steps and camera are editable in Godot.

Default inputs:
- WASD: move / air steer
- Mouse: look
- Space: jump (with short coyote time / jump buffer)
- Shift: sprint
- Q: dash, with a short cooldown
- Tab: release/capture mouse for test buttons
- Esc: pause/resume; reserved so menus always remain reachable
- J/K/R: test combo hit/kill/reset
- L: test level up
- 1/2/3: select a reward

Walk speed 9 m/s, sprint x1.5, dash 25 m/s for 0.16 s with a 0.65 s cooldown. Move speeds scale with the player's Speed stat. No weapon attacks, sliding, wall-running or enemy AI yet. The existing character-to-weapon metadata is unchanged.

Pause, reward dialogs and window focus loss release the mouse and stop gameplay. Resume captures it. Tab releases the mouse without pausing so test controls can be clicked.

## Settings
scripts/settings_panel.gd is shared by the main Settings/Controls screens and pause menu.
Keyboard inputs can be remapped using physical key positions. Clicking a binding waits for one key. Escape cancels. Assigning a key already in use swaps the two bindings so no action becomes unreachable.

Crosshair: plus (default), dot, gapped plus; white (default), red, black, light blue, yellow; size 6-48. A contrasting outline keeps the chosen color visible. A live preview uses the same drawing code as the game.

Bindings, mouse sensitivity/inversion and crosshair preferences save to user://settings.cfg alongside existing audio/display settings. Restore defaults resets these preferences. Old config files load with defaults for new fields.

## Checks
--headless --path <project> --script res://scripts/test_items.gd
--headless --path <project> res://scenes/test_game_ui.tscn --quit-after 2400
--headless --path <project> --script res://scripts/test_combo.gd

The integration test covers real physics, key input, remapping and config reload, modal pausing, repeat rewards and inventory. It uses user://fps_test_settings.cfg so the player's settings.cfg is not overwritten. Without --headless it also captures preview PNGs in the ignored backups folder.


