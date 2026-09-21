extends Node
## Persistent character build. Combat resources reset when the player respawns.
signal changed
signal gained_experience(amount: int, levels: int)
const SAVE_PATH = "user://character_progression.cfg"
const KEYS = ["Hp", "Atk", "Spd", "Stamina", "Def"]
const BASE = {"Hp": 100.0, "Atk": 10.0, "Spd": 100.0, "Stamina": 100.0, "Def": 0.0}
const STEP = {"Hp": 20.0, "Atk": 2.0, "Spd": 3.0, "Stamina": 15.0, "Def": 5.0}
const MAX_RANK = 50
var level: int = 1
var experience: int = 0
var points: int = 3
var ranks: Dictionary = {"Hp": 0, "Atk": 0, "Spd": 0, "Stamina": 0, "Def": 0}
var persistence_enabled: bool = true
var save_error: bool = false

func _ready() -> void:
	load_progress()

func value(stat: String) -> float:
	return float(BASE.get(stat, 0.0)) + float(STEP.get(stat, 0.0)) * int(ranks.get(stat, 0))

func upgrade_cost(stat: String) -> int:
	return 1 + int(int(ranks.get(stat, 0)) / 5.0)

func xp_required() -> int:
	return 100 + (level - 1) * 50

func can_upgrade(stat: String) -> bool:
	return stat in KEYS and int(ranks[stat]) < MAX_RANK and points >= upgrade_cost(stat)

func upgrade(stat: String) -> bool:
	if not can_upgrade(stat):
		return false
	points -= upgrade_cost(stat)
	ranks[stat] = int(ranks[stat]) + 1
	save_progress()
	changed.emit()
	return true

func add_experience(amount: int) -> void:
	if amount <= 0:
		return
	experience += amount
	var levels: int = 0
	while experience >= xp_required():
		experience -= xp_required()
		level += 1
		points += 3
		levels += 1
	save_progress()
	changed.emit()
	gained_experience.emit(amount, levels)

func save_progress() -> void:
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	config.set_value("character", "version", 1)
	config.set_value("character", "level", level)
	config.set_value("character", "experience", experience)
	config.set_value("character", "points", points)
	for stat in KEYS:
		config.set_value("ranks", stat, ranks[stat])
	save_error = config.save(SAVE_PATH) != OK
	if save_error:
		push_warning("Character progression could not be saved.")

func load_progress() -> void:
	if not persistence_enabled:
		return
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	level = clampi(int(config.get_value("character", "level", 1)), 1, 100000)
	experience = clampi(int(config.get_value("character", "experience", 0)), 0, xp_required() - 1)
	points = clampi(int(config.get_value("character", "points", 3)), 0, 1000000)
	for stat in KEYS:
		ranks[stat] = clampi(int(config.get_value("ranks", stat, 0)), 0, MAX_RANK)
