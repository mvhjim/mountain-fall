extends Node
## Global game state (autoload "GameState").
## Holds the friends' names, deaths, scores and story flags.
## Dialogue files can use these directly, e.g. {{maja}}: Hello!  or  if flag("got_keys")

signal deaths_changed(friend_id: String, count: int)
signal score_changed(friend_id: String, total: int)
signal toast(text: String)
signal friend_changed(friend_id: String)

const FRIENDS: Array[String] = ["maja", "even", "sara", "tom"]
const DEFAULT_NAMES := {"maja": "Maja", "even": "Even", "sara": "Sara", "tom": "Tom"}

var names: Dictionary = DEFAULT_NAMES.duplicate()
var deaths: Dictionary = {}
var scores: Dictionary = {}
var flags: Dictionary = {}
## Which friend the player is controlling right now.
var active_friend: String = "maja":
	set(value):
		active_friend = value
		friend_changed.emit(value)
## When true, falls cost points (scenarios with turns and scoring).
var scoring := false
const FALL_PENALTY := 20
## True while dialogue, menus or a fall is in progress. The player ignores input then.
var input_locked: bool:
	get:
		return _lock_count > 0

var _lock_count := 0

# Short names for dialogue files: {{maja}} gives the name the players typed in.
var maja: String:
	get: return names.maja
var even: String:
	get: return names.even
var sara: String:
	get: return names.sara
var tom: String:
	get: return names.tom
## The name of whoever is playing right now.  {{me}}: I'm cold.
var me: String:
	get: return names[active_friend]


func _ready() -> void:
	reset()
	var dm := get_node_or_null("/root/DialogueManager")
	if dm:
		dm.dialogue_started.connect(func(_r): lock())
		dm.dialogue_ended.connect(func(_r): unlock_soon())


func reset() -> void:
	flags.clear()
	for id in FRIENDS:
		deaths[id] = 0
		scores[id] = 0


func name_of(id: String) -> String:
	return names.get(id, id)


func flag(key: String) -> bool:
	return flags.get(key, false)


func set_flag(key: String, value: bool = true) -> void:
	flags[key] = value


func add_death(id: String = active_friend) -> void:
	deaths[id] += 1
	deaths_changed.emit(id, deaths[id])
	if scoring:
		add_score(-FALL_PENALTY, "", id)


## Give (or take) points. Shows a pop-up when a reason is given.
## Dialogue example:  $> add_score(25, "Nice!")
func add_score(points: int, reason: String = "", id: String = active_friend) -> void:
	scores[id] += points
	score_changed.emit(id, scores[id])
	if reason != "":
		show_toast("%s%d  %s" % ["+" if points >= 0 else "", points, reason])


func show_toast(text: String) -> void:
	toast.emit(text)


func lock() -> void:
	_lock_count += 1


func unlock() -> void:
	_lock_count = max(0, _lock_count - 1)


## Unlock after a short pause, so the key that closed a dialogue
## doesn't immediately start a new one.
func unlock_soon() -> void:
	await get_tree().create_timer(0.15).timeout
	unlock()
