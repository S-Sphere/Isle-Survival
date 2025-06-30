# Enemy Type 1 -----------------------------------------------------------------
"""
	Melee enemy that chases and contacts the player
"""
# ------------------------------------------------------------------------------
extends BaseEnemy

# State Machine ----------------------------------------------------------------
enum State {
	CHASE,
	ATTACK,
	IDLE
}

# Exports ----------------------------------------------------------------------
@export var movement_speed = 50.0
@export var attack_range = 0.0
@export var attack_anim = "attack"
@export var move_anim = "run"
@export var attack_duration = 0.5

# Variables --------------------------------------------------------------------
var _player_col_shape
var state = State.CHASE
var attack_timer = 0.0

#OnReady -----------------------------------------------------------------------
@onready var player = get_tree().get_first_node_in_group("player")
@onready var _col_shape = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var map_generator: Node = get_tree().current_scene.get_node_or_null("MapGenerator")

# Setup health and caches the player's collider
func _ready() -> void:
	super._ready()
	if max_health == BaseEnemy.DEFAULT_MAX_HEALTH:
		max_health = 60
	health = max_health
	if player and player.has_node("CollisionShape2D"):
		_player_col_shape = player.get_node("CollisionShape2D")

# Updates the AI state machine every frame
func _physics_process(delta):
	update_contact_cooldown(delta)
	velocity = Vector2.ZERO
	match state:
		State.CHASE:
			chase_player(delta)
		State.ATTACK:
			attack_player(delta)
		State.IDLE:
			idle(delta)
	if _is_out_of_map():
		queue_free()

# Runs towards the player until it is within attack range
func chase_player(_delta) -> void:
	if player and is_instance_valid(player):
		if sprite:
			sprite.play(move_anim)
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * movement_speed
		move_and_slide()
		if global_position.distance_to(player.global_position) <= _contact_threshold():
			state = State.ATTACK
			attack_timer = 0.0
	else:
		state = State.IDLE

# Play the attack animation and damage the player once
func attack_player(delta) -> void:
	velocity = Vector2.ZERO
	if attack_timer <= 0.0:
		if player and is_instance_valid(player):
			apply_contact_damage(player, dmg)
		if sprite:
			sprite.play(attack_anim)
		attack_timer = attack_duration
	else:
		attack_timer -= delta
		if attack_timer <= 0.0:
			state = State.CHASE

# Stands still when no player is available - not really used
func idle(_delta) -> void:
	velocity = Vector2.ZERO
	sprite.play("idle")
	if player and is_instance_valid(player):
		state = State.IDLE

# Removes the enemy if it wanders ouside the playable area
# Because sometimes the enemy glitches and get's catapulted
func _is_out_of_map() -> bool:
	if map_generator == null:
		return false
	var tm = map_generator.get_node_or_null("TileMap/TileMapLayer_floor")
	if tm == null:
		return false
	var tile = tm.local_to_map(map_generator.to_local(global_position))
	if map_generator.has_method("_tile_in_bounds"):
		return not map_generator._tile_in_bounds(tile)
	return false

# Approximates a radius for different collider shapes
func _shape_radius(shape):
	if shape is RectangleShape2D:
		return max(shape.extents.x, shape.extents.y)
	elif shape is CapsuleShape2D:
		return max(shape.radius, shape.height / 2.0)
	elif shape is CircleShape2D:
		return shape.radius
	return 0.0

# Calculates the distance needed before starting an attack
func _contact_threshold():
	var r1 = 0.0
	if _col_shape and _col_shape.shape:
		r1 = _shape_radius(_col_shape.shape)
	var r2 = 0.0
	if _player_col_shape and _player_col_shape.shape:
		r2 = _shape_radius(_player_col_shape.shape)
	return attack_range + r1 + r2
