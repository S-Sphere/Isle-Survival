# Damage Numbers Button --------------------------------------------------------
"""
	Setting that toggles the damage numbers
"""
# ------------------------------------------------------------------------------
extends Control

# Onready ----------------------------------------------------------------------
@onready var check_button = $HBoxContainer/CheckButton as CheckButton

# Loads saved choice and applies it
func _ready() -> void:
	var settings = SaveManager.data.get("settings", {})
	var show = settings.get("show_damage_numbers", true)
	check_button.button_pressed = show
	GameManager.set_damage_numbers_enabled(show)
	check_button.toggled.connect(_on_toggled)

# Saves the new choice
func _on_toggled(pressed: bool) -> void:
	var settings = SaveManager.data.get("settings", {})
	settings["show_damage_numbers"] = pressed
	SaveManager.data["settings"] = settings
	SaveManager.save_json()
	GameManager.set_damage_numbers_enabled(pressed)
