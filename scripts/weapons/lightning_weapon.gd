# Lightning Weapon --------------------------------------------------------
"""
	Periodically targets enemies with the lightning strike
"""
# ------------------------------------------------------------------------------
extends Node2D
class_name LightningWeapon

# Exports ----------------------------------------------------------------------
@export var min_interval 	: float = 1.5
@export var max_interval 	: float = 4.0
@export var radius 		 	: float = 200.0
@export var lightning_scene : PackedScene
@export var attack_origin	: Vector2

# Variables --------------------------------------------------------------------
var level = 1
var _timer: Timer
var _area: Area2D

# Creates the timer and join the weapon group
func _ready() -> void:
	randomize()
	add_to_group("origin_weapon")
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)
	_schedule_next_strike()

# Picks a random delay until the next strike
func _schedule_next_strike() -> void:
	_timer.start(randf_range(min_interval, max_interval))

# Fires a strike and queueu up the next one
func _on_timer_timeout() -> void:
	_fire_strike()
	_schedule_next_strike()

# Finds a random enemy within the range and strikes it
func _fire_strike() -> void:
	var center = attack_origin
	var candidates = []
	for e in GameManager.enemies:
		if e.global_position.distance_to(center) <= radius:
			candidates.append(e)
	if candidates.is_empty():
		return

	var target = candidates[randi() % candidates.size()]
	var bolt = lightning_scene.instantiate()

	bolt.target = target
	if GameManager.player != null:
		bolt.damage += GameManager.player.dmg
	get_tree().current_scene.add_child(bolt)
