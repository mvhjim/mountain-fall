extends CanvasLayer
## Inventory window. [I] opens and closes it, Up/Down picks an item, Esc closes.

var _panel: PanelContainer
var _list: ItemList
var _desc: Label
var _open := false


func _ready() -> void:
	layer = 6
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.custom_minimum_size = Vector2(460, 320)
	_panel.offset_left = -230
	_panel.offset_top = -160
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.12, 0.2, 0.96)
	style.border_color = Color(1, 0.72, 0.38)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(16)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	_panel.add_child(box)
	var title := Label.new()
	title.text = "Inventory"
	title.add_theme_font_size_override("font_size", 26)
	box.add_child(title)
	_list = ItemList.new()
	_list.custom_minimum_size = Vector2(0, 170)
	_list.fixed_icon_size = Vector2i(32, 32)
	_list.add_theme_font_size_override("font_size", 20)
	_list.item_selected.connect(_on_selected)
	box.add_child(_list)
	_desc = Label.new()
	_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_desc.add_theme_font_size_override("font_size", 18)
	_desc.add_theme_color_override("font_color", Color(0.85, 0.9, 1))
	box.add_child(_desc)
	var help := Label.new()
	help.text = "Up/Down: choose    I or Esc: close"
	help.add_theme_font_size_override("font_size", 14)
	help.add_theme_color_override("font_color", Color(0.6, 0.65, 0.75))
	box.add_child(help)
	_panel.visible = false
	Inventory.changed.connect(_refresh)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory") and (_open or not GameState.input_locked):
		get_viewport().set_input_as_handled()
		_set_open(not _open)
	elif _open and event.is_action_pressed("cancel"):
		get_viewport().set_input_as_handled()
		_set_open(false)


## Also used by the on-screen hint and mouse users.
func toggle() -> void:
	_set_open(not _open)


func _set_open(on: bool) -> void:
	if on == _open:
		return
	_open = on
	_panel.visible = on
	if on:
		GameState.lock()
		_refresh()
		_list.grab_focus()
		if _list.item_count > 0:
			_list.select(0)
			_on_selected(0)
	else:
		_list.release_focus()
		GameState.unlock_soon()


func _refresh() -> void:
	_list.clear()
	for item in Inventory.items:
		_list.add_item(item.display_name, item.icon)
	if Inventory.items.is_empty():
		_desc.text = "Your pockets are empty."
	elif _open and _list.item_count > 0:
		_list.select(0)
		_on_selected(0)


func _on_selected(index: int) -> void:
	_desc.text = Inventory.items[index].description
