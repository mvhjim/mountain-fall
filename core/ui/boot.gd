extends Control
## Placeholder start screen for the empty project.
## Shows that the project runs, and echoes which input action a key maps to,
## so we can check the keyboard setup in the browser build.

const ACTIONS := [
	"move_up", "move_down", "move_left", "move_right",
	"interact", "cycle_target", "inventory", "combine", "cancel",
]

@onready var _status: Label = %Status


func _ready() -> void:
	var info := Engine.get_version_info()
	%Version.text = "Godot %s · %s" % [info.string, OS.get_name()]
	_status.text = "Press a game key to test the controls."


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	for action in ACTIONS:
		if event.is_action(action):
			_status.text = "Key \"%s\" = action: %s" % [event.as_text_physical_keycode(), action]
			return
	_status.text = "Key \"%s\" is not mapped to a game action." % event.as_text_physical_keycode()
