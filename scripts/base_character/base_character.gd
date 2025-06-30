# Base Character ---------------------------------------------------------------
"""
	Based Character used by the player and other entities
"""
# ------------------------------------------------------------------------------
extends CharacterBody2D
class_name BaseCharacter

# Exports ----------------------------------------------------------------------
@export var max_health = 250
@export var dmg = 5
@export var defense = 2

# Variables --------------------------------------------------------------------
var health = max_health

# Applys damage - to the player
func take_damage(amount) -> void:
	var final_amount = max(1, amount - defense)
	health -= final_amount
	if health <= 0:
		die()

# Death
func die() -> void:
	queue_free()
