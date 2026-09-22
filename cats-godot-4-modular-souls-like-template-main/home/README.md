# Home / Ashen Refuge

New Game and Continue now start in the walkable Home courtyard. Use WASD and the mouse as usual. Walk to the glowing dungeon gate and press E (or the controller interact button) within 3.2 meters to enter Castle Outskirts.

The quest board and merchant are scenery only, marked COMING SOON. They have no activation method, interaction sensor, quest rewards, purchases, or shop menu.

Pause still supports stats, inventory, saving, settings and returning to the title screen. Inside the dungeon, Pause also offers Return to Home with confirmation. Character values, health, stamina, inventory and equipment travel between Home and the dungeon. Saved dungeon position, defeated enemies and interactable states are retained while at Home and restored on re-entry. Existing version-1 dungeon saves are supported and are not deleted by visiting Home.

`home_lobby.gd` builds the native 3D courtyard, props and portal. `lobby_hud.gd` shows the proximity-based gate prompt. `home_lobby.tscn` is the Home scene. No new external images or dependencies are required.

## Random dungeon update
The gate now creates a new expedition on every entry. See ../dungeon/README.md. Earlier descriptions of restoring castle state on re-entry are superseded.
