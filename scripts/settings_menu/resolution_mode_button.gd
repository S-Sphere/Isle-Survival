# Resolution Mode Button -------------------------------------------------------
"""
	Responsible for the persistent upgrades. Saves the information on a JSON 
	file
"""
# ------------------------------------------------------------------------------
extends Control

# OnReady ----------------------------------------------------------------------
@onready var option_button = $HBoxContainer/OptionButton as OptionButton
@onready var window_mode_button = get_parent().get_node("Window_Mode_Button")

# Values -----------------------------------------------------------------------
const RESOLUTION_DICT : Dictionary = {
	"1152 x 648" : Vector2i(1152, 648),
	"1280 x 720" : Vector2i(1280, 720),
	"1920 x 1080" : Vector2i(1920, 1080)
}

# Variables --------------------------------------------------------------------
var DISPLAY_RESOLUTION_KEYS : Array = RESOLUTION_DICT.keys()

func _ready():
	add_resolution_items()
	current_resolution()
	option_button.item_selected.connect(on_resolution_selected)
	if window_mode_button.has_signal("window_mode_changed"):
		window_mode_button.window_mode_changed.connect(update_disabled_state)
	update_disabled_state()

# Adds the available resolutions to the OptionButton
func add_resolution_items() -> void:
	for resolution_size in RESOLUTION_DICT:
		option_button.add_item(resolution_size)

# Detects the resolution of the window and selects it
func current_resolution() -> void:
	var mode = DisplayServer.window_get_mode()
	var current_size = DisplayServer.window_get_size()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		current_size = DisplayServer.screen_get_size()
		
	var index = RESOLUTION_DICT.values().find(current_size)
	if index != -1:
		option_button.select(index)

# Centers the window after changing the resolution
func centre_window() -> void:
	var centre_screen = DisplayServer.screen_get_position() + DisplayServer.screen_get_size()/2
	var window_size = get_window().get_size_with_decorations()
	get_window().set_position(centre_screen - window_size/2)

# Disables the resolution button if in FullScreen
func update_disabled_state() -> void:
	var mode = DisplayServer.window_get_mode()
	option_button.disabled = mode == DisplayServer.WINDOW_MODE_FULLSCREEN

# Applys the chosen resolution
func on_resolution_selected(index : int) -> void:
	var resolution = RESOLUTION_DICT.values()[index]
	DisplayServer.window_set_size(resolution)
	centre_window()
