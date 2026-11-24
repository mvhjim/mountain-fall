extends PickupScene
## Scenario 1, part 1: Maja picks up Even in the city. Part 2 is the road (s1_road).
## Functions here can be called from the dialogue file, e.g. $> take_hidden_ice()

const DIALOGUE := preload("res://scenarios/s1_city/s1_city.dialogue")
const ITEMS := [
	preload("res://scenarios/s1_city/items/car_keys.tres"),
	preload("res://scenarios/s1_city/items/post.tres"),
	preload("res://scenarios/s1_city/items/smirnoff_ice.tres"),
]
const NEXT_SCENE := "res://scenarios/s1_city/s1_road.tscn"


func _ready() -> void:
	car = $World/Car
	GameState.active_friend = "maja"
	GameState.scoring = false
	Inventory.register(ITEMS)
	await get_tree().create_timer(0.6).timeout
	DialogueManager.show_dialogue_balloon(DIALOGUE, "intro")


## Called from dialogue when Maja finds the bottles behind the tree.
func take_hidden_ice() -> void:
	Inventory.give(IcePrank.ITEM_ID)
	var n := $World/HiddenIce
	var interactable: Interactable = n.get_node("Interactable")
	interactable.set_highlighted(false)
	interactable.queue_free()
	n.hide()


## Called from dialogue when the car drives off to the road.
func finish() -> void:
	GameState.lock()
	var t := create_tween()
	t.tween_property(car, "global_position", car.global_position + Vector2(200, 100), 1.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	await t.finished
	GameState.unlock()
	get_tree().change_scene_to_file(NEXT_SCENE)
