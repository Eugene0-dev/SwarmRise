@tool
class_name Entity 
extends CharacterBody2D 

@export var sprite_frames: SpriteFrames:
	set(val):
		sprite_frames = val
		if is_inside_tree():
			sprite.sprite_frames = sprite_frames
			_sync_outline()

@export_group("Title")
@export var type_name: String = "none"
@export var group: String = "none"

@export_group("Stats")
@export var lifetime: int = 3600
@export var max_health: int = 100
var income_damage: int = 0

@export var outcome_damage: int = 5
@export var max_hunger: int = 100
var hunger: int = 0

@export var faction: String = "none"
@export var speed: int = 10

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var outline: AnimatedSprite2D = $Outline_Sprite

@onready var sight_area: Area2D = $Sight_Area
@onready var collision: CollisionShape2D = $CollisionShape2D

@onready var hold_item: Node2D = $Sight_Area/Hold_Item_Slot

@export_group("Variables")
@export var is_outline_on: bool = false

var knowledges: Dictionary = {}

var is_ai_enabled: bool = true
var schedule: Array = []
var current_task: Dictionary = {}

var subtasks: Array = []
var current_subtask: Dictionary = {}
var stuck_timer: float = 0.0
var STUCK_THRESHOLD: float = 3.0
var last_position: Vector2

var environment: World
var specific_commands: Array = [
	"step", "mv", "mv_s", "pos", "give", "drop", "eat", "feed", "expire", "lifetime", "kill", "play", "stop", "stopall", "st", "team", "ai"
]
var prefered_pos: Vector2
enum direction {UP, DOWN, LEFT, RIGHT}
@export var face_dir: direction = direction.DOWN

var current_sector: Vector2i
var old_sector: Vector2i

func _ready() -> void:
	_sync_outline()
	Global.tick.connect(_on_tick)
	face_dir = direction.DOWN
	idle()
	prefered_pos = global_position
	if environment:
		create_tween().tween_property(self, "scale", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_SINE)
		current_sector = environment.get_sector_key(global_position)

func _sync_outline() -> void:
	outline.sprite_frames = sprite.sprite_frames
	outline.position = sprite.position
	outline.animation = sprite.animation
	outline.frame = sprite.frame
	outline.scale = sprite.scale

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and \
	event.button_index == MOUSE_BUTTON_LEFT\
	and event.pressed:
		Global.emit_signal("entity_selected", self)

func _process(delta: float) -> void:
	outline.visible = is_outline_on
	if is_outline_on:
		_sync_outline()

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		idle()
		return
		
	if not current_subtask.is_empty():
		exec_subtask(current_subtask)
	elif not subtasks.is_empty():
		current_subtask = subtasks.pop_front()
		exec_subtask(current_subtask)
	elif not current_task.is_empty():
		exec_task(current_task) 
	elif not schedule.is_empty():
		current_task = schedule.pop_front()
	else: idle()

func _on_tick() -> void:
	lifetime -= 1
	if lifetime <= 0:
		on_lifetime_end()
	if hunger < max_hunger:
		hunger += 1
	if income_damage > max_health: 
		die()
		return
	if hunger >= max_hunger: income_damage+=1
	elif income_damage > 0: 
		var heal_rate = clamp(10 - (hunger / 10), 0, 10)
		income_damage -= heal_rate
	if is_ai_enabled and environment:
		AI()
		
	last_position = global_position

func inspect_sector() -> void:
	var sector = environment.get_sector_key(global_position)
	var state = environment.collect_sector_states(sector)
	knowledges[sector] = state

func add_task(type: String, args: Array) -> void:
	var task: Dictionary = {"type": type}
	match type:
		"mv": 
			var pos = Vector2(args[0], args[1])
			if not args[2]:
				prefered_pos = pos
			task["pos"] = pos
		"wait": task["time"] = args[0]
		
	schedule.append(task)

func add_subtask(type: String, args: Array) -> void:
	var subtask: Dictionary = {"type": type}
	match type:
		"mv":
			var pos = Vector2i(args[0], args[1])
			subtask["pos"] = pos
			subtask["evade"] = args[2]
	subtasks.append(subtask)

func exec_task(task: Dictionary) -> int:
	match task["type"]:
		"wait":
			task["time"] -= 1
			if task["time"] <= 0: 
				complete_task()
				return 1
		"mv":
			var pos = task["pos"]
			var point = environment.get_cell(Vector2i(global_position))
			var end_point = environment.get_cell(pos)
			var path = find_path(point, end_point)
			
			if subtasks.size() == 0:
				for cell in path:
					var cell_pos = environment.nav_grid.get_point_position(cell)
					add_subtask("mv", [cell_pos.x, cell_pos.y, false])
			
			if not subtasks.is_empty(): return 0
			else: 
				complete_task() 
				return 1
	return 1

