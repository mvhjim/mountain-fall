extends Node
## Automated playthrough of scenario 2 (four turns at the cabin, Gutten, scoreboard).
## Run from the project folder:
##   godot --headless --path . res://tests/playthrough_s2.tscn
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
	var deaths0: int = GameState.deaths[GameState.active_friend]
	while t < timeout:
		if GameState.deaths[GameState.active_friend] != deaths0 or GameState.input_locked:
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


func pass_card() -> void:
	await wait(0.8)
	await tap_action("interact")
	await wait(0.5)
	await talk([])


func up_path() -> void:
	for j in [12, 10, 8, 6]:
		await walk_to(c(6, j))


func down_path() -> void:
	for j in [6, 8, 10, 12]:
		await walk_to(c(6, j))


func use(expect: String, choices: Array = []) -> Array:
	for _i in 6:  # Tab through nearby targets until the right one is selected
		if player.selected_prompt() == expect:
			break
		await tap_action("cycle_target")
	check(player.selected_prompt() == expect, "selected '%s' (got '%s')" % [expect, player.selected_prompt()])
	await tap_action("interact")
	return await talk(choices)


func gutten() -> Node:
	for n in scene.get_node("World").get_children():
		if n is Gutten:
			return n
	return null


func _ready() -> void:
	GameState.reset()
	Inventory.clear()
	scene = load("res://scenarios/s2_cabin/s2_cabin.tscn").instantiate()
	get_tree().root.add_child.call_deferred(scene)
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().current_scene = scene
	player = get_tree().get_first_node_in_group("player")

	# ---- Maja: key, then wake Gutten via the cellar, then unlock
	await pass_card()
	check(GameState.active_friend == "maja", "Maja's turn first")
	await up_path()
	await walk_to(c(1, 5) + Vector2(8, 10))
	await use("Look under the frog stone")
	check(Inventory.has("cabin_key"), "found the cabin key")
	await walk_to(c(3, 6) + Vector2(0, 12))
	await use("Open the cellar hatch", [1])
	check(gutten() != null, "opening the cellar wakes Gutten")
	await wait(4.5)
	check(GameState.deaths.maja == 1, "Gutten caught Maja (falls=%d)" % GameState.deaths.maja)
	check(GameState.scores.maja == 30, "score: +50 secret, -20 fall = 30 (got %d)" % GameState.scores.maja)
	await wait(1.5)
	await walk_to(c(6, 6))
	await walk_to(c(6.5, 5))
	await use("Open the cabin door")
	check(GameState.flag("door_unlocked"), "door unlocked")
	check(GameState.scores.maja > 130, "task points added (score %d)" % GameState.scores.maja)

	# ---- Even: fuse box, one wrong switch
	await wait(1.5)
	await pass_card()
	check(GameState.active_friend == "even", "Even's turn second")
	check(Inventory.items.is_empty(), "Even starts with empty pockets")
	await up_path()
	await walk_to(c(9, 6))
	await walk_to(c(12, 5))
	await use("Open the fuse box", [1, 2])
	check(GameState.flag("power_on"), "power on")

	# ---- Sara: bucket, stream, barrel; also test beer + cigarettes
	await wait(1.5)
	await pass_card()
	check(GameState.active_friend == "sara", "Sara's turn third")
	await up_path()
	await use_after_walk(c(6, 6), "Take the bucket")
	check(Inventory.has("bucket"), "got the bucket")
	await walk_to(c(9, 6))
	await walk_to(c(12.5, 6))
	await use("Use the stream")
	check(Inventory.has("bucket_full"), "filled the bucket")
	Inventory.give("beer")
	Inventory.give("cigarettes")
	Inventory.combine("cigarettes", "beer")
	await wait(1.5)
	check(gutten() != null and not Inventory.has("beer"), "beer + cigarettes wakes Gutten")
	await wait(4.0)
	while gutten() != null:
		await wait(0.5)
	player.teleport(c(9, 6))  # wherever Gutten left us, continue from the path
	await wait(0.3)
	await use("Use the water barrel")
	check(GameState.flag("water_done"), "water barrel filled")

	# ---- Tom: matches from the car, firewood, stove
	await wait(1.5)
	await pass_card()
	check(GameState.active_friend == "tom", "Tom's turn last")
	await use("Search the car")
	check(Inventory.has("matches"), "found matches")
	await up_path()
	await walk_to(c(4, 5) + Vector2(0, 4))
	await walk_to(Vector2(-8, 72))
	await use("Take from the woodpile")
	check(Inventory.has("firewood"), "took firewood")
	await walk_to(Vector2(16, 86))
	await use("Use the stove")
	check(GameState.flag("fire_done"), "fire lit")

	# ---- evening + scoreboard
	await wait(2.0)
	var said := await talk([])
	check(said.size() >= 4, "evening dialogue plays")
	await wait(1.0)
	var board := false
	for n in scene.get_children():
		if n is Scoreboard:
			board = true
	check(board, "scoreboard shows")
	print("scores ", GameState.scores, " falls ", GameState.deaths)
	print("RESULT fails=%d" % fails)
	get_tree().quit(fails)


func use_after_walk(pos: Vector2, expect: String) -> void:
	await walk_to(pos)
	await use(expect)
