class_name IcePrank
extends RefCounted
## The Smirnoff Ice prank. Maja hides a bottle on a friend's car seat.
## Whoever finds it has to drink it on one knee, in one gulp. Those are the rules.
## Used by scenario 1 (city and road). Uses story flags "iced_<friend id>".

const ITEM_ID := "smirnoff_ice"
const BOTTLES := 3
const BOTTLE := preload("res://assets/sprites/bottle.png")


## How many friends have been iced so far.
static func times_iced() -> int:
	var n := 0
	for id in GameState.FRIENDS:
		if GameState.flag("iced_" + id):
			n += 1
	return n


## Plays the animation on a friend (a Node2D with a "Sprite" child), then
## uses up one bottle. Await it.
static func play(friend: Node2D, friend_id: String) -> void:
	var sprite: Sprite2D = friend.get_node("Sprite")
	var bottle := Sprite2D.new()
	bottle.texture = BOTTLE
	bottle.offset = Vector2(0, 5)  # turn around the neck of the bottle
	bottle.position = Vector2(6, -9)
	bottle.z_index = 1
	friend.add_child(bottle)

	# Down on one knee, bottle up to the mouth.
	var t := friend.create_tween()
	t.tween_property(sprite, "scale", Vector2(1.08, 0.74), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(sprite, "rotation", -0.1, 0.3)
	t.tween_property(bottle, "position", Vector2(3, -12), 0.3)
	t.tween_property(bottle, "rotation", 2.7, 0.3)  # bottoms up!
	await t.finished

	# One gulp. Glug glug glug.
	for i in 3:
		_float_text(friend, "glug", Vector2(8 + i * 3, -16))
		await friend.get_tree().create_timer(0.4).timeout

	# Toss the empty bottle and stand up.
	var t2 := friend.create_tween()
	t2.tween_property(bottle, "position", Vector2(18, -22), 0.25).set_ease(Tween.EASE_OUT)
	t2.parallel().tween_property(bottle, "rotation", 8.0, 0.5)
	t2.tween_property(bottle, "position", Vector2(24, 2), 0.25).set_ease(Tween.EASE_IN)
	t2.tween_property(bottle, "modulate:a", 0.0, 0.2)
	t2.tween_property(sprite, "scale", Vector2.ONE, 0.25)
	t2.parallel().tween_property(sprite, "rotation", 0.0, 0.25)
	await t2.finished
	bottle.queue_free()

	GameState.set_flag("iced_" + friend_id)
	GameState.show_toast("%s got iced!" % GameState.name_of(friend_id))
	if times_iced() >= BOTTLES:
		Inventory.take(ITEM_ID)


static func _float_text(parent: Node2D, text: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 8)
	label.add_theme_color_override("font_color", Color(0.75, 0.85, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.1, 0.12, 0.2))
	label.add_theme_constant_override("outline_size", 3)
	label.position = at
	label.z_index = 60
	parent.add_child(label)
	var t := parent.create_tween()
	t.tween_property(label, "position:y", at.y - 10, 0.8)
	t.parallel().tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	t.tween_callback(label.queue_free)
