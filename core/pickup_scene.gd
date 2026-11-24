class_name PickupScene
extends Node2D
## Shared code for the two parts of scenario 1, where Maja picks up her friends.
## A friend is a node under World named after them ("Even", "Sara", "Tom")
## with a "Sprite" child and an "Interactable".
## Dialogue can call: $> friend_walks_to_car("sara"), $> drink_ice("sara"), $> friend_gets_in("sara")
## Don't name variables maja/even/sara/tom: dialogue would use them instead of names.

## The car the friends walk to. Set it in _ready().
var car: Node2D


func friend_node(id: String) -> Node2D:
	return get_node_or_null("World/" + id.capitalize())


## The friend walks over to the car. Dialogue waits until they're there.
func friend_walks_to_car(id: String) -> void:
	GameState.set_flag(id + "_joined")
	var n := friend_node(id)
	var interactable := n.get_node_or_null("Interactable")
	if interactable:
		interactable.set_highlighted(false)
		interactable.queue_free()
	var target := car.global_position + Vector2(-24, 8)
	var seconds: float = clampf(n.global_position.distance_to(target) / 40.0, 0.6, 2.2)
	var t := create_tween()
	t.tween_property(n, "global_position", target, seconds)
	await t.finished


## The friend finds a Smirnoff Ice on their seat. One knee, one gulp.
func drink_ice(id: String) -> void:
	await IcePrank.play(friend_node(id), id)


## The friend climbs in and disappears into the car.
func friend_gets_in(id: String) -> void:
	var n := friend_node(id)
	var t := create_tween()
	t.tween_property(n, "global_position", car.global_position, 0.3)
	t.parallel().tween_property(n, "modulate:a", 0.0, 0.3)
	t.tween_callback(n.hide)
	await t.finished
