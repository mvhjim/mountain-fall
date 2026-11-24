extends TurnScenario
## Scenario 2: Arrival at the cabin.
## Four turns in a fixed order. Each friend has one task; finishing it ends their turn.
## The turn system, points and Gutten live in core/turn_scenario.gd.
## Functions there and here can be called from the dialogue file, e.g. $> complete_task()
## Don't name variables here maja/even/sara/tom/me: dialogue would use them instead of names.

const ITEMS := [
	preload("res://scenarios/s2_cabin/items/cabin_key.tres"),
	preload("res://scenarios/s2_cabin/items/bucket.tres"),
	preload("res://scenarios/s2_cabin/items/bucket_full.tres"),
	preload("res://scenarios/s2_cabin/items/firewood.tres"),
	preload("res://scenarios/s2_cabin/items/matches.tres"),
	preload("res://scenarios/s2_cabin/items/beer.tres"),
	preload("res://scenarios/s2_cabin/items/cigarettes.tres"),
]


func _setup() -> void:
	dialogue = preload("res://scenarios/s2_cabin/s2_cabin.dialogue")
	tasks = {
		"maja": "Find the cabin key and unlock the door.",
		"even": "Get the power on. The fuse box is on the shed.",
		"sara": "Fill the water barrel with water from the stream.",
		"tom": "Light the stove: you need firewood and matches.",
	}
	board_title = "Day 1 at the cabin"
	next_label = "Continue to day 2"
	next_scene = "res://scenarios/s3_challenges/s3_challenges.tscn"
	Inventory.register(ITEMS)
