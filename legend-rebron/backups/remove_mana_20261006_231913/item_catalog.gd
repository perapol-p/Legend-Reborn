extends RefCounted
const DATA_PATH = "res://data/item_catalog.json"
const STAT_NAMES = {
	"attack": "ATK", "max_hp": "Max HP", "max_mp": "Max MP",
	"speed": "Speed", "luck": "Luck", "crit_chance": "Crit chance",
	"crit_damage": "Crit damage"
}
var data: Dictionary
var items: Array
var by_id: Dictionary = {}
func _init() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	items = data["items"]
	for item in items:
		by_id[item["id"]] = item
func item_for(id: String) -> Dictionary:
	return by_id.get(id, {})
func rarity_color(rarity: String) -> Color:
	return Color(data["rarities"][rarity]["color"])
func rarity_name(rarity: String) -> String:
	return data["rarities"][rarity]["name"]
func describe(item: Dictionary) -> String:
	var lines: PackedStringArray = []
	for stat in item["effects"]:
		var suffix := "%" if stat in ["luck", "crit_chance", "crit_damage"] else ""
		lines.append("+%s%s %s" % [format_number(float(item["effects"][stat])), suffix, STAT_NAMES[stat]])
	return "\n".join(lines)
func weapon_name(character: String) -> String:
	var weapon_id: String = data["character_weapons"].get(character, "")
	for weapon in data["weapons"]:
		if weapon["id"] == weapon_id:
			return weapon["name"]
	return "Not assigned"
static func format_number(value: float) -> String:
	return ("%.2f" % value).trim_suffix("0").trim_suffix("0").trim_suffix(".")
