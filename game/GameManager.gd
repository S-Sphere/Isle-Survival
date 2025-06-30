# Save Manager -----------------------------------------------------------------
"""
	It controls everything
"""
# ------------------------------------------------------------------------------
extends Node

# Signals ----------------------------------------------------------------------
signal xp_changed(current_xp, xp_cap)
signal coins_changed(current_coins)
signal run_coins_changed(current_run_coins)
signal health_changed(current_health, max_health)
signal kills_changed(current_kills)

# Exports ----------------------------------------------------------------------
@export var upgrade_scene: PackedScene = preload("res://scenes/ui/upgrade_seletion.tscn")
@export var end_screen_scene = preload("res://scenes/ui/end_screen.tscn")
@export var pause_menu_scene = preload("res://scenes/ui/pause_menu.tscn")
const DAMAGE_NUMBER_SCENE_PATH := "res://scenes/ui/DamageNumber.tscn"
@export var damage_number_scene: PackedScene = preload(DAMAGE_NUMBER_SCENE_PATH)
@export var all_upgrades: Array[Resource] = [
	preload("res://data/upgrades/health_upgrade.tres"),
	preload("res://data/upgrades/damage_upgrade.tres"),
	preload("res://data/upgrades/speed_upgrade.tres"),
	preload("res://data/upgrades/magnet_upgrade.tres"),
	preload("res://data/upgrades/defense_upgrade.tres"),
	preload("res://data/upgrades/radial_weapon.tres"),
	preload("res://data/upgrades/firebolt_weapon.tres"),
	preload("res://data/upgrades/lightning_weapon.tres"),
	preload("res://data/upgrades/aura_weapon.tres")
]
@export var time_limit_sec = 600 # 15 minutes -> 900

# Variables --------------------------------------------------------------------
var xp = 0
var level = 1
var xp_to_next_level = 100
var player = null
var coins = 0
var run_coins = 0
var kills = 0
var start_time = 0
var run_time_sec = 0.0
var pending_level_ups = 0
var upgrade_menu_open = false
var damage_numbers_enabled = true
var enemies = []
var run_won = false
var upgrade_levels = {}
# Enable or disable damage number
func set_damage_numbers_enabled(enabled) -> void:
	damage_numbers_enabled = enabled
	if enabled:
		damage_number_scene = load(DAMAGE_NUMBER_SCENE_PATH)
	else:
		damage_number_scene = null

# Return the elapsed time in seconds
func get_run_time() -> int:
	return int(run_time_sec)

# Format a seconds value as M:SS
func format_time(secs) -> String:
	if secs < 60:
		return "%ds" % secs
	return "%d:%02d" % [secs / 60, secs % 60]

# Get the current run time as a formatted string
func get_run_time_string() -> String:
	return format_time(get_run_time())

# Collate current run stats for saving or displaying
func get_run_stats():
	var upgrade_texts = []
	for key in upgrade_levels.keys():
		var lvl = upgrade_levels[key]
		var name = key
		for upg in all_upgrades:
			var k = upg.stat
			if upg.weapon_scene:
				k += upg.weapon_scene.resource_path
			if k == key:
				name = upg.name
				break
		upgrade_texts.append("%s Lv %d" % [name, lvl])
	return {
		"coins": run_coins,
		"level": level,
		"kills": kills,
		"time": int(run_time_sec),
		"upgrades": upgrade_texts,
		"won" : run_won
	}

# Load saved data and initialise coin count
func _ready() -> void:
	SaveManager.load_json()
	coins = int(SaveManager.data.get("coins", 0))
	emit_signal("coins_changed", coins)
	set_process(true)

# Track run time each frame and check for time limit
func _process(delta) -> void:
	if player != null:
		run_time_sec += delta
		if run_time_sec >= time_limit_sec:
			run_won = true
			end_run()

# Keep track of each enemy instance for targeting and statistics
func register_enemy(enemy) -> void:
	if enemy not in enemies:
		enemies.append(enemy)

# Remove an enemy from tracking when it dies
func unregister_enemy(enemy) -> void:
	enemies.erase(enemy)

# Store the player reference and apply persistent stat upgrades
func register_player(player) -> void:
	self.player = player
	var stats = SaveManager.data.get("player_stats", {})
	if stats.has("health"):
		player.max_health += stats["health"]
		player.health = player.max_health
	if stats.has("speed"):
		player.movement_speed += stats["speed"]
	if stats.has("defense"):
		player.defense += stats["defense"]
	if stats.has("magnet"):
		player.magnet_range += stats["magnet"]
	start_run()

# Heal the player without exceeding max health
func heal_player(amount) -> void:
	if player:
		player.health = min(player.max_health, player.health + amount)
		emit_signal("health_changed", player.health, player.max_health)

# Increase XP and queue level-ups when thresholds are reached
func gain_experience(amount) -> void:
	xp += amount
	emit_signal("xp_changed", xp, xp_to_next_level)
	while xp >= xp_to_next_level:
		level += 1
		xp -= xp_to_next_level
		xp_to_next_level = int(xp_to_next_level) * 1.2
		pending_level_ups += 1
		emit_signal("xp_changed", xp, xp_to_next_level)
	if not upgrade_menu_open and pending_level_ups > 0:
		show_upgrade_selection()

# Display a popup with upgrade options when leveling up
func show_upgrade_selection() -> void:
	var choices = []
	for upg in all_upgrades:
		var key = upg.stat
		if upg.weapon_scene:
			key += upg.weapon_scene.resource_path
		var lvl = upgrade_levels.get(key,0)
		if lvl < upg.max_level:
			choices.append(upg)
	if choices.is_empty():
		get_tree().paused = false
		return
	
	var upgrade_ui = upgrade_scene.instantiate()
	var scene = get_tree().current_scene
	if scene == null:
		return
	var ui = scene.get_node_or_null("UI")
	if ui == null:
		return
	
	upgrade_menu_open = true
	ui.add_child(upgrade_ui)
	get_tree().paused = true
	upgrade_ui.popup(choices)
	upgrade_ui.upgrade_chosen.connect(Callable(self, "_on_upgrade_chosen"))

# Apply the upgrade that the player selected
func _on_upgrade_chosen(chosen) -> void:
	var key = chosen.stat + (chosen.weapon_scene.resource_path if chosen.weapon_scene != null else "")
	var lvl = upgrade_levels.get(key, 0)
	if lvl >= chosen.max_level:
		return
	
	lvl += 1
	upgrade_levels[key] = lvl
	_apply_upgrade(chosen, lvl)
	pending_level_ups = max(pending_level_ups - 1, 0)
	upgrade_menu_open = false
	get_tree().paused = false
	call_deferred("_show_next_queued_upgrade")

# Apply stat modifications or add weapons based on the upgrade
func _apply_upgrade(upgrade, lvl) -> void:
	var amount = upgrade.amount_for(lvl)
	match upgrade.stat:
		"health":
			player.max_health += amount
		"damage":
			player.dmg += amount
		"speed":
			player.movement_speed += amount
		"defense":
			player.defense += amount
		"magnet":
			player.magnet_range += amount
		"fire_rate":
			for w in player.weapon_manager.weapons:
				w.cooldown = max(0.1, w.cooldown - amount)
		"weapon":
			if upgrade.weapon_scene:
				var scene_path = upgrade.weapon_scene.resource_path
				if lvl == 1:
					var new_weapon = upgrade.weapon_scene.instantiate()
					player.weapon_manager.add_weapon(new_weapon)
				else:
					for w in player.weapon_manager.weapons:
						if w.get_scene_file_path() == scene_path:
							w.level = lvl
							break
		_:
			push_warning("Unknown upgrade type: %s" % upgrade.stat)
	get_tree().paused = false

# Show another upgrade if multiple level-ups happened at once
func _show_next_queued_upgrade() -> void:
	if pending_level_ups > 0:
		show_upgrade_selection()

# Increase the player's coin count
func gain_coins(amount) -> void:
	if player != null and amount > 0:
		run_coins += amount
		emit_signal("run_coins_changed", run_coins)
	else:
		coins += amount
		emit_signal("coins_changed", coins)
		SaveManager.data["coins"] = coins
		SaveManager.save_json()

# Clear the coins earned during the current run
func reset_run_coins() -> void:
	run_coins = 0
	emit_signal("run_coins_changed", run_coins)

# Initialise variables and timers at the start of a run
func start_run() -> void:
	reset_run_coins()
	kills = 0
	start_time = Time.get_ticks_msec()
	run_time_sec = 0.0
	run_won = false
	xp = 0
	level = 0
	xp_to_next_level = 100
	pending_level_ups = 0
	upgrade_menu_open = false
	enemies.clear()
	emit_signal("xp_changed", xp, xp_to_next_level)

# Update kill count statistics
func incr_kills(amount = 1) -> void:
	kills += amount
	emit_signal("kills_changed", kills)

# Because of the end/pause menu
func set_timer_visible(visible: bool) -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var timer = scene.get_node_or_null("Hud/Timer Label")
	if timer:
		timer.visible = visible

# Handle the end-of-run flow and show the end screen
func end_run() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var ui = scene.get_node_or_null("UI")
	if ui == null:
		return
	
	var stats = get_run_stats()
	coins += run_coins
	emit_signal("coins_changed", coins)
	SaveManager.data["coins"] = coins
	SaveManager.save_json()
	enemies.clear()
	var timer = scene.get_node_or_null("Hud/Timer Label")
	set_timer_visible(false)
	var end_screen = end_screen_scene.instantiate()
	ui.add_child(end_screen)
	get_tree().paused = true
	end_screen.show_stats(stats)

# Bring up the pause screen with current run info
func show_pause_menu() -> void:
	var scene = get_tree().current_scene
	if scene == null:
		return
	var ui = scene.get_node_or_null("UI")
	if ui == null:
		return
	set_timer_visible(false)
	var pause_menu = pause_menu_scene.instantiate()
	ui.add_child(pause_menu)
	get_tree().paused = true
	pause_menu.show_stats(get_run_stats())

# Allow pausing with the cancel action
func _input(event) -> void:
	if player != null and event.is_action_pressed("ui_cancel") and not get_tree().paused:
		show_pause_menu()
