class_name PassScreen
extends CanvasLayer
## Full-screen card between turns: "Pass to Sara!". Enter/E/Space or a click continues.
## Usage:  await PassScreen.show_card(self, "Pass to Sara!", "Fetch water from the stream.")

signal confirmed

var _ready_for_input := false


static func show_card(parent: Node, title: String, subtitle: String, portrait: Texture2D = null) -> void:
	var card := PassScreen.new()
	parent.add_child(card)
	card._build(title, subtitle, portrait)
	await card.confirmed
	card.queue_free()


func _build(title: String, subtitle: String, portrait: Texture2D) -> void:
	layer = 20
	GameState.lock()
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.1, 0.18, 0.97)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -360
	box.offset_right = 360
	box.offset_top = -180
	box.offset_bottom = 180
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	add_child(box)
	if portrait:
		var pic := TextureRect.new()
		pic.texture = portrait
		pic.custom_minimum_size = Vector2(64, 104)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		box.add_child(pic)
	box.add_child(_label(title, 48, Color.WHITE))
	var sub := _label(subtitle, 22, Color(1, 0.8, 0.55))
	sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(sub)
	box.add_child(_label("Press Enter to start", 16, Color(0.6, 0.65, 0.75)))
	await get_tree().create_timer(0.4).timeout
	_ready_for_input = true


func _unhandled_input(event: InputEvent) -> void:
	if not _ready_for_input:
		return
	var go: bool = event.is_action_pressed("interact") or event.is_action_pressed("ui_accept") \
		or (event is InputEventMouseButton and event.pressed)
	if go:
		get_viewport().set_input_as_handled()
		_ready_for_input = false
		GameState.unlock_soon()
		confirmed.emit()


func _label(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
