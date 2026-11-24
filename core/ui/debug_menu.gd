extends CanvasLayer
## Debug menu for testing (autoload "DebugMenu"). Press F2 (or F1) anywhere to open it.
## Jump straight to any scenario or turn, skip a turn, or give points.
## Arrow keys move between buttons, Enter picks one, Esc or F2 closes.

const NAME_ENTRY := "res://core/ui/name_entry.tscn"
const S1 := "res://scenarios/s1_city/s1_city.tscn"
const S1_ROAD := "res://scenarios/s1_city/s1_road.tscn"
const TURN_SCENARIOS := [
	["Scenario 2: arrival", "res://scenarios/s2_cabin/s2_cabin.tscn"],
	["Scenario 3: challenges", "res://scenarios/s3_challenges/s3_challenges.tscn"],
]

var _panel: PanelContainer
var _box: VBoxContainer
var _first_button: Button


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.16, 0.96)
	style.border_color = Color(0.4, 1.0, 0.5)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(18)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	_box = VBoxContainer.new()
	_box.add_theme_constant_override("separation", 8)
	_panel.add_child(_box)
	_panel.hide()


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F2 or event.keycode == KEY_F1:
			toggle()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and is_open():
			close()
			get_viewport().set_input_as_handled()


func is_open() -> bool:
	return _panel.visible


func toggle() -> void:
	if is_open():
		close()
	else:
		open()


func open() -> void:
	_build()
	_panel.show()
	GameState.lock()
	_first_button.grab_focus.call_deferred()


func close() -> void:
	if not is_open():
		return
	_panel.hide()
	GameState.unlock_soon()


func _build() -> void:
	for ch in _box.get_children():
		ch.queue_free()
	_first_button = null
	_label("DEBUG MENU", 26, Color(0.4, 1.0, 0.5))
	_label("Jump anywhere. Names, points and falls are kept.", 14, Color(0.75, 0.8, 0.9))

	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 8)
	_box.add_child(top)
	_button(top, "Name screen", _jump.bind(NAME_ENTRY, 0, false))
	_button(top, "Scenario 1: the city", _jump.bind(S1, 0, false))
	_button(top, "Scenario 1: the road", _jump.bind(S1_ROAD, 0, false))

	for sc in TURN_SCENARIOS:
		_label(sc[0], 18, Color(1, 0.75, 0.45))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_box.add_child(row)
		for i in GameState.FRIENDS.size():
			_button(row, GameState.name_of(GameState.FRIENDS[i]), _jump.bind(sc[1], i, true))
		_button(row, "Evening", _jump.bind(sc[1], GameState.FRIENDS.size(), true))

	_label("Right now", 18, Color(1, 0.75, 0.45))
	var now := HBoxContainer.new()
	now.add_theme_constant_override("separation", 8)
	_box.add_child(now)
	var scene := get_tree().current_scene
	if scene and scene.has_method("debug_skip_turn"):
		_button(now, "Skip this turn", func():
			close()
			scene.debug_skip_turn())
	if scene and scene.has_method("debug_give_ice"):
		_button(now, "Get Smirnoff Ice", func():
			close()
			scene.debug_give_ice())
	_button(now, "+100 points", func():
		GameState.add_score(100, "Debug points"))
	_button(now, "Reset points + falls", func():
		var keep := GameState.flags.duplicate()
		GameState.reset()
		GameState.flags = keep
		for id in GameState.FRIENDS:
			GameState.score_changed.emit(id, 0)
			GameState.deaths_changed.emit(id, 0)
		GameState.show_toast("Points and falls reset"))
	_button(now, "Close", close)
	_label("Arrows: move   Enter: pick   Esc/F2: close", 13, Color(0.6, 0.65, 0.75))


func _jump(path: String, turn: int, scoring: bool) -> void:
	_panel.hide()
	_free_balloons(get_tree().root)
	GameState.clear_locks()
	GameState.scoring = scoring
	GameState.debug_start_turn = turn
	GameState.active_friend = GameState.FRIENDS[0]
	Inventory.clear()
	get_tree().paused = false
	get_tree().change_scene_to_file(path)


func _free_balloons(n: Node) -> void:
	for ch in n.get_children():
		if ch is MountainfallBalloon:
			ch.queue_free()
		elif ch != self:
			_free_balloons(ch)


func _button(parent: Control, text: String, action: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", 16)
	b.pressed.connect(action)
	parent.add_child(b)
	if _first_button == null:
		_first_button = b


func _label(text: String, size: int, color: Color) -> void:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	_box.add_child(l)
