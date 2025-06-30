# Main Menu ----------------------------------------------------------------
"""
	Handles the title menu and the sub menus
"""
# ------------------------------------------------------------------------------
extends Control
class_name MainMenu

# OnReady ----------------------------------------------------------------------
@onready var start_button = $MarginContainer/HBoxContainer2/VBoxContainer/Start_Button as Button
@onready var settings_button = $MarginContainer/HBoxContainer2/VBoxContainer/Settings_Button as Button
@onready var exit_button = $MarginContainer/HBoxContainer2/VBoxContainer/Exit_Button as Button
@onready var settings_menu = $settings_menu as SettingsMenu
@onready var margin_container = $MarginContainer as MarginContainer
@onready var shop_button = $MarginContainer/HBoxContainer2/VBoxContainer/Shop_Button as Button
@onready var controls_button = $MarginContainer/HBoxContainer2/VBoxContainer/Controls_Button as Button
@onready var sub_menu = $MarginContainer/HBoxContainer2/SubMenu

# Scenes -----------------------------------------------------------------------
@onready var start_level = preload("res://scenes/main/main.tscn") as PackedScene
@onready var shop_scene = preload("res://scenes/main_menu/ShopMenu.tscn") as PackedScene
@onready var setting_scene = preload("res://scenes/settings_menu/settings_menu.tscn") as PackedScene
@onready var controls_scene = preload("res://scenes/main_menu/ControlsMenu.tscn") as PackedScene
@onready var map_scene = preload("res://scenes/map/map_generator.tscn")
@onready var obstacle_scene = preload("res://scenes/map/Obstacle_1.tscn")

# Variables --------------------------------------------------------------------
var shop_instance = null
var settings_instance = null
var controls_instance = null
var map_instance: Node2D
var map_zoom: float = 0.65

# Initializes buttons and preview map
func _ready():
	handle_signals()
	
	map_instance = map_scene.instantiate() as Node2D
	map_instance.obstacle_scenes = [obstacle_scene]
	map_instance.z_index = -1
	add_child(map_instance)
	move_child(map_instance, 0)
	map_instance.position = get_viewport_rect().size * 0.5
	map_instance.scale = Vector2.ONE * map_zoom
	
	sub_menu.visible = false
	if settings_instance == null and settings_menu != null:
		settings_menu.visible = false
		settings_menu.set_process(false)

# Loads the level
func on_start_pressed() -> void:
	get_tree().change_scene_to_packed(start_level)

# Closes the game window
func on_exit_pressed() -> void:
	get_tree().quit()

# Toggles the settings menu
func on_settings_pressed() -> void:
	if shop_instance != null:
		shop_instance.queue_free()
		shop_instance = null
	
	if controls_instance != null:
		controls_instance.queue_free()
		controls_instance = null

	if settings_instance == null:
		settings_instance = setting_scene.instantiate() as Control
	
		if settings_menu != null:
			settings_menu.queue_free()
			settings_menu = null
	
		sub_menu.visible = true
		sub_menu.add_child(settings_instance)
	else:
		settings_instance.queue_free()
		settings_instance = null
		sub_menu.visible = false

# Called when the settings menu closes
func on_exit_settings_menu() -> void:
	if settings_instance != null:
		settings_instance.queue_free()
		settings_instance = null
	sub_menu.visible = false

# Toggle the shop menu
func on_shop_pressed() -> void:
	if settings_instance != null:
		settings_instance.queue_free()
		settings_instance = null
	
	if controls_instance != null:
		controls_instance.queue_free()
		controls_instance = null

	if shop_instance == null:
		shop_instance = shop_scene.instantiate() as Control
		sub_menu.visible = true
		sub_menu.add_child(shop_instance)
	else:
		shop_instance.queue_free()
		shop_instance = null
		sub_menu.visible = false

# Toggles the controls menu
func on_controls_pressed() -> void:
	if settings_instance != null:
		settings_instance.queue_free()
		settings_instance = null
	
	if shop_instance != null:
		shop_instance.queue_free()
		shop_instance = null
	if controls_instance == null:
		controls_instance = controls_scene.instantiate() as Control
		sub_menu.visible = true
		sub_menu.add_child(controls_instance)
	else:
		controls_instance.queue_free()
		controls_instance = null
		sub_menu.visible = false

# Wires up all the buttons signals
func handle_signals() -> void:
	start_button.button_down.connect(on_start_pressed)
	exit_button.button_down.connect(on_exit_pressed)
	settings_button.button_down.connect(on_settings_pressed)
	controls_button.button_down.connect(on_controls_pressed)
	shop_button.button_down.connect(on_shop_pressed)
