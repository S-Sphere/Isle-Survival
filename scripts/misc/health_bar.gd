# Health Bar -------------------------------------------------------------------
"""
	Simple Health Bar for the parent node - the player
"""
# ------------------------------------------------------------------------------
extends Node2D

# Exports ----------------------------------------------------------------------
@export var width = 40
@export var height = 6
@export var y_offset = -20

# Variables --------------------------------------------------------------------
var player

# Finds the parent and starts processing
func _ready():
	player = get_parent()
	set_process(true)

# Keeps the bar positioned above the player
func _process(_delta):
	position = Vector2(0, y_offset)
	queue_redraw()

# Renders a dark background with a red portion for the remainign health
func _draw():
	if not player:
		return
	var ratio = clamp(player.health / float(player.max_health), 0.0, 1.0)
	draw_rect(Rect2(Vector2(-width/2, 0), Vector2(width, height)), Color(0,0,0,0.6))
	draw_rect(Rect2(Vector2(-width/2, 0), Vector2(width * ratio, height)), Color(1,0,0))
