# Weapon level upgrades
Every character level-up queues an item reward followed by one upgrade for the equipped weapon. Selecting the item raises weapon level by one and displays the weapon's three choices. Select one with the mouse or keys 1/2/3. The game remains paused until all item/weapon reward pairs are complete. Weapon levels start at 1 and have no level-5 cap or character-level 10/20/30/40 milestones.

Upgrades stack independently for each weapon:
- Sword: Attack Speed (+10% additive); Sword Wave Size (+15% additive); Sword Wave Range + Speed (+15% additive to both).
- Bow: Attack Speed (+10% additive); Projectile Count (+1 arrow per volley); Pierce Count (+1 additional enemy passed through).
- Staff (internal ID spellbook): Cast Speed (+10% additive); Storm Cooldown (8 seconds divided by 1.10 per rank; minimum 0.5 seconds); Explosion Size (+15% additive radius).

Attack/cast speed divides the base attack interval by 1 + 0.10 times rank. Sword starts with a piercing wave (6 m range, 14 m/s). Bow starts with one arrow, no additional piercing, and four volleys per reload. Staff has normal piercing fireballs, random storms within 10 m of the player, RMB warp, and E Explosion available from level 1. Explosion retains its 30-second cooldown and starts at 27 m radius.

Save fields include upgrade ranks, pending choice phase, weapon being upgraded, and storm cooldown and active storm lifetimes. Old saves keep their weapon levels and distribute prior earned ranks across the three new choices. /weaponlevel opens an upgrade choice in practice mode.

Regression tests: scripts/test_character_weapon_progression.gd and scenes/test_weapon_upgrade.tscn.

Weapon Stats Panel in the Tab equipment section reads the same central module used by combat. Gameplay HUD shows only character name above weapon type and level as compact text without a panel background. Level Up shows centered cards without weapon stats. Attack/cast speed is attacks per second; Wave Size is the crescent radius in metres. Storm spawns at a random valid ground position within 10 m, remains stationary, and lasts 2.5 seconds. Upgrades reduce cooldown, with +1 storm per spawn every five selected upgrades. Tab displays actual cooldown and spawn radius. All balance values live in weapon_progression.gd.
