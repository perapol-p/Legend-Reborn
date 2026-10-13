extends RefCounted
const Style = preload("res://scripts/ui_style.gd")
static func portrait(parent: Node, character: String, minimum: Vector2) -> PanelContainer:
 var panel := PanelContainer.new()
 panel.name = "CharacterArtwork"
 panel.custom_minimum_size = minimum
 panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
 panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var frame := Style.inset(Color("10171d"),Color("46545c"))
 for side in [SIDE_LEFT,SIDE_TOP,SIDE_RIGHT,SIDE_BOTTOM]: frame.set_content_margin(side,5)
 panel.add_theme_stylebox_override("panel",frame)
 panel.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
 parent.add_child(panel)
 var image := TextureRect.new()
 image.name = "CharacterImage"
 image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
 image.texture = GameData.character_icon(character)
 image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
 image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 image.size_flags_vertical = Control.SIZE_EXPAND_FILL
 image.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(image)
 return panel
