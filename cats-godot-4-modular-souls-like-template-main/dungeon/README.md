# Random dungeon portal

Walk to the Home gate and press E to enter Shifting Depths. Each entry creates a
new 3D layout with eight rooms, three-cell-wide corridors, seven guardians,
three chests, collision geometry, navigation, and a return portal in a distant
room. Press E at the return portal or use Pause > Return to Home.

Character progression, current health, inventory and equipment travel between
scenes. Returning through the Home gate starts a fresh expedition: previous
positions, defeated enemies and opened chests are not restored into a new map.
Continue still starts at Home. Old castle saves remain readable. Death reloads
the current expedition's seed rather than generating a different layout.

The layout pipeline is adapted from the MIT-licensed
Godot-Simple-Dungeon-Generator archive e0f63c86038b377fcd1e7edcd956995ac2855cfb
provided in Downloads. Its Godot 3 2D renderer is replaced by a Godot 4 3D
GridMap. Room separation is bounded with a deterministic fallback; the spanning
tree uses the complete room graph to handle collinear centers; corridors are
carved as inclusive L paths. License is preserved in dungeon/third_party/LICENSE.

Run tests/test_dungeon.gd, tests/test_lobby.gd and tests/test_menus.gd with
Godot --headless --path <project> --script res://tests/<test>.gd.