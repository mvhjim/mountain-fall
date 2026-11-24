extends Node
## Automated playthrough of scenario 1, part 2 (the road: pick up Sara and Tom).
## Run from the project folder:
##   godot --headless --path . res://tests/playthrough_s1_road.tscn
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
	GameState.names.sara = "Sanna"
	GameState.names.tom = "Tore"
	scene = load("res://scenarios/s1_city/s1_road.tscn").instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = scene
	player = get_tree().get_first_node_in_group("player")
	await wait(1.0)
	var said := await talk([])
	check(said.size() == 3 and "Sanna" in said[0], "road intro plays: %s" % [said])
	scene.debug_give_ice()
	check(Inventory.has("smirnoff_ice"), "debug gives the Smirnoff Ice")

	# drive off the edge: a fall
	await walk_to(c(3, 9), 3.0)
	await wait(2.0)
	check(GameState.deaths.maja == 1, "driving off the edge is a fall (deaths=%d)" % GameState.deaths.maja)

	await walk_to(c(15, 4.2))
	await walk_to(c(15, 5.3))
	check(player.selected_prompt() == "Pick up Sanna", "Sara selected with typed name: %s" % player.selected_prompt())
	await tap_action("interact")
	said = await talk([1])
	check(GameState.flag("sara_joined") and GameState.flag("sara_left_sled"), "Sara joins: %s" % [said])
	check(GameState.flag("iced_sara") and "Smirnoff Ice" in str(said), "Sara gets iced")
	check(not scene.get_node("World/Sara").visible, "Sara is in the car")

	await walk_to(c(30, 4.2), 10.0)
	await walk_to(c(30, 3.0))
	check(player.selected_prompt() == "Pick up Tore", "Tom selected: %s" % player.selected_prompt())
	await tap_action("interact")
	said = await talk([2, 3])
	check(GameState.flag("tom_joined"), "Tom joins after the password: %s" % [said])
	check(GameState.flag("iced_tom") and "I had to do it at the bus stop!" in str(said), "Tom gets iced, Sara teases")
	check(Inventory.has("smirnoff_ice"), "one bottle left over (Even wasn't iced)")

	await walk_to(c(41.5, 4.2), 10.0)
	await walk_to(c(41.5, 5.2))
	check(player.selected_prompt() == "Drive on to the mountains", "sign selected: %s" % player.selected_prompt())
	await tap_action("interact")
	said = await talk([])
	check("Mountains, here we come!" in str(said) and "a bottle of Smirnoff Ice left" in str(said), "drive on: %s" % [said])
	await wait(2.5)
	var card: Node
	for n in scene.get_children():
		if n is CanvasLayer and n.layer == 10:
			card = n
	check(card != null, "end card shows")
	if card:
		var texts := []
		for l in card.find_children("*", "Label", true, false):
			texts.append(l.text)
		check("Friends pranked with Smirnoff Ice: 2" in texts and "Falls: 1" in texts, "end card counts pranks: %s" % [texts])
	print("RESULT fails=%d" % fails)
	get_tree().quit(fails)
