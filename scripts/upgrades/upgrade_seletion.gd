# Upgrade Selection -------------------------------------------------------------
"""
	Script for the upgrade selection menu
"""
# ------------------------------------------------------------------------------
extends Control
class_name UpgradeSelection

# Signals ----------------------------------------------------------------------
signal upgrade_chosen(upgrade_data)
# Exports ----------------------------------------------------------------------
@export var option_count = 3
# Variables --------------------------------------------------------------------
var _buttons = []
var _choices = [] # the choices that show up this time
var _all_upgrades = [] # all the choices for upgrades

# Prepares the buttons
func _ready():
	_buttons = [
		$HBoxContainer/Button,
		$HBoxContainer/Button2,
		$HBoxContainer/Button3
	]
	for btn in _buttons:
		btn.pressed.connect(Callable(self, "_on_button_pressed").bind(btn))
	visible = false

# Randomly chooses the option that will show up
func popup(upgrades) -> void:
	_all_upgrades = upgrades.duplicate()
	_all_upgrades.shuffle()
	_choices = _all_upgrades.slice(0, min(option_count, _all_upgrades.size()))
	for i in range(option_count):
		var up = _choices[i]
		var btn = _buttons[i]
		btn.text = up.name
		if up.description != "":
			btn.text += "\n" + up.description
		if up.icon:
			btn.icon = up.icon
		else:
			btn.icon = null
		btn.tooltip_text = ""
	for j in range(_choices.size(), option_count):
		_buttons[j].visible = false
	visible = true

# Called when the player makes a choice
func _on_button_pressed(btn: Button) -> void:
	var idx = _buttons.find(btn)
	var picked = _choices[idx]
	emit_signal("upgrade_chosen", picked)
	unpause_and_close()

# Closes the menu and goes back to the game
func unpause_and_close() -> void:
	get_tree().paused = false
	queue_free()

# What it says
func show_menu() -> void:
	visible = true
