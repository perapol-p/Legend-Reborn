extends RefCounted
const Style = preload("res://scripts/ui_style.gd")
static func portrait(parent: Node, character: String, minimum: Vector2) -> PanelContainer:
 var panel := PanelContainer.new()
 panel.name = "CharacterArtwork"
 panel.custom_minimum_size = minimum
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_theme_stylebox_override("panel",Style.box(Color("10171d"),Color("46545c"),10))
 parent.add_child(panel)
 var image := TextureRect.new()
 image.name = "CharacterImage"
 image.texture = GameData.character_icon(character)
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 image.size_flags_vertical = Control.SIZE_EXPAND_FILL
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(image)
 return panel
