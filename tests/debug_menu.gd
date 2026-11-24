extends Node
## Automated check of the debug menu (F2): open, jump to a turn, skip a turn.
## Run from the project folder:
##   godot --headless --path . res://tests/debug_menu.tscn
## Prints PASS/FAIL per step; exit code = number of failures.

var fails := 0


func check(cond: bool, msg: String) -> void:
	print(("PASS " if cond else "FAIL ") + msg)
	if not cond:
		fails += 1


func wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


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


func press(text: String, nth := 0) -> bool:
	var found := DebugMenu.find_children("*", "Button", true, false).filter(func(b): return b.text == text)
	if found.size() <= nth:
		return false
	found[nth].pressed.emit()
	return true


func _ready() -> void:
	# Keep this test node alive when the menu changes scene.
	get_tree().current_scene = null
	GameState.reset()
	await wait(0.2)

	await tap_key(KEY_F2)
	check(DebugMenu.is_open(), "F2 opens the debug menu")
	check(GameState.input_locked, "game input is locked while open")
	await tap_key(KEY_ESCAPE)
	await wait(0.3)
	check(not DebugMenu.is_open() and not GameState.input_locked, "Esc closes it and unlocks input")

	# Jump to scenario 3, Tom's turn (the 2nd row of friend buttons, Tom = nth 1)
	DebugMenu.open()
	await get_tree().process_frame
	check(press("Tom", 1), "found scenario 3 Tom button")
	await wait(1.0)
	var scene := get_tree().current_scene
	check(scene != null and scene.name == "S3Challenges", "jumped to scenario 3 (%s)" % (scene.name if scene else "none"))
	check(GameState.active_friend == "tom", "starts on Tom's turn (%s)" % GameState.active_friend)
	check(not DebugMenu.is_open(), "menu closes after a jump")

	# Skip Tom's turn: goes to the evening
	await wait(1.0)
	DebugMenu.open()
	await get_tree().process_frame
	check(press("Skip this turn"), "found Skip this turn")
	await wait(0.5)
	check(GameState.scores.tom == 0, "skipping gives no points")

	# Jump to scenario 2 evening while dialogue may be open
	DebugMenu.open()
	await get_tree().process_frame
	check(press("Evening", 0), "found scenario 2 Evening button")
	await wait(1.5)
	scene = get_tree().current_scene
	check(scene != null and scene.name == "S2Cabin", "jumped to scenario 2")
	check(GameState.input_locked, "evening dialogue is running (input locked)")

	DebugMenu.open()
	await get_tree().process_frame
	check(press("Scenario 1: the city"), "found scenario 1 button")
	await wait(1.0)
	check(not GameState.scoring, "scenario 1 has no scoring")
	print("RESULT fails=%d" % fails)
	get_tree().quit(fails)
