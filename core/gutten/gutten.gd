class_name Gutten
extends Node2D
## Gutten, the hidden fifth "friend". Wakes up when you do something you shouldn't,
## then staggers after you, trailing cigarette smoke.
## If he catches you, he hugs you right off the edge (counts as a fall).
## Escape by reaching a SafeZone (the sauna) or by surviving until he gets bored.

signal finished(caught: bool)

@export var speed: float = 88.0
## Seconds Gutten spends waking up before he starts chasing (your head start).
@export var wake_time: float = 2.0
@export var chase_time: float = 25.0
@export var escape_points: int = 75

var _player: Player
var _time := 0.0
var _done := false
var _wobble := 0.0
var _sprite: Sprite2D
var _smoke: CPUParticles2D
var _hic: Label
var _hic_timer := 1.5


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_sprite = Sprite2D.new()
	_sprite.texture = preload("res://assets/sprites/gutten.png")
	_sprite.offset = Vector2(0, -11)
	add_child(_sprite)
	_smoke = _make_smoke()
	add_child(_smoke)
	_hic = Label.new()
	_hic.text = "*hic*"
	_hic.add_theme_font_size_override("font_size", 8)
	_hic.position = Vector2(-10, -38)
	_hic.modulate.a = 0.0
	add_child(_hic)
	_puff()
	GameState.show_toast("Gutten woke up! RUN!")


func _physics_process(delta: float) -> void:
	if _done or _player == null:
		return
	if _player.is_falling() or GameState.input_locked:
		return
	_time += delta
	_hiccup(delta)
	if _time < wake_time:
		_sprite.rotation = sin(_time * 12.0) * 0.2  # stretching and swaying
		return
	if _player_is_safe():
		_escape("%s made it to safety!" % GameState.name_of(_player.friend_id))
		return
	if _time > wake_time + chase_time:
		_escape("Gutten got bored and wandered off.")
		return
	var to := _player.global_position - global_position
	if to.length() < 7.0:
		_catch()
		return
	_wobble += delta * 5.0
	var dir := to.normalized()
	var side := Vector2(-dir.y, dir.x) * sin(_wobble) * 0.6  # drunk zig-zag
	global_position += (dir + side).normalized() * speed * delta
	_sprite.flip_h = to.x < 0
	_sprite.rotation = sin(_wobble * 0.7) * 0.15


func _player_is_safe() -> bool:
	for zone in get_tree().get_nodes_in_group("safe_zone"):
		if _player.global_position.distance_to(zone.global_position) < zone.radius:
			return true
	return false


func _catch() -> void:
	_done = true
	GameState.show_toast("Gutten: \"Come here, buddy!\"")
	await _player.drag_off(global_position)
	_leave(true)


func _escape(text: String) -> void:
	_done = true
	if escape_points > 0 and GameState.scoring and not text.begins_with("Gutten got bored"):
		GameState.add_score(escape_points, text)
	else:
		GameState.show_toast(text)
	_leave(false)


func _leave(caught: bool) -> void:
	_puff()
	var t := create_tween()
	t.tween_property(_sprite, "modulate:a", 0.0, 0.6)
	await t.finished
	_smoke.emitting = false
	finished.emit(caught)
	await get_tree().create_timer(1.2).timeout
	queue_free()


func _hiccup(delta: float) -> void:
	_hic_timer -= delta
	if _hic_timer <= 0:
		_hic_timer = randf_range(1.5, 3.0)
		_hic.modulate.a = 1.0
		create_tween().tween_property(_hic, "modulate:a", 0.0, 0.8)


func _puff() -> void:
	var p := _make_smoke()
	p.one_shot = true
	p.amount = 24
	p.explosiveness = 0.9
	p.initial_velocity_min = 20
	p.initial_velocity_max = 40
	p.global_position = global_position + Vector2(0, -8)
	get_parent().add_child(p)
	p.emitting = true
	get_tree().create_timer(2.0).timeout.connect(p.queue_free)


func _make_smoke() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.texture = preload("res://assets/sprites/smoke.png")
	p.amount = 18
	p.lifetime = 1.4
	p.local_coords = false
	p.position = Vector2(-7, -14)  # the cigarette
	p.direction = Vector2(0, -1)
	p.spread = 30
	p.gravity = Vector2(0, -12)
	p.initial_velocity_min = 4
	p.initial_velocity_max = 10
	p.scale_amount_min = 0.4
	p.scale_amount_max = 0.9
	var curve := Curve.new()
	curve.add_point(Vector2(0, 0.4))
	curve.add_point(Vector2(1, 1.6))
	p.scale_amount_curve = curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.85, 0.85, 0.88, 0.7))
	ramp.set_color(1, Color(0.7, 0.7, 0.75, 0.0))
	p.color_ramp = ramp
	p.z_index = 5
	return p
