extends Node2D
## Scenario 1: Collect the friends. Part 1: Maja picks up Even.
## Functions here can be called from the dialogue file, e.g. $> even_joins()

const DIALOGUE := preload("res://scenarios/s1_city/s1_city.dialogue")
const ITEMS := [
	preload("res://scenarios/s1_city/items/car_keys.tres"),
	preload("res://scenarios/s1_city/items/post.tres"),
]

# Note: don't name variables here maja/even/sara/tom. Dialogue would
# use them instead of the friends' names.
@onready var _even_node: Node2D = $World/Even
@onready var _car_node: Node2D = $World/Car


func _ready() -> void:
	GameState.active_friend = "maja"
	Inventory.register(ITEMS)
	await get_tree().create_timer(0.6).timeout
	DialogueManager.show_dialogue_balloon(DIALOGUE, "intro")


## Called from dialogue when Even agrees to come.
func even_joins() -> void:
	GameState.set_flag("even_joined")
	var interactable: Interactable = _even_node.get_node("Interactable")
	interactable.set_highlighted(false)
	interactable.queue_free()
	var t := create_tween()
	t.tween_property(_even_node, "global_position", _car_node.global_position + Vector2(-6, 2), 2.0)
	t.tween_property(_even_node, "modulate:a", 0.0, 0.3)
	t.tween_callback(_even_node.hide)


## Called from dialogue when the car drives off.
func finish() -> void:
	GameState.lock()
	var t := create_tween()
	t.tween_property(_car_node, "global_position", _car_node.global_position + Vector2(200, 100), 1.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await t.finished
	_show_end_card()


func _show_end_card() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var bg := ColorRect.new()
	bg.color = Color(0.06, 0.08, 0.14, 0.92)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	box.offset_left = -320
	box.offset_right = 320
	box.offset_top = -160
	box.offset_bottom = 160
	box.add_theme_constant_override("separation", 14)
	layer.add_child(box)
	var lines := [
		["On the road!", 40, Color.WHITE],
		["%s and %s are on their way." % [GameState.maja, GameState.even], 22, Color(1, 0.75, 0.45)],
		["(Picking up %s and %s comes in a later version.)" % [GameState.sara, GameState.tom], 18, Color(0.85, 0.9, 1)],
		["Falls: %d" % GameState.deaths["maja"], 22, Color(0.85, 0.9, 1)],
	]
	for l in lines:
		var label := Label.new()
		label.text = l[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", l[1])
		label.add_theme_color_override("font_color", l[2])
		box.add_child(label)
	var next := Button.new()
	next.text = "Continue to the cabin"
	next.add_theme_font_size_override("font_size", 24)
	next.pressed.connect(func():
		GameState.unlock()
		get_tree().change_scene_to_file("res://scenarios/s2_cabin/s2_cabin.tscn"))
	box.add_child(next)
	next.grab_focus()
