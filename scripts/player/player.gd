# Player -----------------------------------------------------------------------
"""
	Controls the main player character
"""
# ------------------------------------------------------------------------------
extends BaseCharacter

# Exports ----------------------------------------------------------------------
@export var starting_upgrade: Upgrade
@export var movement_speed = 65.0
@export var magnet_range = 0.0
@export var magnet_speed = 150.0

# Variables --------------------------------------------------------------------
var weapon_manager

# OnReady ----------------------------------------------------------------------
@onready var sprite: AnimatedSprite2D = $Sprite2D

# Its called when the node enters the tree
func _ready() -> void:
	GameManager.register_player(self)
	
	weapon_manager = WeaponManager.new()
	add_child(weapon_manager)
	
	GameManager.upgrade_levels.clear()
	GameManager.upgrade_levels[starting_upgrade.stat + starting_upgrade.weapon_scene.resource_path] = 1
	GameManager._apply_upgrade(starting_upgrade, 1)

# Updates movement and weapon positions every frame
func _physics_process(_delta):
	movement()
	weapon_manager.update_origins(global_position)
	_magnet_pull(_delta)

# Basic WASD style movement
func movement():
	var x_mov = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var y_mov = Input.get_action_strength("move_down") - Input.get_action_strength("move_up") # up is minus and down is plus
	var mov = Vector2(x_mov, y_mov)
	velocity = mov.normalized() * movement_speed
	if mov != Vector2.ZERO:
		sprite.play("run")
		sprite.flip_h = x_mov < 0
	else:
		sprite.stop()
	move_and_slide()

# Attracts nearby pickups toward the player
func _magnet_pull(delta) -> void:
	if magnet_range <= 0:
		return
	for p in get_tree().get_nodes_in_group("pickup"):
		if not p.is_inside_tree():
			continue
		if global_position.distance_to(p.global_position) <= magnet_range:
			p.global_position = p.global_position.move_toward(global_position, magnet_speed * delta)

# Adds experience when a enemy dies
func _on_enemy_defeated(xp_amount) -> void:
	GameManager.gain_experience(xp_amount)

# When the player dies, the current run ends
func die() -> void:
	GameManager.run_won = false
	GameManager.end_run()
	super.die()
