# Upgrade Resource -------------------------------------------------------------
"""
	Basic resource to make Upgrades
"""
# ------------------------------------------------------------------------------
extends Resource
class_name Upgrade

# Basic Upgrade
@export var name: String
@export var description: String
@export var icon: Texture2D

@export var stat: String # attribute affected
@export var values: Array[float] # defines value effect by level (not for weapons)

# For the upgrades that are weapons
@export var weapon_scene: PackedScene
@export var max_level: int = 3

# Returns the value of the upgrade for the specified level
func amount_for(level: int) -> float:
	if values.is_empty():
		return 0.0
	var idx = clamp(level - 1, 0, values.size() - 1)
	return values[idx]
