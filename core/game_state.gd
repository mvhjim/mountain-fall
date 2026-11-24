extends Node
## Global game state (autoload "GameState").
## Holds the friends' names, deaths, scores and story flags.
## Dialogue files can use these directly, e.g. {{maja}}: Hello!  or  if flag("got_keys")

signal deaths_changed(friend_id: String, count: int)
signal toast(text: String)

const FRIENDS: Array[String] = ["maja", "even", "sara", "tom"]
const DEFAULT_NAMES := {"maja": "Maja", "even": "Even", "sara": "Sara", "tom": "Tom"}

var names: Dictionary = DEFAULT_NAMES.duplicate()
var deaths: Dictionary = {}
var scores: Dictionary = {}
var flags: Dictionary = {}
## Which friend the player is controlling right now.
var active_friend: String = "maja"
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
