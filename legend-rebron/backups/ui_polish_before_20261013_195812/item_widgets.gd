extends RefCounted
const Style = preload("res://scripts/ui_style.gd")
static func artwork(parent: Node, catalog: RefCounted, item: Dictionary, height: float = 140.0) -> PanelContainer:
 var color: Color = catalog.rarity_color(item["rarity"])
 var frame := PanelContainer.new()
 frame.name = "ItemArtwork"
 frame.custom_minimum_size.y = height
 frame.size_flags_horizontal = Control.SIZE_EXPAND_FILL
 frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var background := Style.box(Color("10161d").lerp(color,0.065),Color(color,0.24),10)
 background.content_margin_left = 10
 background.content_margin_right = 10
 background.content_margin_top = 10
 background.content_margin_bottom = 10
 frame.add_theme_stylebox_override("panel",background)
 parent.add_child(frame)
 var texture: Texture2D = catalog.icon_for(item)
 if texture != null:
  var picture := TextureRect.new()
  picture.name = "ItemImage"
  picture.texture = texture
  picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
  picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
  picture.size_flags_horizontal = Control.SIZE_EXPAND_FILL
  picture.size_flags_vertical = Control.SIZE_EXPAND_FILL
  picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
  picture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
  frame.add_child(picture)
 else:
  var placeholder := Style.label(frame,"?",int(height*0.40),Color(color,0.7))
  placeholder.name = "MissingArtwork"
  placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
  placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
  placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return frame

static func badge(parent: Node, catalog: RefCounted, item: Dictionary, count: int = 1) -> PanelContainer:
 var panel := PanelContainer.new()
 panel.name = "Item_"+str(item["id"])
 panel.custom_minimum_size = Vector2(112,142)
 var color: Color = catalog.rarity_color(item["rarity"])
 var border := Style.box(Color("1b222b"),Color(color,0.7),10)

 border.content_margin_left = 8
 border.content_margin_right = 8
 border.content_margin_top = 8
 border.content_margin_bottom = 8
 panel.add_theme_stylebox_override("panel",border)
 panel.tooltip_text = "%s / %s\n%s\nStacks: %d (bonuses per stack)" % [item["name"],catalog.rarity_name(item["rarity"]),catalog.describe(item),count]
 parent.add_child(panel)
 var stack := VBoxContainer.new()
 stack.add_theme_constant_override("separation",5)
 stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
 panel.add_child(stack)
 artwork(stack,catalog,item,70.0)
 var name_label := Style.label(stack,item["name"],14)
 name_label.name = "ItemName"
 name_label.custom_minimum_size = Vector2(94,34)
 name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
 name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
 name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 var count_label := Style.label(stack,"x%d" % count,13,color)
 count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
 count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
 return panel
