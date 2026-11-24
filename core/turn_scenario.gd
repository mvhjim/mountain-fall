class_name TurnScenario
extends Node2D
## Shared base for the cabin scenarios: four turns in a fixed order, one task each.
## A scenario script extends this, fills in the settings in _setup() and writes the dialogue.
## Functions here can be called from dialogue, e.g. $> complete_task()
## Don't name variables maja/even/sara/tom/me: dialogue would use them instead of names.

signal task_completed

const TASK_POINTS := 100
const SPEED_BONUS_MAX := 50
const GUTTEN_BONUS := 50

## The scenario's dialogue file. Needs a "<id>_turn" title per friend and an "evening" title.
var dialogue: DialogueResource
## What each friend has to do, shown on the turn card.
var tasks: Dictionary = {}
## Title of the scoreboard at the end.
var board_title := ""
## Button on the scoreboard, and the scene it goes to.
var next_label := "Play again"
var next_scene := "res://core/ui/name_entry.tscn"
## Where Gutten comes from when beer and cigarettes are combined.
var gutten_home := "Cellar"

var _task_done := false
var _turn_started_at := 0.0
var _gutten: Gutten

@onready var _player: Player = $World/Player
@onready var _spawn: Marker2D = $Spawn


func _ready() -> void:
	GameState.scoring = true
	GameState.flags.clear()
	Inventory.clear()
	_setup()
	Inventory.add_recipe("beer", "cigarettes", _on_beer_and_cigarettes)
	_run_turns.call_deferred()


## Override: register items, recipes and fill in the settings above.
func _setup() -> void:
	pass


## Override: called after the evening dialogue, before the scoreboard.
func _before_board() -> void:
	pass


func _run_turns() -> void:
	# The debug menu can ask to start at a later turn (4 = straight to the evening).
	var first: int = GameState.debug_start_turn
	GameState.debug_start_turn = 0
	for i in range(first, GameState.FRIENDS.size()):
		await _play_turn(GameState.FRIENDS[i])
	_show_friends("")
	_player.set_friend(GameState.FRIENDS[0])
	_player.teleport(_spawn.global_position)
	DialogueManager.show_dialogue_balloon(dialogue, "evening")
	await DialogueManager.dialogue_ended
	await _before_board()
	var choice := await Scoreboard.show_board(self, board_title, [next_label])
	if choice == next_label:
		get_tree().change_scene_to_file(next_scene)


func _play_turn(id: String) -> void:
	_player.set_friend(id)
	_player.teleport(_spawn.global_position)
	_show_friends(id)
	_task_done = false
	await PassScreen.show_card(self, "%s's turn!" % GameState.name_of(id), tasks[id], load("res://assets/sprites/%s.png" % id))
	DialogueManager.show_dialogue_balloon(dialogue, "%s_turn" % id)
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
## extra: bonus points for doing it well, e.g. $> complete_task(30)
func complete_task(extra: int = 0) -> void:
	if _task_done:
		return
	_task_done = true
	var seconds := Time.get_ticks_msec() / 1000.0 - _turn_started_at
	var bonus: int = clampi(SPEED_BONUS_MAX - int(seconds / 4.0), 0, SPEED_BONUS_MAX)
	GameState.add_score(TASK_POINTS + bonus + extra, "Task done! (speed bonus %d)" % bonus)
	task_completed.emit()


## Debug menu: end the current turn without points.
func debug_skip_turn() -> void:
	if _task_done:
		return
	_task_done = true
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


## Called from dialogue: show a hidden object under World, e.g. $> show_node("Snowman")
func show_node(node_name: String) -> void:
	var n := get_node_or_null("World/" + node_name) as CanvasItem
	if n:
		n.show()


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
	wake_gutten(gutten_home)


func _show_friends(active: String) -> void:
	for id in GameState.FRIENDS:
		var n := get_node_or_null("World/Friend_" + id)
		if n:
			n.visible = id != active
