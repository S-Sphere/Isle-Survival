# Aura Weapon ------------------------------------------------------------------
"""
	Weapon that damages enemies in a circural area around the player
"""
# ------------------------------------------------------------------------------
extends Area2D
class_name AuraWeapon

# Exports ----------------------------------------------------------------------
@export var base_radius = 40.0
@export var radius_per_level = 10.0
@export var base_damage = 3
@export var damage_per_level = 2
@export var tick_rate = 0.75
@export var attack_origin: Vector2 = Vector2.ZERO

# Onready ----------------------------------------------------------------------
@onready var collision_shape_2d = $CollisionShape2D
@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")
@onready var _timer: Timer = Timer.new()

# Variables --------------------------------------------------------------------
var _shape = CircleShape2D
var level: int = 1 : set = set_level
var damage
var range
 
# Starts timer and collision shape
func _ready() -> void:
	add_to_group("origin_weapon")
	_shape = collision_shape_2d.shape as CircleShape2D
	add_child(_timer)
	_timer.wait_time = tick_rate
	_timer.one_shot = false
	_timer.timeout.connect(_on_tick)
	_timer.start()
	
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var scale_x = base_radius * 2 / tex_size.x
			var scale_y = base_radius * 2 / tex_size.y
			sprite.scale = Vector2(scale_x, scale_y)
	update_stats()

# Follows the player
func _process(_delta) -> void:
	global_position = attack_origin

# Called for the weapon level increase
func set_level(value) -> void:
	level = value
	update_stats()

# Recalculates radius and damage based on level
func update_stats() -> void:
	var r = base_radius + radius_per_level * (level - 1)
	damage = base_damage + damage_per_level * (level - 1)
	if GameManager.player != null:
		damage += GameManager.player.dmg
	range = r
	if _shape:
		_shape.radius = r
	if sprite and sprite.texture:
		var tex_size = sprite.texture.get_size()
		if tex_size.x > 0 and tex_size.y > 0:
			var scale_x = r * 2 / tex_size.x
			var scale_y = r * 2 / tex_size.y
			sprite.scale = Vector2(scale_x, scale_y)

# Damage any enemies that are overlapping the area
func _on_tick() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("enemy") and body.has_method("take_damage"):
			body.take_damage(damage)
