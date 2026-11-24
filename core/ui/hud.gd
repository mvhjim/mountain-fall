extends CanvasLayer
## On-screen info: who you are, how many times you fell, what you can interact with,
## and short pop-up messages ("Got: Car keys").

var _who: Label
var _prompt: Label
var _toast: Label
var _toast_tween: Tween


func _ready() -> void:
	layer = 5
	_who = _label(20, Color(1, 1, 1))
	_who.position = Vector2(16, 12)
	var hint := _label(16, Color(0.85, 0.9, 1))
	hint.text = "[E] Interact   [Tab] Next target   [I] Inventory"
	hint.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -420
	hint.offset_right = -16
	hint.offset_top = 14
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_prompt = _label(22, Color(1, 0.85, 0.5))
	_prompt.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -300
	_prompt.offset_right = 300
	_prompt.offset_top = -70
	_prompt.offset_bottom = -30
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast = _label(24, Color(1, 1, 1))
	_toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_toast.offset_left = -400
	_toast.offset_right = 400
	_toast.offset_top = 60
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.modulate.a = 0.0
	GameState.toast.connect(_show_toast)
	GameState.deaths_changed.connect(func(_id, _n): _update_who())
	GameState.score_changed.connect(func(_id, _n): _update_who())
	GameState.friend_changed.connect(func(_id): _update_who())
	_update_who()


func _process(_delta: float) -> void:
	var player: Player = get_tree().get_first_node_in_group("player")
	if player and not GameState.input_locked and player.selected_prompt() != "":
		_prompt.text = "[E]  %s" % player.selected_prompt()
	else:
		_prompt.text = ""


func _update_who() -> void:
	var id := GameState.active_friend
	_who.text = "%s    Falls: %d" % [GameState.name_of(id), GameState.deaths[id]]
	if GameState.scoring:
		_who.text += "    Points: %d" % GameState.scores[id]


func _show_toast(text: String) -> void:
	_toast.text = text
	if _toast_tween:
		_toast_tween.kill()
	_toast.modulate.a = 1.0
	_toast_tween = create_tween()
	_toast_tween.tween_interval(1.8)
	_toast_tween.tween_property(_toast, "modulate:a", 0.0, 0.6)


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0.05, 0.07, 0.12))
	l.add_theme_constant_override("outline_size", 6)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l
