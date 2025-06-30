# Base Enemy -------------------------------------------------------------------
"""
	Base class for the enemies
"""
# ------------------------------------------------------------------------------
extends CharacterBody2D
class_name BaseEnemy

# Exports ----------------------------------------------------------------------
@export var xp_drop_scene = preload("res://scenes/drops/XPDrop.tscn")
@export var coin_drop_scene = preload("res://scenes/drops/CoinDrop.tscn")
@export var health_drop_scene = preload("res://scenes/drops/HealthDrop.tscn")
@export var max_health = DEFAULT_MAX_HEALTH
@export var contact_tick_rate = 0.5
@export var dmg = DEFAULT_DMG
@export_range(0.0, 1.0, 0.01) var xp_drop_rate = 0.70
@export_range(0.0, 1.0, 0.01) var coin_drop_rate = 0.20
@export_range(0.0, 1.0, 0.01) var health_drop_rate = 0.1

# Values -----------------------------------------------------------------------
const DEFAULT_MAX_HEALTH = 50
const DEFAULT_DMG = 10

# variables --------------------------------------------------------------------
var _contact_cooldown = 0.0
var health: int = max_health

# Onready ----------------------------------------------------------------------
@onready var _animation_player = ($AnimationPlayer if has_node("AnimationPlayer") else null)

# Registers the enemy with the GameManager
func _ready() -> void:
	add_to_group("enemy")
	GameManager.register_enemy(self)

# Makes sure the enemy is removed from the manager
func _exit_tree() -> void:
	GameManager.unregister_enemy(self)

# Dealth with the damage taken by the enemies, and spawns the damage number
func take_damage(amount: int) -> void:
	health -= amount
	if GameManager.damage_number_scene:
		var dmg_num = GameManager.damage_number_scene.instantiate()
		dmg_num.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-5.0, 5.0))
		var label = null
		if dmg_num.has_node("Label"):
			label = dmg_num.get_node("Label")
		if label and label.has_method("setup"):
			label.setup(amount)
		elif dmg_num.has_method("setup"):
			dmg_num.setup(amount)
		get_tree().current_scene.call_deferred("add_child", dmg_num)
	if health <= 0:
		die()

# Death - makes the loop drop
func die() -> void:
	drop_loot()
	GameManager.incr_kills()
	GameManager.unregister_enemy(self)
	queue_free()

# Randomly spawns a drop
func drop_loot() -> void:
	var r = randf()
	if r < xp_drop_rate:
		_spawn_drop(xp_drop_scene)
	elif r < xp_drop_rate + coin_drop_rate:
		_spawn_drop(coin_drop_scene)
	elif r < xp_drop_rate + coin_drop_rate + health_drop_rate:
		_spawn_drop(health_drop_scene)

# Helper function to create a pickup at the enemy's location
func _spawn_drop(scene) -> void:
	var drop = scene.instantiate()
	drop.global_position = global_position
	get_tree().current_scene.call_deferred("add_child", drop)

# Used to throttle damage
func update_contact_cooldown(delta) -> void:
	if _contact_cooldown > 0.0:
		_contact_cooldown -= delta

# Inflicts damage upon contact
func apply_contact_damage(target, amount) -> void:
	if _contact_cooldown <= 0.0 and target and target.has_method("take_damage"):
		if _animation_player and _animation_player.has_animation("attack"):
			_animation_player.play("attack")
		target.take_damage(amount)
		_contact_cooldown = contact_tick_rate
