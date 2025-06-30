# Boss Type 1 ------------------------------------------------------------------
"""
	Base class for the enemies
"""
# ------------------------------------------------------------------------------
extends BaseEnemy

# Variables --------------------------------------------------------------------
enum State {
	CHASE,
	WARNING,
	CHARGE,
	IDLE
} 

enum ChargeAnimPhase { 
	MOVE, 
	ATTACK, 
	POST 
}

const CHARGE_ANIM_SPEED := 8.0
const ATTACK_PHASE_DURATION := 0.3

var _player_col_shape
var player
var _charge_dir = Vector2.ZERO
var _charge_target = Vector2.ZERO
var _charge_phase := ChargeAnimPhase.MOVE
var _charge_anim_timer = 0.0

var state = State.CHASE
var _cooldown_timer: Timer
var _warning_timer: Timer
var _charge_timer: Timer

# Exports ----------------------------------------------------------------------
@export var movement_speed = 30.0
@export var charge_speed = 250.0
@export var warning_time = 0.8
@export var time_between_charges = 5.0
@export var charge_width = 10.0
@export var attack_range = 0.0
@export var charge_damage_mult := 3.0

@export var move_anim := "move"
@export var charge_anim := "attack_charge"

# Onready ----------------------------------------------------------------------
@onready var _col_shape = $CollisionShape2D
@onready var sprite: AnimatedSprite2D = $Sprite2D

# Initialise state and timers
func _ready() -> void:
	#add_to_group("enemy")
	super._ready()
	if max_health == BaseEnemy.DEFAULT_MAX_HEALTH:
		max_health = 3000
	health = max_health
	if sprite:
		sprite.play(move_anim)
	
	player = get_tree().get_first_node_in_group("player")
	
	if player and player.has_node("CollisionShape2D"):
		_player_col_shape = player.get_node("CollisionShape2D")
	
	_cooldown_timer = Timer.new()
	_cooldown_timer.wait_time = time_between_charges
	_cooldown_timer.one_shot = false
	add_child(_cooldown_timer)
	_cooldown_timer.timeout.connect(_on_cooldown_timeout)
	_cooldown_timer.start()
	
	_warning_timer = Timer.new()
	_warning_timer.wait_time = warning_time
	_warning_timer.one_shot = true
	add_child(_warning_timer)
	_warning_timer.timeout.connect(_start_charge)
	
	_charge_timer = Timer.new()
	_charge_timer.one_shot = true
	add_child(_charge_timer)
	_charge_timer.timeout.connect(_end_charge)

# Handle Behaviour based on current state
func _physics_process(delta):
	match state:
		State.CHASE:
			if sprite:
				sprite.play(move_anim)
			_chase_player(delta)
			_check_contact_damage()
		State.WARNING:
			if sprite:
				sprite.stop()
				sprite.animation = charge_anim
				sprite.frame = 0
			velocity = Vector2.ZERO
		State.CHARGE:
			if sprite:
				sprite.play(charge_anim)
			_charge_move(delta)
		State.IDLE:
			if sprite:
				sprite.play(move_anim)
			_check_contact_damage()

# Moves towards the player at a normal pace
func _chase_player(_delta) -> void:
	if player and is_instance_valid(player):
		var direction = global_position.direction_to(player.global_position)
		velocity = direction * movement_speed
		move_and_slide()

# Begin the charge warning phase
func _on_cooldown_timeout() -> void:
	if player and is_instance_valid(player):
		state = State.WARNING
		if sprite:
			sprite.stop()
			sprite.animation = charge_anim
			sprite.frame = 0
		_charge_target = player.global_position
		_charge_dir = global_position.direction_to(_charge_target)
		_warning_timer.start()
		queue_redraw()

# Switch to charging state and setup animation timing
func _start_charge() -> void:
	state = State.CHARGE
	if sprite:
		sprite.stop()
		sprite.animation = charge_anim
		sprite.frame = 0.0
	_charge_phase = ChargeAnimPhase.MOVE
	_charge_anim_timer = 0.0
	queue_redraw()
	var dist = global_position.distance_to(_charge_target)
	if dist <= 0:
		dist = 1
	var duration = dist / charge_speed
	_charge_timer.wait_time = duration
	_charge_timer.start()

# Move rapidly towards the player
func _charge_move(delta) -> void:
	velocity = _charge_dir * charge_speed
	move_and_slide()
	_update_charge_animation(delta)
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= _contact_threshold():
			if _charge_phase == ChargeAnimPhase.MOVE:
				apply_contact_damage(player, int(dmg * charge_damage_mult))
				_charge_phase = ChargeAnimPhase.ATTACK
				_charge_anim_timer = 0.0

# Cycle through frames to create a simple charge animation
func _update_charge_animation(delta) -> void:
	if sprite == null:
		return
	_charge_anim_timer += delta
	var frames = []
	match _charge_phase:
		ChargeAnimPhase.MOVE:
			frames = [0, 1]
		ChargeAnimPhase.ATTACK:
			frames = [2, 3]
		ChargeAnimPhase.POST:
			frames = [4, 5]
	if frames.size() > 0:
		var idx = int(_charge_anim_timer * CHARGE_ANIM_SPEED) % frames.size()
		sprite.frame = frames[idx]
	if _charge_phase == ChargeAnimPhase.ATTACK and _charge_anim_timer >= ATTACK_PHASE_DURATION:
		_charge_phase = ChargeAnimPhase.POST
		_charge_anim_timer = 0.0

# Reset state after finishing a charge
func _end_charge() -> void:
	state = State.CHASE
	if sprite:
		sprite.play(move_anim)
	_charge_phase = ChargeAnimPhase.MOVE
	_charge_anim_timer = 0.0
	queue_redraw()

# Visualise the charge path during the warning phase
func _draw() -> void:
	if state == State.WARNING:
		var start = Vector2.ZERO
		var end = to_local(_charge_target)
		var dir = (end - start).normalized()
		var normal = dir.orthogonal() * (charge_width / 2.0)
		var pts = [start - normal, start + normal, end + normal, end - normal]
		draw_polygon(pts, [Color(1, 0, 0.4)])

func _shape_radius(shape):
	if shape is RectangleShape2D:
		return max(shape.extents.x, shape.extents.y)
	elif shape is CapsuleShape2D:
		return max(shape.radius, shape.height / 2.0)
	elif shape is CircleShape2D:
		return shape.radius
	return 0.0

func _contact_threshold():
	var r1 = 0.0
	if _col_shape and _col_shape.shape:
		r1 = _shape_radius(_col_shape.shape)
	var r2 = 0.0
	if _player_col_shape and _player_col_shape.shape:
		r2 = _shape_radius(_player_col_shape.shape)
	return attack_range + r1 + r2

# Apply contact damage when close enough to the player
func _check_contact_damage(mult = 1.0) -> void:
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= _contact_threshold():
			apply_contact_damage(player, int(dmg * mult))
