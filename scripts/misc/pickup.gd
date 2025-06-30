# Pickup -----------------------------------------------------------------------
"""
	Genereric pickup item that grants XP, coins or health
"""
# ------------------------------------------------------------------------------
extends Area2D

# Exports ----------------------------------------------------------------------
@export var pickup_type : String
@export var value 		: int

# Makes it so that the player can find pickups
func _ready() -> void:
	add_to_group("pickup")
	connect("body_entered", Callable(self, "_on_body_entered"))

# Only reacts when the player touches the pickup
func _on_body_entered(body) -> void:
	if not body.is_in_group("player"):
		return
	match pickup_type:
		"xp":
			GameManager.gain_experience(value)
		"coin":
			GameManager.gain_coins(value)
		"health":
			GameManager.heal_player(value)
	
	queue_free()
