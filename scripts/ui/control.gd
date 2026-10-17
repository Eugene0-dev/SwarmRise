extends Control

@export var camera: Camera2D
@export var world: World

@onready var info: TextEdit = $Info
@onready var target_label: Label = $Target_Label
@onready var command_line: LineEdit = $Command_LineEdit
@onready var command_history: TextEdit = $Command_History_TextEdit
@onready var command_hints_menu: ItemList = $Command_Hints_ItemList

var is_debug_on: bool = false

var target: Entity
var line_counter: int = 0
var commands_no_target: Array = [
	"clear", "select", "find", "cam", "spawn", "sector", "debug", "item"
]

func _ready() -> void:
	Global.entity_selected.connect(_on_entity_selected)
	Global.entity_unselected.connect(_on_entity_unselected)
	commands_hint_update(false)

func commands_hint_update(is_target: bool):
	command_hints_menu.clear()
	for cmd in commands_no_target:
		command_hints_menu.add_item(cmd)
	if is_target:
		for cmd in target.specific_commands:
			command_hints_menu.add_item(cmd)

func _init() -> void:
	visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("alt"): visible = !visible
	if visible and Input.is_action_just_pressed("enter"):
		command(command_line.text)
		command_line.text = ""
		line_counter = 0
		visible = false
	if Input.is_action_just_pressed("ui_up"):
		command_line.text = command_history.text.get_slice("\n", line_counter)
		line_counter += 1
	if Input.is_action_just_pressed("ui_down"):
		line_counter -= 1
		command_line.text = command_history.text.get_slice("\n", line_counter)
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) and target: 
		Global.emit_signal("entity_unselected", target)
		target = null
		target_label.text = "tg: None"
		commands_hint_update(false)

func command(cmd_line: String):
	command_history.text = cmd_line+"\n"+command_history.text
	var cmd = cmd_line.split(" ")
	var task = {}
	match cmd[0]:
		"breed":
			if target is Queen:
				target.exec_command("breed", [cmd[1]])
		"clear":
			info.text = ""
		"item":
			world.place_item(int(cmd[1]), camera.global_position)
		"cam":
			if len(cmd)>2:
				var sec = world.sectors.get(Vector2i(int(cmd[1]), int(cmd[2])))
				if sec:
					camera.position = sec.get_center()
			elif target:
				camera.position = target.position
		"find":
			match cmd[1]:
					"queen": target = world.find_child("Queen_*", true, false)
					"drone": target = world.find_child("Drone_*", true, false)
					"soldier": target = world.find_child("Soldier_*", true, false)
					"scout": target = world.find_child("Scout_*", true, false)
					"princess": target = world.find_child("Princess_*", true, false)
					_: target = world.get_node_or_null(cmd[1])
			if target:
				camera.position = target.position
				Global.emit_signal("entity_selected", target)
				
		"select":
			target = world.get_node_or_null(cmd[1])
			if target:
				Global.emit_signal("entity_selected", target)
		"spawn":
			world.create_entity(cmd[1], camera.global_position)
		"sector":
			if target:
				info.text += target.exec_command(cmd[0], cmd.slice(1))+"\n"
			else:
				var sec = world.get_sector_key(camera.global_position)
				info.text += "sec: %d %d\n" % [sec.x, sec.y]
		"debug":
			match cmd[1]:
				"nav_layer":
					if cmd[2] == "on":
						Global.emit_signal("nav_layer_enabled", world.nav_grid)
					elif cmd[2] == "off":
						Global.emit_signal("nav_layer_disabled")
				"nav_trace":
					if cmd[2] == "on" and target:
						Global.emit_signal("track_navigation_enabled", target)
					elif cmd[2] == "off":
						Global.emit_signal("track_navigation_disabled")
				"on":
					if not is_debug_on:
						is_debug_on = true
						Global.debug_node = DevFeatures.new(camera)
						get_tree().current_scene.add_child(Global.debug_node)
				"off":
					if is_debug_on:
						is_debug_on = false
						get_tree().current_scene.remove_child(Global.debug_node)
		_:
			if target:
				var output = target.exec_command(cmd[0], cmd.slice(1))
				if output:
					info.text += output+"\n"

func _on_entity_selected(entity: Entity):
	if target:
		Global.emit_signal("entity_unselected", target)
	target = entity
	target.is_outline_on = true
	target_label.text = "tg: "+entity.name
	commands_hint_update(true)

func _on_entity_unselected(entity: Entity):
	entity.is_outline_on = false

func _on_command_hints_item_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
	command_line.text = command_hints_menu.get_item_text(index)
