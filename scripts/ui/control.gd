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

enum commands_no_target {
	CLEAR, SELECT, FIND, CAM, SPAWN, SECTOR, DEBUG, ITEM
}

func _ready() -> void:
	Global.entity_selected.connect(_on_entity_selected)
	Global.entity_unselected.connect(_on_entity_unselected)
	commands_hint_update(false)

func commands_hint_update(has_target: bool):
	command_hints_menu.clear()
	if not has_target:
		for cmd: String in commands_no_target.keys():
			command_hints_menu.add_item(cmd.to_lower())
	if has_target:
		if not target.executor.command_extension.is_empty():
			for cmd: String in target.executor.command_extension.keys():
				command_hints_menu.add_item(cmd.to_lower())
		for cmd: String in target.executor.commands.keys():
			command_hints_menu.add_item(cmd.to_lower())

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
	var cmd = Cmd.new(cmd_line)
	var task = {}
	match cmd.type:
		100:
			if target is Queen:
				target.executor.execute(100, {"unit_type": cmd.args["unit_type"]})
		commands_no_target.CLEAR:
			info.text = ""
		commands_no_target.ITEM:
			var amount: int = 1
			if len(cmd.args) > 0: amount = cmd.args["amount"]
			world.place_item(cmd.args["item_id"], camera.global_position, amount)
		commands_no_target.CAM:
			if len(cmd)>2:
				var sec = world.sectors.get(cmd.args["pos"])
				if sec:
					camera.position = sec.get_center()
			elif target:
				camera.position = target.position
		commands_no_target.FIND:
			match cmd.args["unit_type"]:
					"queen": target = world.find_child("Queen_*", true, false)
					"drone": target = world.find_child("Drone_*", true, false)
					"soldier": target = world.find_child("Soldier_*", true, false)
					"scout": target = world.find_child("Scout_*", true, false)
					"princess": target = world.find_child("Princess_*", true, false)
					_: target = world.get_node_or_null(cmd.args["unit_type"])
			if target:
				camera.position = target.position
				Global.emit_signal("entity_selected", target)
		commands_no_target.SELECT:
			target = world.get_node_or_null(cmd.args["unit_id"])
			if target is Entity:
				Global.entity_selected.emit(target)
		commands_no_target.SPAWN:
			world.create_entity(cmd.args["unit_ref"], camera.global_position)
		commands_no_target.SECTOR:
			if target:
				info.text += target.executor.execute(cmd.type, cmd.args)+"\n"
			else:
				var sec = world.get_sector_key(camera.global_position)
				info.text += "sec: %d %d\n" % [sec.x, sec.y]
		commands_no_target.DEBUG:
			match cmd.args[0]:
				"nav_layer":
					if cmd.args[1] == "on":
						Global.emit_signal("nav_layer_enabled", world.nav_grid)
					elif cmd.args[1] == "off":
						Global.emit_signal("nav_layer_disabled")
				"nav_trace":
					if cmd.args[1] == "on" and target:
						Global.emit_signal("track_navigation_enabled", target)
					elif cmd.args[1] == "off":
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
				var command = Cmd.new(cmd_line, true)
				var output = target.executor.execute(command.type, command.args)
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

class Cmd:
	var type: int = -1
	var args: Dictionary = {}
	var cmd: PackedStringArray
	
	func _init(input: String, has_target: bool = false) -> void:
		cmd = input.split(" ", false)
		
		if cmd.is_empty() or cmd[0].is_empty():
			return
		
		if has_target:
			type = Executor.commands.get(cmd[0].to_upper(), -1)
			parse_target_cmd()
		else:
			type = commands_no_target.get(cmd[0].to_upper(), -1)
			parse_notarget_cmd()
		
	func parse_target_cmd() -> void: 
		match type:
			Executor.commands.LIFETIME:
				if cmd.size() > 1:
					args["time"] = int(cmd[1])
			Executor.commands.GIVE:
				if cmd.size() > 1:
					args["item_id"] = int(cmd[1])
				if cmd.size() > 2:
					args["amount"] = int(cmd[2])
			Executor.commands.POS:
				if cmd.size() > 2:
					args["pos"] = Vector2(
						int(cmd[1]), int(cmd[2])
					)
			Executor.commands.MV:
				if cmd.size() > 2:
					args["pos"] = Vector2(
						int(cmd[1]), int(cmd[2])
					)
			Executor.commands.MV_S:
				if cmd.size() > 2:
					args["sec_key"] = Vector2i(
						int(cmd[1]), int(cmd[2])
					)
			Executor.commands.STEP:
				if cmd.size() > 2:
					args["dest"] = Vector2(
						int(cmd[1]), int(cmd[2])
					)
			Executor.commands.PLAY:
				if cmd.size() > 1:
					args["anim_name"] = cmd[1]
			Executor.commands.AI:
				if cmd.size() > 1:
					args["option"] = cmd[1]

	func parse_notarget_cmd() -> void:
		match type:
			commands_no_target.ITEM:
				if cmd.size() > 1:
					args["item_id"] = int(cmd[1])
				if cmd.size() > 2:
					args["amount"] = int(cmd[2])
			commands_no_target.CAM:
				if cmd.size() > 2:
					args["pos"] = Vector2(
						int(cmd[1]), int(cmd[2])
					)
			commands_no_target.FIND:
				if cmd.size() > 1:
					args["unit_type"] = cmd[1]
			commands_no_target.SELECT:
				if cmd.size() > 1:
					args["unit_id"] = cmd[1]
			commands_no_target.SPAWN:
				if cmd.size() > 1:
					args["unit_ref"] = cmd[1]
			commands_no_target.DEBUG:
				if cmd.size() == 2:
					args["option"] = cmd[1]
				elif cmd.size() > 2:
					args["debug"] = cmd[1]
					args["option"] = cmd[2]