func exec_subtask(task: Dictionary) -> int:
	var status: int
	match task["type"]:
		"mv":
			var results = move_at(task["pos"])
			status = results["status"]
			
			if status == -1:
				complete_subtask()
				on_stuck_handle(results["obstacle"])
			
	if status == 1: complete_subtask()
	return status

func compress_path(path: Array[Vector2i]) -> Array[Vector2i]:
	if path.size() <= 2:
		return path
	var compressed_path: Array[Vector2i] = [path[0]]
	var last_dir = path[1] - path[0]
	for i in range(1, path.size() - 1):
		var current_dir = path[i + 1] - path[i]
		
		if current_dir != last_dir:
			compressed_path.append(path[i])
			last_dir = current_dir
			
	compressed_path.append(path[-1])
	return compressed_path

func find_path(point: Vector2i, end_point: Vector2i) -> Array[Vector2i]:
	var path = environment.nav_grid.get_id_path(point, end_point)
	return compress_path(path)

func on_stuck_handle(obstacle: Area2D) -> void:
	var evade_point = global_position+Vector2(get_face_dir())*100
	
	if obstacle:
		var shape: Rect2 = obstacle.find_child("CollisionShape2D").shape.get_rect()
		face_dir = face_dir-1 if face_dir-1 > -1 else 3
		if shape.size.x > shape.size.y:
			evade_point = global_position+Vector2(get_face_dir())*shape.size.x*1.5
		else:
			evade_point = global_position+Vector2(get_face_dir())*shape.size.y*1.5
	else:
		evade_point = global_position
		match face_dir:
			direction.UP   : evade_point.x -= get_size()
			direction.DOWN : evade_point.x += get_size()
			direction.LEFT : evade_point.y += get_size()
			direction.RIGHT: evade_point.y -= get_size()
			
	current_subtask = {"type": "mv", "pos": evade_point, "evade": true}
	#var dir = evade_point.direction_to(prefered_pos)
	#if abs(dir.y) > abs(dir.x):
	#	add_subtask("mv", [prefered_pos.x, evade_point.y, false])
	#	add_subtask("mv", [prefered_pos.x, prefered_pos.y, false])
	#else:
	#	add_subtask("mv", [evade_point.x, prefered_pos.y, false])
	#	add_subtask("mv", [prefered_pos.x, prefered_pos.y, false])

func exec_command(type: String, args: Array):
	match type:	
		"expire":
			lifetime = 0
		"lifetime":
			lifetime = int(args[0])
		"give":
			if args.is_empty(): return
			var item_scene: PackedScene = load("res://scenes/objects/item.tscn")
			var item: Item = item_scene.instantiate()
		
			item.item_id = int(args[0])
			hold_item.add_child(item)
		"drop":
			drop_item()
		"eat":
			eat()
		"feed":
			hunger = 0
		"pos":
			if args.size() == 0:
				return "pos: %d %d" % [position.x, position.y]
			else:
				var x = int(args[0])
				var y = int(args[1])
				prefered_pos = Vector2(x, y)
				return "pref pos: %d %d" % [x, y]
		"sector":
			var sec = current_sector
			return "sec: %d %d" % [sec.x, sec.y]
		"team":
			return "faction: %s" % faction
		"play":
			sprite.play(args[0].replace("_"," "))
		"st":
			return "(%d) task: %s\n(%d) subtask: %s" % [schedule.size(), current_task.get("type"), subtasks.size(), current_subtask.get("type")]
		"kill":
			income_damage += max_health*100
		"stop":
			complete_task()
			subtasks.clear()
			complete_subtask()
		"stopall":
			schedule.clear()
			subtasks.clear()
			complete_task()
			complete_subtask()
			prefered_pos = global_position
			sprite.play("Idle Down")
		"mv": 
			add_task("mv", [int(args[0]), int(args[1]), false])
		"mv_s":
			var sec_key = Vector2i(int(args[0]), int(args[1]))
			var sec = environment.sectors.get(sec_key)
			if sec:
				var sec_center = sec.get_center()
				add_task("mv", [sec_center.x, sec_center.y, false])
		"step":
			add_task("mv", [global_position.x+int(args[0]), global_position.y+int(args[1]), false])
		"ai":
			match args[0]:
				"on", "1", "enable", "true": is_ai_enabled = true
				"off", "0", "disable", "false": is_ai_enabled = false
				_: is_ai_enabled = false

func complete_task() -> void:
	current_task.clear()
	idle()

func complete_subtask() -> void:
	current_subtask.clear()
	if subtasks.is_empty(): complete_task()

