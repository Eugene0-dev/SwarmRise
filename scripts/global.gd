extends Node

var debug_node: DevFeatures

const DAY_LENGTH: int = 1200
var current_tick: int = 0
var hour: int = 0
var day: int = 0
var month: int = 0
var year: int = 0

func throw_dice(d: int, val: int) -> bool:
	return randi_range(1, d) <= val

var timer: float = 0.0
func is_tick(delta: float) -> bool:
	timer += delta
	if timer >= 1.0:
		timer = 0.0
		return true
	return false

func calendar() -> void:
	if current_tick % (DAY_LENGTH / 24) == 0:
		hour += 1
		if hour == 24: hour = 0
	if current_tick % DAY_LENGTH == 0:
		day += 1
	if day == 30:
		month += 1
		day = 0
	if month == 10:
		year += 1
		month = 0

func _process(delta: float) -> void:
	if is_tick(delta):
		emit_signal("tick")
		current_tick += 1
		calendar()

signal tick()

signal save_game()

signal place_item(item_id, pos)

signal grow_plant(type, pos)

signal entity_selected(entity)

signal entity_unselected(entity)

signal track_navigation_enabled(entity)

signal track_navigation_disabled()

signal nav_layer_enabled(nav_grid)

signal nav_layer_disabled()
