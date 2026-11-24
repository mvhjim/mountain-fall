class_name Player
extends CharacterBody2D
## The friend the player controls.
## Keyboard: WASD / arrows to walk, E / Space / Enter to interact, Tab to pick another target.
## Mouse: click the ground to walk there, click a person or object to go and use it.
## Walking off the edge of the map makes you fall: +1 death, and you respawn nearby.

signal fell

@export var speed: float = 75.0
@export var friend_id: String = "maja"

var _targets: Array[Interactable] = []
var _selected: Interactable
var _move_target = null  # Vector2 or null
var _pending_interact: Interactable
var _last_safe: Vector2
var _falling := false
var _floor: TileMapLayer
var _bob := 0.0
var _was_moving := false

@onready var sprite: Sprite2D = $Sprite
@onready var reach: Area2D = $Reach


func _ready() -> void:
	add_to_group("player")
	_floor = get_tree().get_first_node_in_group("floor")
	_last_safe = global_position
	reach.area_entered.connect(_on_area_entered)
	reach.area_exited.connect(_on_area_exited)


func _physics_process(delta: float) -> void:
	if _falling:
		return
	var dir := Vector2.ZERO
	if not GameState.input_locked:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if dir != Vector2.ZERO:
			_move_target = null
			_pending_interact = null
		elif _move_target != null:
			var to: Vector2 = _move_target - global_position
			if _pending_interact and _targets.has(_pending_interact):
				_select(_pending_interact)
				_move_target = null
				var it := _pending_interact
				_pending_interact = null
				it.interact()
			elif to.length() < 2.0:
				_move_target = null
			else:
				dir = to.normalized()
	velocity = dir * speed
	move_and_slide()
	if (dir != Vector2.ZERO or _was_moving) and not _targets.is_empty():
		_select(_nearest())  # walking picks the closest target again
	_was_moving = dir != Vector2.ZERO
	_animate(delta, dir)
	if _move_target != null and get_slide_collision_count() > 0 and velocity.length() < 1.0:
		_move_target = null  # blocked by something
	_check_floor()


func _unhandled_input(event: InputEvent) -> void:
	if GameState.input_locked or _falling:
		return
	if event.is_action_pressed("interact") and _selected:
		get_viewport().set_input_as_handled()
		_selected.interact()
	elif event.is_action_pressed("cycle_target") and _targets.size() > 1:
		get_viewport().set_input_as_handled()
		var i := _targets.find(_selected)
		_select(_targets[(i + 1) % _targets.size()])
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_on_click(get_global_mouse_position())


## Switch which friend this player is (used between turns).
func set_friend(id: String) -> void:
	friend_id = id
	GameState.active_friend = id
	var tex := load("res://assets/sprites/%s.png" % id)
	if tex:
		sprite.texture = tex


## Put the player somewhere, e.g. at the start of a turn.
func teleport(pos: Vector2) -> void:
	global_position = pos
	_last_safe = pos
	_move_target = null
	_pending_interact = null
	velocity = Vector2.ZERO
	$Camera.reset_smoothing()


## Something (Gutten!) drags you off the edge. Counts as a fall.
func drag_off(toward: Vector2) -> void:
	if _falling:
		return
	var away := (global_position - toward).normalized()
	if away == Vector2.ZERO:
		away = Vector2.DOWN
	var t := create_tween()
	t.tween_property(self, "global_position", global_position + away * 30, 0.25)
	await t.finished
	_fall()


func is_falling() -> bool:
	return _falling


func selected_prompt() -> String:
	return _selected.prompt() if _selected else ""


func _on_click(pos: Vector2) -> void:
	# Clicked a person or object? Walk to it and use it.
	var best: Interactable
	var best_d := 14.0
	for it: Interactable in get_tree().get_nodes_in_group("interactables"):
		var d := pos.distance_to(it.global_position + Vector2(0, -10))
		if d < best_d:
			best_d = d
			best = it
	if best:
		if _targets.has(best):
			_select(best)
			best.interact()
		else:
			_pending_interact = best
			_move_target = best.global_position
		return
	# Clicked the ground? Walk there. Clicking empty sky does nothing.
	if _floor and _floor.get_cell_source_id(_floor.local_to_map(_floor.to_local(pos))) != -1:
		_pending_interact = null
		_move_target = pos


func _animate(delta: float, dir: Vector2) -> void:
	if dir.x != 0:
		sprite.flip_h = dir.x < 0
	if dir != Vector2.ZERO:
		_bob += delta * 14.0
		sprite.position.y = -abs(sin(_bob)) * 2.0
	else:
		_bob = 0.0
		sprite.position.y = 0.0


# ---------------------------------------------------------------- falling
func _has_floor(cell: Vector2i) -> bool:
	return _floor.get_cell_source_id(cell) != -1


func _check_floor() -> void:
	if _floor == null:
		return
	var cell := _floor.local_to_map(_floor.to_local(global_position))
	if not _has_floor(cell):
		_fall()
		return
	# Remember a spot well away from the edge to respawn at.
	for n in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if not _has_floor(cell + n):
			return
	_last_safe = _floor.to_global(_floor.map_to_local(cell))


func _fall() -> void:
	_falling = true
	_move_target = null
	_pending_interact = null
	GameState.lock()
	var start_z := z_index
	z_index = -10  # drop behind the map
	var t := create_tween().set_parallel()
	t.tween_property(self, "global_position:y", global_position.y + 140, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	t.tween_property(self, "modulate:a", 0.0, 0.7)
	t.tween_property(sprite, "rotation", 4.0, 0.7)
	GameState.show_toast("%s fell off the edge! Wheee..." % GameState.name_of(friend_id))
	await t.finished
	GameState.add_death(friend_id)
	fell.emit()
	global_position = _last_safe
	sprite.rotation = 0.0
	z_index = start_z
	modulate.a = 1.0
	var blink := create_tween().set_loops(4)
	blink.tween_property(sprite, "modulate:a", 0.3, 0.08)
	blink.tween_property(sprite, "modulate:a", 1.0, 0.08)
	_falling = false
	GameState.unlock()


# ---------------------------------------------------------------- targets
func _on_area_entered(area: Area2D) -> void:
	if area is Interactable and not _targets.has(area):
		_targets.append(area)
		_select_nearest()


func _on_area_exited(area: Area2D) -> void:
	if area is Interactable:
		_targets.erase(area)
		if area == _selected:
			area.set_highlighted(false)
			_selected = null
		_select_nearest()


func _select_nearest() -> void:
	if _selected and _targets.has(_selected):
		return
	_select(_nearest())


func _nearest() -> Interactable:
	var best: Interactable
	var best_d := INF
	for it in _targets:
		var d := global_position.distance_to(it.global_position)
		if d < best_d:
			best_d = d
			best = it
	return best


func _select(it: Interactable) -> void:
	if it == _selected:
		return
	if _selected and is_instance_valid(_selected):
		_selected.set_highlighted(false)
	_selected = it
	if it:
		it.set_highlighted(true)
