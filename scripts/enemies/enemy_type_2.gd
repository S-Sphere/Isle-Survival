# Enemy Type 2 -----------------------------------------------------------------
"""
	Ranged enemy that fires at the player
"""
# ------------------------------------------------------------------------------
extends BaseEnemy

# Export -----------------------------------------------------------------------
@export var cooldown = 3.0
@export var projectile_speed = 350.0
@export var projectile_scene = preload("res://scenes/weapons/enemy_firebolt.tscn")
@export var idle_anim = "idle"
@export var attack_anim = "attack"
@export var attack_anim_duration := 0.6

# OnReady ----------------------------------------------------------------------
@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var attack_anim_timer: Timer = Timer.new()

# Variables --------------------------------------------------------------------
var shoot_timer

# Configure timers and play the idle animations
func _ready() -> void:
	super._ready()
	if max_health == BaseEnemy.DEFAULT_MAX_HEALTH:
		max_health = 60
	health = max_health
	
	if sprite:
		sprite.play(idle_anim)
		
	shoot_timer = Timer.new()
	shoot_timer.one_shot = true
	add_child(shoot_timer)
	shoot_timer.timeout.connect(_on_shoot_timer_timeout)
	_start_shoot_timer()
	
	attack_anim_timer.one_shot = true
	attack_anim_timer.wait_time = attack_anim_duration
	add_child(attack_anim_timer)
	attack_anim_timer.timeout.connect(_on_attack_anim_finished)

# Fires a projectile toward the player's current position
func shoot_at_player() -> void:
	if player and is_instance_valid(player):
		if sprite:
			sprite.play(attack_anim)
			attack_anim_timer.start()

# Spawns the projectile once the attack animation ends
func _on_attack_anim_finished() -> void:
	if sprite:
		sprite.play(idle_anim)
	
	if player and is_instance_valid(player):
		var projectile = projectile_scene.instantiate()
		projectile.is_homing = false
		projectile.global_position = global_position
		var shoot_dir = (player.global_position - global_position).normalized()
		projectile.direction = shoot_dir
		get_tree().current_scene.add_child(projectile)
	_start_shoot_timer()

# Sets the timer to a random value around the cooldown
func _start_shoot_timer() -> void:
	shoot_timer.wait_time = randf_range(cooldown * 0.5, cooldown * 1.5)
	shoot_timer.start()

# Gets called when the time to attack again comes
func _on_shoot_timer_timeout() -> void:
	shoot_at_player()
