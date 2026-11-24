extends TurnScenario
## Scenario 3: Day 2, challenges at the cabin.
## Same turn system as scenario 2 (core/turn_scenario.gd). Each challenge gives
## extra points for how well it went: complete_task(extra) in the dialogue.
## At the end, Gutten joins the friends for dinner, then the final score for the whole trip.
## Don't name variables here maja/even/sara/tom/me: dialogue would use them instead of names.

const ITEMS := [
	preload("res://scenarios/s3_challenges/items/camera.tres"),
	preload("res://scenarios/s3_challenges/items/fishing_rod.tres"),
	preload("res://scenarios/s3_challenges/items/worms.tres"),
	preload("res://scenarios/s3_challenges/items/fish.tres"),
	preload("res://scenarios/s3_challenges/items/potatoes.tres"),
	preload("res://scenarios/s3_challenges/items/herbs.tres"),
	preload("res://scenarios/s3_challenges/items/carrot.tres"),
	preload("res://scenarios/s3_challenges/items/coal.tres"),
	preload("res://scenarios/s3_challenges/items/scarf.tres"),
	preload("res://scenarios/s2_cabin/items/beer.tres"),
	preload("res://scenarios/s2_cabin/items/cigarettes.tres"),
]


func _setup() -> void:
	dialogue = preload("res://scenarios/s3_challenges/s3_challenges.dialogue")
	tasks = {
		"maja": "Take the perfect photo from the lookout. The camera is in the car.",
		"even": "Catch a fish for dinner. Rod in the shed, worms under the woodpile.",
		"sara": "Cook dinner: potatoes, herbs and %s's fish." % GameState.name_of("even"),
		"tom": "Build a snowman: a carrot, coal and a scarf. Build it at the snow pile.",
	}
	board_title = "Final score: the whole trip"
	next_label = "Play again"
	next_scene = "res://core/ui/name_entry.tscn"
	Inventory.register(ITEMS)
	$World/Snowman.hide()
	$World/GuttenGuest.hide()


## Called from the evening dialogue: Gutten climbs out of the cellar and joins dinner.
func reveal_gutten() -> void:
	var guest: Node2D = $World/GuttenGuest
	var smoke := CPUParticles2D.new()
	smoke.texture = preload("res://assets/sprites/smoke.png")
	smoke.amount = 14
	smoke.lifetime = 1.4
	smoke.one_shot = true
	smoke.explosiveness = 0.8
	smoke.direction = Vector2.UP
	smoke.spread = 60
	smoke.initial_velocity_min = 10
	smoke.initial_velocity_max = 25
	smoke.gravity = Vector2(0, -15)
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 1.2
	smoke.color = Color(0.85, 0.85, 0.9, 0.7)
	smoke.position = Vector2(0, -10)
	guest.add_child(smoke)
	smoke.emitting = true
	guest.modulate.a = 0.0
	guest.show()
	create_tween().tween_property(guest, "modulate:a", 1.0, 0.6)
