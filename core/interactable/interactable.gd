class_name Interactable
extends Area2D
## Add as a child of anything the player can talk to or use.
## Give it a dialogue file and a cue, or connect to the "interacted" signal.

signal interacted

## Shown in the prompt, e.g. "Talk to Mrs. Berg".
@export var display_name: String = ""
@export var verb: String = "Talk to"
@export var dialogue: DialogueResource
@export var cue: String = "start"
## The node that lights up when selected (defaults to the parent).
@export var highlight_target: CanvasItem
## Height of the selection marker above the ground, in pixels.
@export var marker_height: float = 30.0

var _marker: Sprite2D
var _tween: Tween


func _ready() -> void:
	add_to_group("interactables")
	monitoring = false
	collision_layer = 2
	collision_mask = 0
	if highlight_target == null and get_parent() is CanvasItem:
		highlight_target = get_parent()
	_marker = Sprite2D.new()
	_marker.texture = preload("res://assets/sprites/marker.png")
	_marker.position = Vector2(0, -marker_height)
	_marker.visible = false
	_marker.z_index = 50
	add_child(_marker)


func prompt() -> String:
	return "%s %s" % [verb, display_name]


func interact() -> void:
	interacted.emit()
	if dialogue:
		DialogueManager.show_dialogue_balloon(dialogue, cue)


func set_highlighted(on: bool) -> void:
	_marker.visible = on
	if _tween:
		_tween.kill()
	if on:
		_tween = create_tween().set_loops()
		_tween.tween_property(_marker, "position:y", -marker_height - 3, 0.35)
		_tween.tween_property(_marker, "position:y", -marker_height, 0.35)
	if highlight_target:
		highlight_target.modulate = Color(1.15, 1.15, 1.15) if on else Color.WHITE