func idle() -> void:
	if not sprite: return
	match face_dir:
			direction.DOWN: sprite.play("Idle Down")
			direction.UP: sprite.play("Idle Up")
			direction.RIGHT: sprite.play("Idle Right")
			direction.LEFT: sprite.play("Idle Left")

func walk(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("Walk Right" if dir.x > 0 else "Walk Left")
		face_dir = direction.RIGHT if dir.x > 0 else direction.LEFT
	else:
		sprite.play("Walk Down" if dir.y > 0 else "Walk Up")
		face_dir = direction.DOWN if dir.y > 0 else direction.UP
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(get_face_dir()))
	velocity = dir*speed
	
	if not environment.get_sector_rect(current_sector).has_point(global_position):
		update_sector()
	
	move_and_slide()

func update_sector() -> void:
	old_sector = current_sector
	current_sector = environment.get_sector_key(global_position)
	environment.replace_entity(self)
	inspect_sector()

func is_item_held() -> bool:
	return not hold_item.get_children().is_empty()

func get_item_held() -> Item:
	if not is_item_held(): return null
	return hold_item.get_children()[0]

func take_item(item: Item) -> void:
	var dist = global_position.distance_to(item.global_position)
	if dist > 50: return
	if is_item_held(): return
	
	environment.displace_item(item)
	hold_item.add_child(item)
	item.position = Vector2.ZERO

func drop_item() -> void:
	if not is_item_held():
		return
	
	var item: Item = get_item_held()
	var drop_pos: Vector2 = item.global_position
	
	hold_item.remove_child(item)
	environment.items.add_child(item)
	environment.reg_item(item)
	item.global_position = drop_pos

func move_at(pos: Vector2i) -> Dictionary:
	var dir = global_position.direction_to(pos)
	if global_position.distance_to(pos) <= 8:
		return {"status": 1}
	var obstacles = sight_area.get_overlapping_areas()
	if obstacles.size() > 1 and not current_subtask["evade"]: return {"status": -1, "obstacle": obstacles[0]}
	
	if global_position.distance_to(last_position) < 0.1 and velocity != Vector2.ZERO:
		stuck_timer += 1
		if stuck_timer >= STUCK_THRESHOLD:
			stuck_timer = 0.0
			return {"status": -1, "obstacle": null}
	else:
		stuck_timer = max(0.0, stuck_timer - 1)
	
	walk(dir)
	return {"status": 0}

func move_to(target: Node2D) -> bool:
	return false

func eat() -> void:
	var food: Item = get_item_held()
	if not food: return
	if not Food.is_edible(food.item_id): return
	
	hunger -= Food.get_value(food.item_id)
	if hunger < 0: hunger = 0
	
	hold_item.remove_child(food)
	food.queue_free()

func get_face_dir() -> Vector2i:
	match face_dir:
		direction.UP   : return Vector2i(0, -1)
		direction.DOWN : return Vector2i(0, 1)
		direction.LEFT : return Vector2i(-1, 0)
		direction.RIGHT: return Vector2i(1, 0)
	return Vector2i(0, -1)

func get_size() -> float:
	var rect: Rect2 = collision.shape.get_rect()
	var width = rect.end.x
	var height = rect.end.y
	if width > height:
		return width*1.5
	else: return height*1.5

func on_lifetime_end() -> void:
	die()

func die() -> void:
	var corpse_scene: PackedScene
	var corpse: Corpse
	
	match get_face_dir():
		direction.DOWN : sprite.play("Death Down")
		direction.UP   : sprite.play("Death Up")
		direction.LEFT : sprite.play("Death Left")
		direction.RIGHT: sprite.play("Death Right")
	
	await get_tree().create_timer(0.5).timeout
	if group != "none" and type_name != "none":
		corpse_scene = load("res://entity/%s/corpses/%s.tscn" % [group, type_name])
		corpse = corpse_scene.instantiate()
		corpse.face_dir = face_dir
		corpse.global_position = global_position
		add_sibling(corpse)
	
	queue_free()

func is_busy() -> bool:
	return not (subtasks.is_empty() and\
	 schedule.is_empty() and\
	 current_subtask.is_empty() and\
	 current_task.is_empty())

func wander() -> void:
	if not is_busy() and randf() >= 0.8:
		var pos = global_position+Vector2(randi_range(-500, 500), randi_range(-500, 500))
		var tile = environment.get_cell(pos)
		if not environment.nav_grid.is_point_solid(tile):
			prefered_pos = pos

func AI() -> void:
	if global_position.distance_to(prefered_pos) > 30 and not is_busy():
		add_task("mv", [prefered_pos.x, prefered_pos.y, false])
	
	wander()
