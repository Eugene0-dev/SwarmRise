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

var tasks: TaskController
var planner: TaskPlanner
var nav_agent: NavAgent

var task: Task

var stuck_timer: float = 0.0
var STUCK_THRESHOLD: float = 3.0
var last_position: Vector2

var environment: World

var executor: Executor

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
		
		nav_agent = NavAgent.new(environment, self)
		planner = TaskPlanner.new(nav_agent)
		tasks = TaskController.new(planner)
		executor = Executor.new(self)
		
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
	if Engine.is_editor_hint() or not environment:
		idle()
		return

	if not task or task.status == Task.state.COMPLETE:
		if tasks.is_busy():
			task = tasks.pull()
		else:
			task = null
			idle()
		return

	exec_task(task)

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

func exec_task(task: Task) -> int:
	match task.type:
		Task.types.WAIT:
			task.args["time"] -= 1
			if task.args["time"] <= 0: 
				tasks.complete()
				return task.status
		Task.types.MOVE:
			move_at(task.args["pos"])
	return task.status

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
			
	#current_subtask = {"type": "mv", "pos": evade_point, "evade": true}
	var new_task = Task.new(Task.types.MOVE, {"pos": evade_point})
	tasks.push(new_task, true)
	task.status = Task.state.FAILED
	task = null

func move_at(pos: Vector2) -> void:
	var dir = global_position.direction_to(pos)

	if global_position.distance_to(pos) <= 8:
		tasks.complete()
		return

	var obstacles = sight_area.get_overlapping_areas()
	if obstacles.size() > 1:
		on_stuck_handle(obstacles[0])
		return

	if global_position.distance_to(last_position) < 0.1 \
			and velocity != Vector2.ZERO:
		stuck_timer += 1

		if stuck_timer >= STUCK_THRESHOLD:
			stuck_timer = 0.0
			on_stuck_handle(null)
			return
	else:
		stuck_timer = maxf(0.0, stuck_timer - 1)

	walk(dir)

func move_to(target: Node2D) -> bool:
	return false

func walk(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		sprite.play("Walk Right" if dir.x > 0 else "Walk Left")
		face_dir = direction.RIGHT if dir.x > 0 else direction.LEFT
	else:
		sprite.play("Walk Down" if dir.y > 0 else "Walk Up")
		face_dir = direction.DOWN if dir.y > 0 else direction.UP
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(get_face_dir()))
	velocity = dir*speed
	
	if not environment.get_sector_rect(current_sector).has_point(last_position):
		update_sector()
	
	move_and_slide()

func idle() -> void:
	if not sprite: return
	match face_dir:
			direction.DOWN: sprite.play("Idle Down")
			direction.UP: sprite.play("Idle Up")
			direction.RIGHT: sprite.play("Idle Right")
			direction.LEFT: sprite.play("Idle Left")

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
	
	if item.amount < 10:
		environment.displace_item(item)
		hold_item.add_child(item)
		item.position = Vector2.ZERO
	else:
		item.amount -= 10
		var item_scene: PackedScene = load("res://scenes/objects/item.tscn")
		var item_clone: Item = item_scene.instantiate()
		item_clone.item_id = item.item_id
		item_clone.amount = 10
		item.position = Vector2.ZERO
		hold_item.add_child(item_clone)

func drop_item() -> void:
	if not is_item_held():
		return
	
	var item: Item = get_item_held()
	var drop_pos: Vector2 = item.global_position
	
	hold_item.remove_child(item)
	environment.items.add_child(item)
	environment.reg_item(item)
	item.global_position = drop_pos

func eat() -> void:
	var food: Item = get_item_held()
	if not food: return
	if not Food.is_edible(food.item_id): return
	
	hunger -= Food.get_value(food.item_id)
	if hunger < 0: hunger = 0
	
	if food.amount > 1:
		food.amount -= 1
	else:
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

func wander() -> void:
	if not tasks.is_busy() and randf() >= 0.8:
		var pos = global_position+Vector2(randi_range(-500, 500), randi_range(-500, 500))
		var tile = environment.get_cell(pos)
		if not environment.nav_grid.is_point_solid(tile):
			prefered_pos = pos

func AI() -> void:
	if global_position.distance_to(prefered_pos) > 30 and not tasks.is_busy():
		var new_task = Task.new(Task.types.MOVE, {"pos": Vector2(prefered_pos.x, prefered_pos.y)})
		tasks.push(new_task)
		
	wander()
