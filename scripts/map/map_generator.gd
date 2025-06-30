# Map Generator ----------------------------------------------------------------
"""
	Constructs a map for each run
"""
# ------------------------------------------------------------------------------
extends Node2D

enum MapShape {SQUARE, CIRCLE, VERTICAL_CORRIDOR, HORIZONTAL_CORRIDOR}

# Exports ----------------------------------------------------------------------
@export var map_size = 100
@export var border_thickness = 1
@export var obstacle_scenes = []
@export var obstacle_count = 20
@export var water_scene: PackedScene
@export var water_size = 35
@onready var _water_container = $Water

# Variables --------------------------------------------------------------------
var map_width
var map_height
var shape : MapShape
var obstacle_tiles = []
var rng := RandomNumberGenerator.new()

# Entry point to generate the entire map
func _ready() -> void:
	rng.randomize()
	_select_shape()
	_build_floor()
	_build_walls()
	_create_wall_colliders()
	_scatter_obstacles()
	_add_water()

# Randomly chooses what overral shape the map will have
func _select_shape() -> void:
	var shapes = [
		MapShape.SQUARE, 
		MapShape.CIRCLE,
		MapShape.VERTICAL_CORRIDOR, 
		MapShape.HORIZONTAL_CORRIDOR
	]
	shape = shapes[rng.randi_range(0, shapes.size() - 1)]
	map_width = map_size
	map_height = map_size
	
	match shape:
		MapShape.VERTICAL_CORRIDOR:
			map_width = max(3, map_size / 2)
			map_height = int(map_size * 1.5)
		MapShape.HORIZONTAL_CORRIDOR:
			map_height = max(3, map_size / 3)
			map_width = int(map_size * 1.5)

# Fills the floor tilemap within the selected bounds
func _build_floor() -> void:
	var tm = $TileMap/TileMapLayer_floor
	tm.clear()
	var radius = min(map_width, map_height) / 2
	for x in range(int(-map_width/2), int(map_width/2)):
		for y in range(int(-map_height/2), int(map_height/2)):
			var place = true
			if shape == MapShape.CIRCLE:
				var dist = Vector2(x + 0.5, y + 0.5).length()
				place = dist <= radius
			if place:
				tm.set_cell(Vector2i(x, y), 0, Vector2i.ZERO)

# Draws a border of wall tiles around the playable area
func _build_walls() -> void:
	var tm = $TileMap/TileMapLayer2_wall
	tm.clear()
	if shape == MapShape.CIRCLE:
		var radius = min(map_width, map_height) / 2.0
		for x in range(int(-radius - border_thickness), int(radius + border_thickness)):
			for y in range(int(-radius - border_thickness), int(radius + border_thickness)):
				var dist = Vector2(x + 0.5, y + 0.5).length()
				if dist >= radius and dist < radius + border_thickness:
					tm.set_cell(Vector2i(x, y), 1, Vector2i.ZERO)
	else:
		var x_min = int(-map_width / 2)
		var x_max = int(map_width / 2) - 1
		var y_min = int(-map_height / 2)
		var y_max = int(map_height / 2) - 1
		for i in range(1, border_thickness + 1):
			for x in range(x_min - i, x_max + i + 1):
				tm.set_cell(Vector2i(x, y_min - i), 1, Vector2i.ZERO)
				tm.set_cell(Vector2i(x, y_max + i), 1, Vector2i.ZERO)
			for y in range(y_min - i, y_max + i + 1):
				tm.set_cell(Vector2i(x_min - i, y), 1, Vector2i.ZERO)
				tm.set_cell(Vector2i(x_max + i, y), 1, Vector2i.ZERO)

# Spawns physics bodies that match each wall tile
func _create_wall_colliders() -> void:
	var parent = get_node_or_null("WallColliders")
	if parent == null:
		push_warning("WallColliders node missing")
		return
	for child in parent.get_children():
		child.queue_free()
	var tm = $TileMap/TileMapLayer2_wall
	var tile_size = tm.tile_set.tile_size
	for cell in tm.get_used_cells():
		var body = StaticBody2D.new()
		body.collision_layer = 16
		body.collision_mask = 5
		var shape = RectangleShape2D.new()
		shape.size = tile_size
		var collider = CollisionShape2D.new()
		collider.shape = shape
		body.position = tm.map_to_local(cell) + tile_size * 0.5
		body.add_child(collider)
		parent.add_child(body)

# Places water sprites around the outside of the map 
func _add_water() -> void:
	if _water_container == null or water_scene == null:
		return
	for child in _water_container.get_children():
		child.queue_free()
	var tm = $TileMap/TileMapLayer_floor
	var tile_size = tm.tile_set.tile_size
	_water_container.z_index = -1
	if shape == MapShape.CIRCLE:
		var radius = min(map_width, map_height) / 2.0
		var inner = radius + border_thickness
		var outer = inner + water_size
		
		for x in range(int(-outer), int(outer)):
			for y in range(int(-outer), int(outer)):
				var dist = Vector2(x + 0.5, y + 0.5).length()
				if dist >= inner and dist < outer:
					var sprite = water_scene.instantiate() as Node2D
					sprite.position = tm.map_to_local(Vector2i(x, y)) + tile_size * 0.5
					sprite.z_index = -1
					_water_container.add_child(sprite)
	else:
		var x_min = int(-map_width / 2) - border_thickness
		var x_max = int(map_width / 2) + border_thickness - 1
		var y_min = int(-map_height / 2) - border_thickness
		var y_max = int(map_height / 2) + border_thickness - 1
		for i in range(1, water_size + 1):
			var ix_min = x_min - i
			var ix_max = x_max + i
			var iy_min = y_min - i
			var iy_max = y_max + i
			for x in range(ix_min, ix_max + 1):
				for y in [iy_min, iy_max]:
					var sprite = water_scene.instantiate() as Node2D
					sprite.position = tm.map_to_local(Vector2i(x, y)) + tile_size * 0.5
					sprite.z_index = -1
					_water_container.add_child(sprite)
			for y in range(iy_min, iy_max + 1):
				for x in [ix_min, ix_max]:
					var sprite = water_scene.instantiate() as Node2D
					sprite.position = tm.map_to_local(Vector2i(x, y)) + tile_size * 0.5
					sprite.z_index = -1
					_water_container.add_child(sprite)

