
class_name World
extends Node2D

@onready var sun: DirectionalLight2D = $Sun
@onready var clouds: ColorRect = $Clouds
@onready var camera: Camera2D = $MainCam

@export var world_map: WorldMap
var items: Node2D
var entities: Node2D
var sectors: Dictionary
var nav_grid: AStarGrid2D

func _ready() -> void:
	items = world_map.items
	entities = world_map.entities
	sectors = world_map.sectors
	clouds.size.x = world_map.map_width_px
	clouds.size.y = world_map.map_height_px
	
	Global.place_item.connect(_on_place_item_requested)
	Global.grow_plant.connect(grow)
	Global.save_game.connect(save_world)

func _process(delta: float) -> void:
	if Global.is_tick(delta):
		Global.emit_signal("tick")

func save_world():
	var world_seed: int = world_map.world_seed
	var items_list: Array[Dictionary]
	var entities_list: Array
	
	for item in items.get_children():
		if item is Item:
			items_list.append(DataRaw.extract_item(item))
	
	for entity in entities.get_children():
		if entity is Entity:
			entities_list.append(DataRaw.extract_entity(entity))

func place_item(id: int, pos: Vector2) -> Item:
	if world_map.astar_grid.is_point_solid(get_cell(pos)):
		return null
	var item_scene: PackedScene = load("res://scenes/objects/item.tscn")
	var item: Item = item_scene.instantiate()
	if id < item.id.size():
		item.item_id = id
		item.global_position = pos
		items.add_child(item)
		return item
	return null

func grow(args: Dictionary) -> Grass:
	var scene: PackedScene = load("res://scenes/objects/grass.tscn")
	var grass: Grass = scene.instantiate()
	grass.global_position = args["pos"]
	grass.type = args["type"]
	add_child(grass)
	return grass

func create_entity(link: String, pos: Vector2, extra: String = "") -> Entity:
	var scene: PackedScene = load("res://entity/%s.tscn" % link)
	if scene:
		if scene.can_instantiate():
			var subject = scene.instantiate()
			if subject is Egg and extra != "":
				subject.type = extra
			subject.name = create_entity_name(subject)
			subject.position = pos
			subject.environment = self
			entities.add_child(subject)
			return subject
	return null

func create_entity_name(subject: Entity) -> String:
	var name: String
	var num: int = randi_range(0, 4000)
	if subject is Queen:
		name = "Queen_%d" % num
	elif subject is Drone:
		name = "Drone_%d" % num
	elif subject is Soldier:
		name = "Soldier_%d" % num
	elif subject is Scout:
		name = "Scout_%d" % num
	elif subject is Princess:
		name = "Princess_%d" % num
	elif subject is Egg:
		name = "Egg_%s_%d" % [subject.type, num]
	
	if not get_node_or_null(name):
		return name
	else:
		return create_entity_name(subject)

func get_sector_key(pos: Vector2i) -> Vector2i:
	var x = pos.x >> 8
	var y = pos.y >> 8
	return Vector2i(x, y)

func get_sector_rect(key: Vector2i) -> Rect2i:
	return sectors[key]

func get_dir_to_sector(from: Vector2, key: Vector2i) -> Vector2i:
	var sector_center = sectors[key].get_center()
	return from.direction_to(sector_center)

func get_cell(coordinates: Vector2i) -> Vector2i:
	var x = coordinates.x >> 3
	var y = coordinates.y >> 3
	return Vector2i(x, y)

func _on_place_item_requested(args: Dictionary):
	place_item(args["id"], args["pos"])

func _on_ground_generation_complete() -> void:
	nav_grid = world_map.astar_grid
	var pos = Vector2i(
		randi_range(100, world_map.map_width_px-100),
		randi_range(100, world_map.map_height_px-100)
	)
	var tile_pos = world_map.water_layer.local_to_map(pos)
	var tile = world_map.water_layer.get_cell_tile_data(tile_pos)
	if tile:
		return _on_ground_generation_complete()
	create_entity("ants/queen", pos)
	camera.position = pos
