# Enemy Spawner -----------------------------------------------------------------
"""
	Periodically Spawns enemies 
"""
# ------------------------------------------------------------------------------
extends Node2D

# Exports ----------------------------------------------------------------------
@export var spawns: Array[SpawnInfo] = []

# OnReady ----------------------------------------------------------------------
@onready var player = get_tree().get_first_node_in_group("player")
@onready var map_generator = get_parent().get_node("MapGenerator")

# Variables --------------------------------------------------------------------
var time = 0

# Starts the delay counter
func _ready():
	for spawn in spawns:
		spawn.spawn_delay_counter = spawn.enemy_spawn_delay

# Wait until time and then spawn the configured number of enemies
func _on_timer_timeout():
	time += 1
	var enemy_spaws = spawns
	for i in enemy_spaws:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				var new_enemy = i.enemy
				var counter = 0
				while counter < i.enemy_number:
					var enemy_spawn = new_enemy.instantiate()
					if i.override_health >= 0:
						enemy_spawn.max_health = i.override_health
						enemy_spawn.health = i.override_health
					else:
						enemy_spawn.health = enemy_spawn.max_health
					if i.override_dmg >= 0:
						enemy_spawn.dmg = i.override_dmg
					enemy_spawn.global_position = get_random_position()
					add_child(enemy_spawn)
					counter += 1

# Picks a random position
func get_random_position():
	var vpr = get_viewport_rect().size * randf_range(0.5, 1.0)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up", "down", "right", "left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2= bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
	
	var attempt = 0
	while attempt < 10:
		var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
		var y_spawn = randf_range(spawn_pos1.y, spawn_pos2.y)
		var pos = Vector2(x_spawn, y_spawn)
		pos = map_generator.clamp_position_to_map(pos)
		if map_generator.is_position_free(pos):
			return pos
		attempt += 1
	return map_generator.get_random_spawn_position()
