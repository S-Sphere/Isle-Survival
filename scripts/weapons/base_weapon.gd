# Base weapon ------------------------------------------------------------------
"""
	Base class for projectiles weapons
"""
# ------------------------------------------------------------------------------
extends Node2D
class_name Weapon

# Exports ----------------------------------------------------------------------
@export var cooldown = 1.2
@export var projectile_scene: PackedScene
@export var attack_origin: Vector2
@export var range = 500.0

# Variables --------------------------------------------------------------------
var level = 1
var _fire_timer

# Adds weapon to the group so attack origin works
func _ready() -> void:
	add_to_group("origin_weapon")
	_fire_timer = Timer.new()
	_fire_timer.wait_time = cooldown
	_fire_timer.one_shot = false
	add_child(_fire_timer)
	_fire_timer.timeout.connect(fire)
	_fire_timer.start()

# Deals with the fire of the firebolt
func fire() -> void:
	var candidates = []
	for enemy in GameManager.enemies:
		if attack_origin.distance_to(enemy.global_position) <= range:
			candidates.append(enemy)
	
	if candidates.size() == 0:
		return
	
	candidates.sort_custom(Callable(self, "_sort_by_distance"))
	
	if level >= 3:
		var first_enemy = candidates[0]
		var second_enemy = null
		if candidates.size() > 1:
			second_enemy = candidates[1]
		_spawn_projectile_toward(first_enemy, true, false)
		if second_enemy:
			_spawn_projectile_toward(second_enemy, true, false)
	elif level == 2:
		var target_enemy = candidates[0]
		_spawn_projectile_toward(target_enemy, false, true)
	else:
		var target_enemy = candidates[0]
		_spawn_projectile_toward(target_enemy, false, false)

# Helper function for sorting enemies by distance
func _sort_by_distance(a,b) -> int:
	var da = attack_origin.distance_to(a.global_position)
	var db = attack_origin.distance_to(b.global_position)
	return da < db

# Creates and configures the projectile
func _spawn_projectile_toward(enemy, is_double_shot, increase_damage):
	var proj = projectile_scene.instantiate()
	proj.is_homing = true
	proj.global_position = attack_origin
	proj.target = enemy
	if GameManager.player != null:
		proj.dmg += GameManager.player.dmg
	
	if increase_damage:
		proj.dmg = int(proj.dmg * 1.5)
	
	get_tree().current_scene.add_child(proj)