# Randomly places obstacles while avoiding overlap
func _scatter_obstacles() -> void:
	var parent = $Obstacles
	if obstacle_scenes.is_empty():
		return
	var placed = 0
	var attempts = 0
	var tm = $TileMap/TileMapLayer_floor
	var tile_size = tm.tile_set.tile_size
	while placed < obstacle_count and attempts < obstacle_count * 10:
		attempts += 1
		var x = rng.randi_range(int(-map_width/2) + border_thickness, int(map_width/2) - border_thickness)
		var y = rng.randi_range(int(-map_height/2) + border_thickness, int(map_height/2) - border_thickness)
		var tile = Vector2i(x, y)
		var occupied = false
		for nx in range(tile.x - 1, tile.x + 2):
			for ny in range(tile.y - 1, tile.y + 2):
				var n = Vector2i(nx, ny)
				if not _tile_in_bounds(n) or obstacle_tiles.has(n):
					occupied = true
					break
			if occupied:
				break
		if occupied:
			continue
		if shape == MapShape.CIRCLE:
			var radius = min(map_width, map_height) / 2.0 - border_thickness
			if Vector2(x + 0.5, y + 0.5).length() > radius:
				continue
		var scene = obstacle_scenes[rng.randi_range(0, obstacle_scenes.size() - 1)]
		var obs = scene.instantiate() as Node2D
		var world_pos = tm.map_to_local(Vector2i(x, y)) + tile_size * 0.5
		obs.position = world_pos
		parent.add_child(obs)
		for nx in range(tile.x - 1, tile.x + 2):
			for ny in range(tile.y - 1, tile.y + 2):
				var n = Vector2i(nx, ny)
				if _tile_in_bounds(n) and not obstacle_tiles.has(n):
					obstacle_tiles.append(n)
		placed += 1

# Helper function fo check if a tile coordinate is within playable bounds
func _tile_in_bounds(tile) -> bool:
	if tile.x < int(-map_width/2) + border_thickness or tile.x > int(map_width/2) - border_thickness:
		return false
	if tile.y < int(-map_height/2) + border_thickness or tile.y > int(map_height/2) - border_thickness:
		return false
	if shape == MapShape.CIRCLE:
		var radius = min(map_width, map_height) / 2.0 - border_thickness
		if Vector2(tile.x + 0.5, tile.y + 0.5).length() > radius:
			return false
	return true

# Returns true if tile is within bounds and free of obstacles
func is_tile_free(tile) -> bool:
	return _tile_in_bounds(tile) and not obstacle_tiles.has(tile)

# Convers a world position to tile coordinates and test for obstacles
func is_position_free(pos) -> bool:
	var tm = $TileMap/TileMapLayer_floor
	var tile = tm.local_to_map(to_local(pos))
	return is_tile_free(tile)

# Keeps a world position within the map bounds, and return the clamped value
func clamp_position_to_map(pos) -> Vector2:
	var tm = $TileMap/TileMapLayer_floor
	var map_pos = tm.local_to_map(to_local(pos))
	if not _tile_in_bounds(map_pos):
		var x_min = int(-map_width / 2) + border_thickness
		var x_max = int(map_width / 2) - border_thickness
		var y_min = int(-map_height / 2) + border_thickness
		var y_max = int(map_height / 2) - border_thickness
		
		map_pos.x = clamp(map_pos.x, x_min, x_max)
		map_pos.y = clamp(map_pos.y, y_min, y_max)
		
		if shape == MapShape.CIRCLE:
			var radius = min(map_width, map_height) / 2.0 - border_thickness
			var vec = Vector2(map_pos.x + 0.5, map_pos.y + 0.5)
			if vec.length() > radius:
				vec = vec.normalized() * radius
				map_pos = Vector2i(int(floor(vec.x)), int(floor(vec.y)))
	return tm.map_to_local(map_pos) + tm.tile_set.tile_size * 0.5

# Picks a random free tile and converts it to a world position
func get_random_spawn_position():
	var tm = $TileMap/TileMapLayer_floor
	var tile_size = tm.tile_set.tile_size
	while true:
		var x = rng.randi_range(int(-map_width/2) + border_thickness, int(map_width/2) - border_thickness)
		var y = rng.randi_range(int(-map_height/2) + border_thickness, int(map_height/2) - border_thickness)
		var tile = Vector2i(x, y)
		if _tile_in_bounds(tile) and not obstacle_tiles.has(tile):
			return tm.map_to_local(tile) + tile_size * 0.5
