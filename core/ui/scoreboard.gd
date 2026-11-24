class_name Scoreboard
extends CanvasLayer
## End-of-scenario scoreboard: points and falls per friend, best friend on top.

signal closed(choice: String)


static func show_board(parent: Node, title: String, buttons: Array[String]) -> String:
	var board := Scoreboard.new()
	parent.add_child(board)
	board._build(title, buttons)
	var choice: String = await board.closed
	board.queue_free()
	return choice


func _build(title: String, buttons: Array[String]) -> void:
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
	box.offset_top = -260
	box.offset_bottom = 260
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 12)
	add_child(box)
	box.add_child(_label(title, 44, Color.WHITE))

	var ranking: Array = GameState.FRIENDS.duplicate()
	ranking.sort_custom(func(a, b): return GameState.scores[a] > GameState.scores[b])
	var most_falls: String = GameState.FRIENDS.reduce(func(best, id): return id if GameState.deaths[id] > GameState.deaths[best] else best, "maja")

	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 40)
	grid.add_theme_constant_override("v_separation", 8)
	for h in ["", "Friend", "Points", "Falls"]:
		grid.add_child(_label(h, 18, Color(0.6, 0.65, 0.75)))
	for i in ranking.size():
		var id: String = ranking[i]
		var color := Color(1, 0.82, 0.4) if i == 0 else Color(0.9, 0.93, 1)
		grid.add_child(_label("%d." % (i + 1), 26, color))
		grid.add_child(_label(GameState.name_of(id), 26, color))
		grid.add_child(_label(str(GameState.scores[id]), 26, color))
		grid.add_child(_label(str(GameState.deaths[id]), 26, color))
	var center := CenterContainer.new()
	center.add_child(grid)
	box.add_child(center)
	box.add_child(_label("Best friend: %s!" % GameState.name_of(ranking[0]), 26, Color(1, 0.75, 0.45)))
	if GameState.deaths[most_falls] > 0:
		box.add_child(_label("Most falls: %s (%d)" % [GameState.name_of(most_falls), GameState.deaths[most_falls]], 18, Color(0.85, 0.9, 1)))

	var first: Button
	for b in buttons:
		var btn := Button.new()
		btn.text = b
		btn.add_theme_font_size_override("font_size", 24)
		btn.pressed.connect(func():
			GameState.unlock()
			closed.emit(b))
		box.add_child(btn)
		if first == null:
			first = btn
	first.grab_focus()


func _label(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
