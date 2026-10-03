# Legend Rebron - Godot 4 Project

Open project.godot. F5 runs the main menu; open scenes/game_placeholder.tscn and press F6 to test gameplay directly.

Current prototype:
- Main menu, character selection, settings and controls
- FPS test arena: movement, sprint, jump, air control and dash
- Rebindable keyboard controls and saved mouse settings
- Configurable crosshair: plus, dot or gapped plus; five colors and size
- Combo ranks F through SSS with fire and gradual decay
- Level-up rewards: three choices, one selection, unlimited item stacks
- Colored name badges and live item stats while holding Tab

WASD / Space / Shift / Q move, jump, sprint and dash. R reloads the gun. Esc pauses. Hold Tab for stats, weapons and items. F1 opens the command console; type /help and press Enter. 1/2/3 choose a level-up item. Test actions are available only through commands.

See [prototype notes](docs/item_system.md) for tuning, data paths, current limitations and test commands.

Command console (F1; F1 or Esc closes; Up/Down recalls history):
- `/help`: list commands
- `/weapon sword|katana|gun|bow|spellbook`: equip weapon
- `/target`: create training target
- `/hit`, `/kill`, `/reset`: test combo
- `/levelup`: level up and open item selection
- `/weaponlevel`: debug override to upgrade current weapon, up to level 5
- `/spawndebug on|off`: show/hide spawn radius and markers (off by default)
- `/spawninfo`: print spawn information in the console
- `/clear`: clear console output

The console pauses gameplay and preserves any existing pause or reward screen when closed. Settings > General > Tab UI opacity (%) controls stats background opacity and saves automatically.

Console regression check: Godot --headless --path . --script res://scripts/test_command_console.gd
Gun level 3 and above: monster kills with the gun have a 35% chance to create a red floating target above the defeated monster. The target and its hitbox shrink to zero over 3 seconds. Shoot it with the gun to unlock one use of the existing charged burst. Without an earned charge, the gun fires normally. A short hold keeps the charge; a charged release consumes it. Switching weapons clears earned charge and floating targets. Paused gameplay freezes the target timer.
Weapon progression: the equipped weapon gains one level whenever the character reaches a multiple of 10 (10, 20, 30, 40, ...), capped at weapon level 5. Crossing several milestones in one XP award grants each upgrade. Item choices still appear for every character level. Weapon levels remain separate when switching weapons; the milestone upgrades only the weapon equipped at that moment. HUD shows the next character level required.
