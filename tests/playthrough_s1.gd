extends Node
## Automated playthrough of scenario 1 (part 1).
## Run from the project folder:
##   godot --headless --path . res://tests/playthrough_s1.tscn
## Prints PASS/FAIL per step; exit code = number of failures.

var scene: Node
var player: Node2D
var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("PASS " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func tap_action(a: String) -> void:
	var e := InputEventAction.new()
	e.action = a
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := InputEventAction.new()
	r.action = a
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


func tap_key(k: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = k
	e.physical_keycode = k
	e.pressed = true
	Input.parse_input_event(e)
	await get_tree().process_frame
	var r := e.duplicate()
	r.pressed = false
	Input.parse_input_event(r)
	await get_tree().process_frame


func balloon() -> Node:
	return _find(get_tree().root)


func _find(n: Node) -> Node:
	if n is MountainfallBalloon and n.is_inside_tree() and not n.is_queued_for_deletion():
		return n
	for ch in n.get_children():
		var f := _find(ch)
		if f:
			return f
	return null


func talk(choices: Array) -> Array:
	var said: Array = []
	for _i in 60:
		var b := balloon()
		if b == null or not b.is_inside_tree():
			break
		await wait(0.5)
		b = balloon()
		if b == null:
			break
		if b.dialogue_line and (said.is_empty() or said[-1] != b.dialogue_line.text):
			said.append(b.dialogue_line.text)
		if b.responses_menu.visible and not choices.is_empty():
			var c: int = choices.pop_front()
			await tap_key(KEY_1 + c - 1)
		else:
			await tap_action("interact")
	await wait(0.4)
	return said


func walk_to(target: Vector2, timeout := 8.0) -> void:
	var t := 0.0
	var deaths0: int = GameState.deaths.maja
	while t < timeout:
		if GameState.deaths.maja != deaths0 or GameState.input_locked:
			break
		var d := target - player.global_position
		if d.length() < 6:
			break
		var n := d.normalized()
		for a in ["move_left", "move_right", "move_up", "move_down"]:
			Input.action_release(a)
		if n.x > 0.05: Input.action_press("move_right", n.x)
		if n.x < -0.05: Input.action_press("move_left", -n.x)
		if n.y > 0.05: Input.action_press("move_down", n.y)
		if n.y < -0.05: Input.action_press("move_up", -n.y)
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
	for a in ["move_left", "move_right", "move_up", "move_down"]:
		Input.action_release(a)
	await wait(0.2)


func c(i: float, j: float) -> Vector2:
	return Vector2(16 + (i - j) * 16, 8 + (i + j) * 8)


func _ready() -> void:
	GameState.names.maja = "Jim"
	scene = load("res://scenarios/s1_city/s1_city.tscn").instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = scene
	player = get_tree().get_first_node_in_group("player")
	await wait(1.0)
	var said := await talk([])
	check(said.size() >= 3 and said[0].begins_with("Finally"), "intro dialogue plays: %s" % [said])

	# fall off the north edge
	await walk_to(c(2, -2), 4.0)
	await wait(2.0)
	check(GameState.deaths.maja == 1, "falling off adds a death (deaths=%d)" % GameState.deaths.maja)
	var fl: TileMapLayer = get_tree().get_first_node_in_group("floor")
	check(fl.get_cell_source_id(fl.local_to_map(player.global_position)) != -1 and player.modulate.a == 1.0, "respawned on the map")

	# inventory opens and closes
	await tap_action("inventory")
	check(GameState.input_locked, "inventory open locks movement")
	await tap_action("inventory")
	await wait(0.3)
	check(not GameState.input_locked, "inventory closes")

	await walk_to(c(6, 4) + Vector2(-14, 0))
	check(player.selected_prompt() == "Talk to Mrs. Berg", "Mrs. Berg selected: %s" % player.selected_prompt())
	await tap_action("interact")
	said = await talk([1])
	check(GameState.flag("asked_for_post"), "asked for post: %s" % [said])

	await walk_to(c(9, 5) + Vector2(-14, -4))
	check(player.selected_prompt() == "Open the mailbox", "mailbox selected: %s" % player.selected_prompt())
	await tap_action("interact")
	await talk([])
	check(Inventory.has("post"), "got the post")

	await walk_to(c(6, 4) + Vector2(14, 4))
	await tap_action("interact")
	said = await talk([1])
	check(Inventory.has("car_keys") and not Inventory.has("post"), "traded post for car keys")

	await walk_to(c(12.5, 5.5) + Vector2(0, -6))
	check(player.selected_prompt() == "Use the car", "car selected: %s" % player.selected_prompt())
	await tap_action("interact")
	said = await talk([])
	check(said.size() > 0 and "not leaving without" in said[0], "car refuses without Even: %s" % [said])

	await walk_to(c(13, 11) + Vector2(14, -6))
	check(player.selected_prompt() == "Talk to Even", "Even selected: %s" % player.selected_prompt())
	await tap_action("interact")
	said = await talk([1, 2])
	check(GameState.flag("even_joined") and GameState.flag("even_out_of_office"), "Even joins after out-of-office: %s" % [said])
	await wait(2.6)

	await walk_to(c(12.5, 5.5) + Vector2(0, -6))
	await tap_action("interact")
	said = await talk([])
	check("Jim" in str(said) or said.size() >= 3, "drive-off dialogue: %s" % [said])
	await wait(2.5)
	var card := false
	for n in scene.get_children():
		if n is CanvasLayer and n.layer == 10:
			card = true
	check(card, "end card shows")
	print("RESULT fails=%d" % fails)
	get_tree().quit(fails)
