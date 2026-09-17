extends Control

@onready var hp_bar: ProgressBar = $HP_ProgressBar
@onready var hunger_bar: ProgressBar = $Hunger_ProgressBar
@onready var name_label: Label = $Name_Label
@onready var faction_label: Label = $Faction_Label
@onready var lifetime_label: Label = $Lifetime_Label
@onready var process_label: Label = $Process_Label
@onready var subprocess_label: Label = $Subprocess_Label

var target: Entity

func _init() -> void:
	visible = false

func _ready() -> void:
	Global.entity_selected.connect(_on_entity_selected)

func _process(delta: float) -> void:
	if target:
		hp_bar.value = target.max_health-target.income_damage
		hunger_bar.value = target.hunger
		lifetime_label.text = "Lifetime: %d sec" % target.lifetime
		if Global.is_tick(delta):
			update_current_task_label()
	else:
		visible = false
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT): target = null

func update_current_task_label():
	process_label.text = get_task_as_string(target)
	subprocess_label.text = get_task_as_string(target, false)

func _on_entity_selected(entity: Entity):
	target = entity
	hp_bar.max_value = target.max_health
	hunger_bar.max_value = target.max_hunger
	name_label.text = target.name
	faction_label.text = target.faction
	update_current_task_label()
	visible = true

func get_task_as_string(entity: Entity, main: bool = true) -> String:
	var task = "chill"
	if main:
		if not entity.current_task.is_empty():
			task = ""
			for key in entity.current_task.keys():
				task += str(entity.current_task[key])+" "
	else:
		task = ""
		if not entity.current_subtask.is_empty():
			for key in entity.current_subtask.keys():
				task += str(entity.current_subtask[key])+" "
			
	return task
