# Water Tile -------------------------------------------------------------------
"""
	Script responsible for animation control only when the tile is visible on
	screen -> to help with performance
"""
# ------------------------------------------------------------------------------
extends Node2D
class_name WaterTile

# Exports ----------------------------------------------------------------------
@export var sprite_frames: SpriteFrames
@export var animation: String = "water"
# OnReady ----------------------------------------------------------------------
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _notifier: VisibleOnScreenNotifier2D = $VisibleNotifier

# Sprite animation and connection of the signals for visibility
func _ready() -> void:
	if sprite_frames != null:
		_sprite.sprite_frames = sprite_frames
		if _sprite.sprite_frames != null and _notifier.is_on_screen():
			_sprite.play(animation)
	_notifier.screen_entered.connect(_on_screen_entered)
	_notifier.screen_exited.connect(_on_screen_exited)

# Starts animation if on screen
func _on_screen_entered() -> void:
	if _sprite.sprite_frames != null:
		_sprite.play(animation)

# Stops animation if off screen
func _on_screen_exited() -> void:
	_sprite.stop()
