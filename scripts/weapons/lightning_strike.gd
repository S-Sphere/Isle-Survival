# Lightning Strike -------------------------------------------------------
"""
	Falling bolt that damages a single target
"""
# ------------------------------------------------------------------------------
extends Node2D    # Area2D -> AOE

# Exports ----------------------------------------------------------------------
@export var damage:       int   = 15
@export var fall_duration: float = 0.1
@export var spawn_height: float = 150.0
@export var fall_animation = "fall"
@export var explode_animation = "explode"

# Variables -------------------------------------------------------------------- 
var target: Node 
var _start_y := 0.0
var _t := 0.0
var _damage_applied = false
var _sprite_offset := Vector2.ZERO

# OnReady ----------------------------------------------------------------------
@onready var _sprite = get_node_or_null("Sprite2D")

# Initializes the strike and starts falling towards the target
func _ready() -> void:
	if not target or not is_instance_valid(target):
		queue_free()
		return
		
	if GameManager.player != null:
		damage += GameManager.player.dmg
	
	var target_pos = target.global_position

	if _sprite:
		_sprite_offset = _sprite.position
		_sprite.play(fall_animation)
		_sprite.animation_finished.connect(_on_animation_finished)
	
	_start_y = target_pos.y - spawn_height
	var start_pos = Vector2(target_pos.x, _start_y) - _sprite_offset
	global_position = start_pos

# Updates the bolt's position while falling
func _process(delta) -> void:
	if not target or not is_instance_valid(target):
		queue_free()
		return
	_t += delta
	var target_pos = target.global_position
	var center = target_pos - _sprite_offset
	var start_pos = Vector2(target_pos.x, target_pos.y - spawn_height)
	var t = clamp(_t / fall_duration, 0.0, 1.0)
	global_position = start_pos.lerp(center, t)

# Apply's damage when the bolt lands
func _apply_damage() -> void:
	if _damage_applied:
		return
	_damage_applied = true
	if target and is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)

# Handle switching from fall animation to explode
func _on_animation_finished() -> void:
	if not _sprite:
		queue_free()
		return
	if _sprite.animation == fall_animation:
		_apply_damage()
		_sprite.play(explode_animation)
	else:
		if not _damage_applied:
			_apply_damage()
		queue_free() 
