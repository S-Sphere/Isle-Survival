# End Screen -------------------------------------------------------------------
"""
	Displays final run stats and actions
"""
# ------------------------------------------------------------------------------
extends CanvasLayer

# OnReady ----------------------------------------------------------------------
@onready var coins_label = $ColorRect/VBoxContainer/CoinsLabel
@onready var level_label = $ColorRect/VBoxContainer/LevelLabel
@onready var kills_label = $ColorRect/VBoxContainer/KillsLabel
@onready var time_label = $ColorRect/VBoxContainer/TimeLabel
@onready var result_label = $ColorRect/VBoxContainer/ResultLabel
@onready var upgrades_label = $ColorRect/VBoxContainer/UpgradesLabel
@onready var retry_button = $ColorRect/VBoxContainer/Buttons/RetryButton
@onready var menu_button = $ColorRect/VBoxContainer/Buttons/MenuButton

# Hooks up buttons actions
func _ready():
	retry_button.pressed.connect(_on_retry_pressed)
	menu_button.pressed.connect(_on_menu_pressed)

# Updates the labels with the stats
func show_stats(data: Dictionary) -> void:
	var won = data.get("won", false)
	result_label.text = "You Won!" if won else "You Died"
	result_label.self_modulate = Color(0, 1, 0) if won else Color(1, 0, 0)
	coins_label.text = "Coins: %d" % data.get("coins", 0)
	level_label.text = "Level Reached: %d" % data.get("level", 1)
	kills_label.text = "Kills: %d" % data.get("kills", 0)
	var t = int(data.get("time", 0))
	time_label.text = "Time Survived: %s" % GameManager.format_time(t)
	var upg = data.get("upgrades", [])
	if upg.size() > 0:
		upgrades_label.text = "Upgrades:\n" + ", ".join(upg)
	else:
		upgrades_label.text = "Upgrades: None"

# Starts a new run
func _on_retry_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/main.tscn")

# Returns to the main menu
func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")
