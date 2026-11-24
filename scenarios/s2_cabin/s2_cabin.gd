extends Node2D
## Scenario 2: Arrival at the cabin.
## Four turns in a fixed order. Each friend has one task; finishing it ends their turn.
## Functions here can be called from the dialogue file, e.g. $> complete_task()
## Don't name variables here maja/even/sara/tom/me: dialogue would use them instead of names.

signal task_completed

const DIALOGUE := preload("res://scenarios/s2_cabin/s2_cabin.dialogue")
const ITEMS := [
	preload("res://scenarios/s2_cabin/items/cabin_key.tres"),
	preload("res://scenarios/s2_cabin/items/bucket.tres"),
	preload("res://scenarios/s2_cabin/items/bucket_full.tres"),
	preload("res://scenarios/s2_cabin/items/firewood.tres"),
	preload("res://scenarios/s2_cabin/items/matches.tres"),
	preload("res://scenarios/s2_cabin/items/beer.tres"),
	preload("res://scenarios/s2_cabin/items/cigarettes.tres"),
]
const TASKS := {
	"maja": "Find the cabin key and unlock the door.",
	"even": "Get the power on. The fuse box is on the shed.",
	"sara": "Fill the water barrel with water from the stream.",
	"tom": "Light the stove: you need firewood and matches.",
}
const TASK_POINTS := 100
const SPEED_BONUS_MAX := 50
const GUTTEN_BONUS := 50

var _task_done := false
var _turn_started_at := 0.0
var _gutten: Gutten

@onready var _player: Player = $World/Player
@onready var _spawn: Marker2D = $Spawn


func _ready() -> void:
	GameState.scoring = true
	GameState.flags.clear()
	Inventory.clear()
	Inventory.register(ITEMS)
	Inventory.add_recipe("beer", "cigarettes", _on_beer_and_cigarettes)
	_run_turns.call_deferred()


func _run_turns() -> void:
	for id in GameState.FRIENDS:
		await _play_turn(id)
	_show_friends("")
	_player.teleport(_spawn.global_position)
	DialogueManager.show_dialogue_balloon(DIALOGUE, "evening")
	await DialogueManager.dialogue_ended
	var choice := await Scoreboard.show_board(self, "Day 1 at the cabin", ["Play again"])
	if choice == "Play again":
		get_tree().change_scene_to_file("res://core/ui/name_entry.tscn")


func _play_turn(id: String) -> void:
	_player.set_friend(id)
	_player.teleport(_spawn.global_position)
	_show_friends(id)
	_task_done = false
	await PassScreen.show_card(self, "%s's turn!" % GameState.name_of(id), TASKS[id], load("res://assets/sprites/%s.png" % id))
	DialogueManager.show_dialogue_balloon(DIALOGUE, "%s_turn" % id)
	await DialogueManager.dialogue_ended
	_turn_started_at = Time.get_ticks_msec() / 1000.0
	if not _task_done:
		await task_completed
	# let the last line of dialogue finish
	while GameState.input_locked:
		await get_tree().process_frame
	if is_instance_valid(_gutten):
		_gutten.queue_free()
	await get_tree().create_timer(1.0).timeout


## Called from dialogue when the active friend finishes their task.
func complete_task() -> void:
	if _task_done:
		return
	_task_done = true
	var seconds := Time.get_ticks_msec() / 1000.0 - _turn_started_at
	var bonus: int = clampi(SPEED_BONUS_MAX - int(seconds / 4.0), 0, SPEED_BONUS_MAX)
	GameState.add_score(TASK_POINTS + bonus, "Task done! (speed bonus %d)" % bonus)
	task_completed.emit()


## Called from dialogue: hide an object under World, e.g. $> hide_node("Bucket")
func hide_node(node_name: String) -> void:
	var n := get_node_or_null("World/" + node_name)
	if n:
		n.hide()
		var it := n.get_node_or_null("Interactable")
		if it:
			it.set_highlighted(false)
			it.queue_free()


func gutten_awake() -> bool:
	return is_instance_valid(_gutten)


## Wake Gutten at an object under World (e.g. "Cellar"). He chases the active friend.
func wake_gutten(at_node: String) -> void:
	if gutten_awake():
		return
	var at := get_node_or_null("World/" + at_node) as Node2D
	_gutten = Gutten.new()
	$World.add_child(_gutten)
	_gutten.global_position = at.global_position if at else _player.global_position + Vector2(60, 0)
	var bonus_flag := "gutten_found_%s" % GameState.active_friend
	if not GameState.flag(bonus_flag):
		GameState.set_flag(bonus_flag)
		GameState.add_score(GUTTEN_BONUS, "Secret found: Gutten!")


func _on_beer_and_cigarettes() -> void:
	Inventory.take("beer")
	Inventory.take("cigarettes")
	GameState.show_toast("Somewhere, someone smells beer and smoke...")
	await get_tree().create_timer(1.2).timeout
	wake_gutten("Cellar")


func _show_friends(active: String) -> void:
	for id in GameState.FRIENDS:
		var n := get_node_or_null("World/Friend_" + id)
		if n:
			n.visible = id != active
