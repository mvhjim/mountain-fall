class_name SafeZone
extends Node2D
## Gutten gives up when the player gets within "radius" pixels of this point.

@export var radius: float = 24.0


func _ready() -> void:
	add_to_group("safe_zone")
