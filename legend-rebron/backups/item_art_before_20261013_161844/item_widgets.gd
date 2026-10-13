extends RefCounted
const Style = preload("res://scripts/ui_style.gd")
static func badge(parent: Node, catalog: RefCounted, item: Dictionary, count: int = 1) -> PanelContainer:
	var panel := PanelContainer.new()
	var color: Color = catalog.rarity_color(item["rarity"])
	var border := Style.box(Color("20242c"), color)
	border.set_border_width_all(2)
	panel.add_theme_stylebox_override("panel", border)
	panel.tooltip_text = "%s / %s\n%s" % [item["name"], catalog.rarity_name(item["rarity"]), catalog.describe(item)] + "\nStacks: %d (bonuses per stack)" % count
	parent.add_child(panel)
	var name_label := Style.label(panel, "%s ×%d" % [item["name"], count], 17)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel
