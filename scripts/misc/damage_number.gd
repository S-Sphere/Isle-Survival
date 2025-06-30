# Damage Number ----------------------------------------------------------------
"""
	Floating label showing damage dealt - slight performance hit
"""
# ------------------------------------------------------------------------------
extends Label

# Exports ----------------------------------------------------------------------
@export var float_speed = 40.0
@export var lifetime = 0.8

# Variables --------------------------------------------------------------------
var _time = 0.0
var _amount := 0

# Stores the damage value before ready
func setup(amount) -> void:
	_amount = amount

# Shows the number when the node is adde
func _ready() -> void:
	text = str(_amount)

# Moves upward and fades over time
func _process(delta) -> void:
	position.y -= float_speed * delta
	_time += delta
	modulate.a = 1.0 - clamp(_time / lifetime, 0.0, 1.0)
	if _time >= lifetime:
		queue_free()
