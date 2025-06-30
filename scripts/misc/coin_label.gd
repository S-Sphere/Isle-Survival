# Coin Label -------------------------------------------------------------------
"""
	Displays the current run coin count on the HUD
"""
# ------------------------------------------------------------------------------
extends Label

# Onready ----------------------------------------------------------------------
@onready var coin_label = $"."

# Connects the signal that notifies when the coin count changes
func _ready():
	GameManager.connect("run_coins_changed", Callable(self, "_on_run_coins_changed"))
	coin_label.text = "Coins: " + str(GameManager.run_coins)

# Update the text the GameManager emits a change
func _on_run_coins_changed(current_run_coins):
	coin_label.text = "Coins: " + str(current_run_coins)
