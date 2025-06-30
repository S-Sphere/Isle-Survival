# XP Bar -----------------------------------------------------------------------
"""
	Script responsible for updating the XP Bar, and for showing the current 
	player level.
"""
# ------------------------------------------------------------------------------
extends TextureProgressBar

# OnReady ----------------------------------------------------------------------
@onready var level_label = $MarginContainer/LevelLabel

func _ready():
	# conects to the signal emited every time XP changes
	GameManager.connect("xp_changed", Callable(self, "_on_xp_changed"))
	# defines the max and current values for the bar
	max_value = GameManager.xp_to_next_level
	value = GameManager.xp
	# shows the lvl of the player in the label
	level_label.text = "LV " + str(GameManager.level)
	
func _on_xp_changed(current_xp, xp_cap):
	# changes the values of the bar when XP changes
	max_value = xp_cap
	value = current_xp
	# updates the label with the current lvl
	level_label.text = "LV " + str(GameManager.level)
