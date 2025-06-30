# Settings Menu ----------------------------------------------------------------
"""
	Settings Menu, not really needed.
"""
# ------------------------------------------------------------------------------
class_name SettingsMenu 
extends Control

# Signals ----------------------------------------------------------------------
signal exit_settings_menu

# Disables the process until the menu is shown.
func _ready():
	set_process(false)
