# Player Firebolt --------------------------------------------------------------
"""
	Script responsible for the player firebolt. It follows enemies
"""
# ------------------------------------------------------------------------------
extends Weapon

# Exports ----------------------------------------------------------------------
@export var speed: float = 300.0
@export var dmg: int = 7
@export var is_homing: bool = true
@export var max_lifetime = 2.0

# Variables --------------------------------------------------------------------
var target: Node = null
var direction: Vector2 = Vector2.ZERO
var _age = 0.0
var _exploding = false

# OnReady ----------------------------------------------------------------------
@onready var _sprite = get_node_or_null("Sprite2D")
@onready var _collision = $CollisionShape2D

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	if _sprite:
		_sprite.play("move")

func _physics_process(delta: float) -> void:
	# Updates movements and check life time
	if _exploding:
		return
	_age += delta
	if _age >= max_lifetime:
		_explode()
		return
		
	if is_homing:
		# Moves in target direction
		if target and is_instance_valid(target):
			var move_dir = global_position.direction_to(target.global_position)
			rotation = move_dir.angle()
			global_position += move_dir * speed * delta
		else:
			queue_free()
	else:
		# For the radial
		if direction != Vector2.ZERO:
			rotation = direction.angle()
			global_position += direction * speed * delta
		else:
			queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy") and body.has_method("take_damage"):
		body.take_damage(dmg)
		call_deferred("_explode")

func _explode() -> void:
	if _exploding:
		return
	_exploding = true
	_collision.disabled = true
	if _sprite:
		_sprite.play("explode")
		await _sprite.animation_finished
	queue_free()
