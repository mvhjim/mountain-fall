extends PickupScene
## Scenario 1, part 2: Maja drives along the road and picks up Sara and Tom.
## Here the player IS the car. Drive up to a friend and pick them up;
## they walk over to the car (and find a Smirnoff Ice on their seat, if Maja has some).
## Functions here can be called from the dialogue file, e.g. $> finish()

const DIALOGUE := preload("res://scenarios/s1_city/s1_road.dialogue")
const ITEMS := [
	preload("res://scenarios/s1_city/items/car_keys.tres"),
	preload("res://scenarios/s1_city/items/post.tres"),
	preload("res://scenarios/s1_city/items/smirnoff_ice.tres"),
]
const CAR_TEXTURE := preload("res://assets/sprites/car.png")
const NEXT_SCENE := "res://scenarios/s2_cabin/s2_cabin.tscn"

@onready var _player: Player = $World/Player


func _ready() -> void:
	car = _player
	GameState.active_friend = "maja"
	GameState.scoring = false
	Inventory.register(ITEMS)
	# Maja drives: the player looks like the car, is wider and faster.
	_player.sprite.texture = CAR_TEXTURE
	_player.sprite.offset = Vector2(0, -8)
	_player.speed = 110.0
	var body := CircleShape2D.new()
	body.radius = 8.0
	_player.get_node("Body").shape = body
	# Show the names the players typed in.
	for id in ["sara", "tom"]:
		friend_node(id).get_node("Interactable").display_name = GameState.name_of(id)
	await get_tree().create_timer(0.6).timeout
	DialogueManager.show_dialogue_balloon(DIALOGUE, "intro")


## Called from dialogue when everyone is in the car.
func finish() -> void:
	GameState.lock()
	_player.set_physics_process(false)  # driving away off the map is not a fall
	var t := create_tween()
	t.tween_property(_player, "global_position", _player.global_position + Vector2(160, 80), 1.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.parallel().tween_property(_player, "modulate:a", 0.0, 0.4).set_delay(1.2)
	await t.finished
	_show_end_card()


## Debug menu: get the Smirnoff Ice without going back to the city.
func debug_give_ice() -> void:
	Inventory.give(IcePrank.ITEM_ID)


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
	box.offset_left = -360
	box.offset_right = 360
	box.offset_top = -160
	box.offset_bottom = 160
	box.add_theme_constant_override("separation", 14)
	layer.add_child(box)
	var lines := [
		["On the road!", 40, Color.WHITE],
		["%s, %s, %s and %s are on their way to the mountains." % [GameState.maja, GameState.even, GameState.sara, GameState.tom], 22, Color(1, 0.75, 0.45)],
		["Falls: %d" % GameState.deaths["maja"], 22, Color(0.85, 0.9, 1)],
	]
	var iced := IcePrank.times_iced()
	if iced > 0:
		lines.insert(2, ["Friends pranked with Smirnoff Ice: %d" % iced, 20, Color(0.75, 0.85, 1)])
	for l in lines:
		var label := Label.new()
		label.text = l[0]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_size_override("font_size", l[1])
		label.add_theme_color_override("font_color", l[2])
		box.add_child(label)
	var next := Button.new()
	next.text = "Continue to the cabin"
	next.add_theme_font_size_override("font_size", 24)
	next.pressed.connect(func():
		GameState.unlock()
		get_tree().change_scene_to_file(NEXT_SCENE))
	box.add_child(next)
	next.grab_focus()
