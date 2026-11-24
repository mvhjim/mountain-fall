extends Control
## Start screen: type a name for each of the four friends, like at a bowling alley.
## Keyboard: type, Enter or Down for the next row, Up to go back, Enter on "Let's go!".

const FIRST_SCENE := "res://scenarios/s1_city/s1_city.tscn"
const PORTRAITS := {
	"maja": preload("res://assets/sprites/maja.png"),
	"even": preload("res://assets/sprites/even.png"),
	"sara": preload("res://assets/sprites/sara.png"),
	"tom": preload("res://assets/sprites/tom.png"),
}

var _edits: Array[LineEdit] = []
var _go: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.17, 0.27)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := VBoxContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	center.offset_left = -260
	center.offset_right = 260
	center.offset_top = -250
	center.offset_bottom = 250
	center.add_theme_constant_override("separation", 14)
	add_child(center)

	center.add_child(_text("Mountainfall", 56, Color.WHITE))
	center.add_child(_text("Who's going to the cabin?", 22, Color(1, 0.75, 0.45)))

	for i in GameState.FRIENDS.size():
		var id: String = GameState.FRIENDS[i]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 14)
		var lane := _text("%d" % (i + 1), 26, Color(0.6, 0.65, 0.75))
		lane.custom_minimum_size = Vector2(30, 0)
		row.add_child(lane)
		var pic := TextureRect.new()
		pic.texture = PORTRAITS[id]
		pic.custom_minimum_size = Vector2(32, 52)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(pic)
		var edit := LineEdit.new()
		edit.text = GameState.names[id]
		edit.placeholder_text = GameState.DEFAULT_NAMES[id]
		edit.max_length = 12
		edit.select_all_on_focus = true
		edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		edit.add_theme_font_size_override("font_size", 26)
		edit.text_submitted.connect(func(_t): _focus_row(i + 1))
		row.add_child(edit)
		_edits.append(edit)
		center.add_child(row)

	_go = Button.new()
	_go.text = "Let's go!"
	_go.add_theme_font_size_override("font_size", 28)
	_go.pressed.connect(_start)
	center.add_child(_go)
	center.add_child(_text("Enter: next    Up/Down: move    Enter on \"Let's go!\" to start    F2: debug menu", 14, Color(0.6, 0.65, 0.75)))

	# Up/Down move between rows
	for i in _edits.size():
		var e := _edits[i]
		e.focus_neighbor_top = (_edits[i - 1] if i > 0 else _go).get_path()
		e.focus_neighbor_bottom = (_edits[i + 1] if i < _edits.size() - 1 else _go).get_path()
	_go.focus_neighbor_top = _edits[-1].get_path()
	_go.focus_neighbor_bottom = _edits[0].get_path()
	_edits[0].grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	var focus := get_viewport().gui_get_focus_owner()
	if focus is LineEdit and event is InputEventKey and event.pressed:
		var i := _edits.find(focus)
		if event.keycode == KEY_DOWN:
			_focus_row(i + 1)
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_UP:
			_focus_row(i - 1)
			get_viewport().set_input_as_handled()


func _focus_row(i: int) -> void:
	if i >= _edits.size():
		_go.grab_focus()
	elif i >= 0:
		_edits[i].grab_focus()


func _start() -> void:
	for i in _edits.size():
		var id: String = GameState.FRIENDS[i]
		var typed := _edits[i].text.strip_edges()
		GameState.names[id] = typed if typed != "" else GameState.DEFAULT_NAMES[id]
	GameState.reset()
	Inventory.clear()
	get_tree().change_scene_to_file(FIRST_SCENE)


func _text(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
