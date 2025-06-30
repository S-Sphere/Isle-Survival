# Weapon Manager ---------------------------------------------------------------
"""
	Script responsible for the management of the weapons the player has on the 
	run
"""
# ------------------------------------------------------------------------------
extends Node
class_name WeaponManager

# Variables --------------------------------------------------------------------
var weapons = []	# saves the weapons currently available to the player
var current_weapon_index = 0

# Adds a new weapon and connects the signal to remove it when the time comes
func add_weapon(weapon) -> void:
	weapons.append(weapon)
	add_child(weapon)
	weapon.tree_exited.connect(Callable(self, "_on_weapon_removed").bind(weapon))

# Removes the weapon from the array when it leaves the node tree
func _on_weapon_removed(weapon) -> void:
	weapons.erase(weapon)

# Calls the "fire" method for the available weapons
func fire_all_weapons() -> void:
	for weapon in weapons:
		if weapon.has_method("fire"):
			weapon.fire()

# Updates the origin of the attacks for the weapons that need it
func update_origins(origin) -> void:
	for w in weapons:
		if w.is_in_group("origin_weapon"):
			w.attack_origin = origin
