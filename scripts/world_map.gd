
class_name WorldMap
extends TileMapLayer

@export var noise: FastNoiseLite
@export var objective_noise: FastNoiseLite
@export var ground_material_noise: FastNoiseLite

@export var map_width: int
@export var map_height: int
@export var tileset: TileSet

var threads: Array

var map_width_px: int
var map_height_px: int

const t_grass  = Vector2i(0, 0)
const t_earth  = Vector2i(0, 1)
const t_sand   = Vector2i(0, 2)
const t_stone  = Vector2i(0, 3)
const t_sludge = Vector2i(12, 13)
const t_clay   = Vector2i(12, 14)
const t_gravel = Vector2i(12, 15)

enum t_types {
	GRASS, EARTH, SAND, STONE, GRAVEL, CLAY, SLUDGE
}

const TREE_TILES = [
	Vector2i(3, 13), Vector2i(24, 11), Vector2i(45, 10), Vector2i(66, 11),
	Vector2i(90, 7), Vector2i(106, 7), Vector2i(3, 42), Vector2i(24, 42),
	Vector2i(45, 42), Vector2i(66, 42), Vector2i(90, 39), Vector2i(106, 39)
]

const BUSH_TILES = [
	Vector2i(3, 84), Vector2i(24, 83), Vector2i(45, 83), Vector2i(66, 83),
	Vector2i(89, 78), Vector2i(107, 78), Vector2i(124, 78), Vector2i(3, 115),
	Vector2i(24, 115), Vector2i(45, 115), Vector2i(66, 115), Vector2i(90, 111),
	Vector2i(108, 111), Vector2i(124, 111)
]

@onready var items: Node2D = $Items
@onready var water_layer: TileMapLayer = $Water
@onready var entities: Node2D = $Entities
@onready var objects_layer: TileMapLayer = $Objects
var progress: float = 0.0
@export var world_seed: int = 0

const sector_size: Vector2i = Vector2i(32, 32)
var sectors: Dictionary = {}

var astar_grid: AStarGrid2D

signal generation_complete()

func _ready() -> void:
	map_width_px = map_width*tileset.tile_size.x
	map_height_px = map_height*tileset.tile_size.y
	world_seed = randi_range(1, 100)
	
	astar_grid = AStarGrid2D.new()
	astar_grid.region = Rect2i(0, 0, map_width, map_height)
	astar_grid.cell_size = tileset.tile_size
	astar_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar_grid.update()
	
	init_noise()
	init_sectors()
	map_gen()

func init_noise() -> void:
	noise = FastNoiseLite.new()
	noise.seed = world_seed
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.frequency = 0.001
	noise.fractal_gain = 0.6
	noise.fractal_octaves = 5
	
	objective_noise = FastNoiseLite.new()
	objective_noise.seed = world_seed+1
	objective_noise.noise_type = FastNoiseLite.TYPE_VALUE_CUBIC
	objective_noise.frequency = 0.1
	
	ground_material_noise = FastNoiseLite.new()
	ground_material_noise.seed = world_seed+2
	ground_material_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	ground_material_noise.frequency = 0.0025
	ground_material_noise.fractal_gain = 0.6

func init_sectors() -> void:
	var tile_width = tileset.tile_size.x
	var tile_height = tileset.tile_size.y
	
	var sector_width_px = sector_size.x * tile_width
	var sector_height_px = sector_size.y * tile_height
	var sector_size_px = Vector2i(sector_width_px, sector_height_px)
	
	var sectors_x = ceili(float(map_width) / sector_size.x)
	var sectors_y = ceili(float(map_height) / sector_size.y)
	
	for x in range(sectors_x):
		for y in range(sectors_y):
			var sector_pos = Vector2i(x * sector_width_px, y * sector_height_px)
			sectors[Vector2i(x, y)] = Rect2i(sector_pos, sector_size_px)

func map_gen() -> void:
	var cell_batches: Dictionary = {}
	for type in t_types.values():
		cell_batches[type] = [] as Array[Vector2i]
	
	for x in range(map_width):
		for y in range(map_height):
			var pos = Vector2i(x, y)
			var pos_px = pos*8
			
			var noise_val = noise.get_noise_2d(x, y)
			var material_val = 	ground_material_noise.get_noise_2d(x, y)
			var tile_case = get_tile_type(noise_val, material_val)
			var tile_type = tile_case["type"]
			tile_case = tile_case["tile"]

			if not (pos.y == 0 or pos.y == map_height):
				cell_batches[tile_type].append(pos)
				
			var obj_noise_val = objective_noise.get_noise_2d(x, y)
			
			var cost = remap(noise_val, -1.0, 1.0, 50.0, 1.0)
			if astar_grid:
				astar_grid.set_point_weight_scale(pos, cost)
			
			if y == 0 or y == map_height-1:
				set_cell(pos, 2, tile_case)
			else:
				set_cell(pos, 1, tile_case)
				
			if noise_val < 0.5 and noise_val > 0 and tile_type == t_types.GRASS:
				set_bushes(noise_val, obj_noise_val, pos)
				set_trees(noise_val, obj_noise_val, pos)
				if Global.throw_dice(500, 1):
					Global.emit_signal("grow_plant", {"type": Grass.types.values().pick_random(), "pos": pos_px})
			
			if Global.throw_dice(2000, 1):
					Global.emit_signal("place_item", {"id": Item.id.ROCK, "pos": pos_px})
			
			if tile_type == t_types.GRAVEL:
				if Global.throw_dice(100, 1):
					Global.emit_signal("place_item", {"id": Item.id.GRAVEL, "pos": pos_px})
			
			if tile_type == t_types.CLAY:
				if Global.throw_dice(250, 1):
					Global.emit_signal("place_item", {"id": Item.id.CLAY, "pos": pos_px})
			
			if noise_val < -0.1:
				water_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				astar_grid.set_point_solid(Vector2i(x, y), true)
				astar_grid.set_point_weight_scale(Vector2i(x, y), 1000000)
				
			progress = x
			# use bigger value to increase generation speed ( x % 20 )
			# that decreases FPS on loading screan
			if x % 5 == 0 and y == 0 and is_inside_tree():
				await get_tree().process_frame
			elif not is_inside_tree(): return
	
	var post_process = connect_cells.bind(cell_batches)
	threads.append(WorkerThreadPool.add_task(post_process, false))
	progress = map_width
	emit_signal("generation_complete")

func connect_cells(tile_batches: Dictionary) -> void:
	var chunk_size = 10000
	for batch in tile_batches:
		var tiles: Array[Vector2i] = tile_batches[batch]
		var i: int = 0
		while i < tiles.size()-1:
			var chunk = tiles.slice(i, i+chunk_size)
			set_cells_terrain_connect(chunk, 0, batch, false)
			i += chunk_size
		OS.delay_msec(50)

func set_trees(val: float, obj_val: float, pos: Vector2i) -> void:
	var noise_sum = val+obj_val
	
	if noise_sum >= 0.5014 and noise_sum < 0.5025:
		var index: int = int((noise_sum - 0.5014) / 0.0001)
		
		if index >= 0 and index < TREE_TILES.size():
			place_object(pos, 1, TREE_TILES[index], true)

func set_bushes(val: float, obj_val: float, pos: Vector2i) -> void:
	var noise_sum = val+obj_val
	
	if noise_sum >= 0.5 and noise_sum < 0.5014:
		var index: int = int((noise_sum - 0.5) / 0.0001)
		
		if index >= 0 and index < BUSH_TILES.size():
			place_object(pos, 1, BUSH_TILES[index], true)

func place_object(pos: Vector2i, atlas_id: int, tile: Vector2i, is_solid: bool) -> void:
	objects_layer.set_cell(pos, atlas_id, tile)
	for x in range(-3, 4):
		for y in range(-2, 3):
			var tile_around = Vector2i(x, y)
			if astar_grid.is_in_boundsv(pos+tile_around):
				astar_grid.set_point_solid(pos+tile_around, true)
	for x in range(-7, 8):
		for y in range(-7, 8):
			var tile_around = Vector2i(x, y)
			if astar_grid.is_in_boundsv(pos+tile_around) and not astar_grid.is_point_solid(pos+tile_around):
				var dist = pos.distance_to(pos+tile_around)
				var cost = remap(dist, 1.0, 6.0, 10.0, 1.0)
				astar_grid.set_point_weight_scale(tile_around+pos, abs(cost))

func get_tile_type(val: float, m_val: float) -> Dictionary:
	if val > -0.3 and val < 0.6 and m_val > -1 and m_val < -0.5:
		return {
			"tile": Vector2i(t_clay.x+randi_range(0, 3), t_clay.y), 
			"type": t_types.CLAY }
	if val > -0.3 and val < 0.8 and m_val > 0.5 and m_val < 1:
		return {
			"tile": Vector2i(t_gravel.x+randi_range(0, 3), t_gravel.y), 
			"type": t_types.GRAVEL }
	if -0.5 < val and val < -0.15: 
		if randf() > 0.99:
			return {
				"tile": Vector2i(t_sludge.x+randi_range(0, 3), t_sludge.y-1),
				"type": t_types.SLUDGE }
		else:
			return {
				"tile": Vector2i(t_sludge.x+randi_range(0, 3), t_sludge.y),
				"type": t_types.SLUDGE }
	if val > -0.15 and val < 0: return {
		"tile": Vector2i(t_sand.x+randi_range(0, 3), t_sand.y),
		"type": t_types.SAND }
	if val > 0 and val < 0.5: return {
		"tile": Vector2i(t_grass.x+randi_range(0, 3), t_grass.y),
		"type": t_types.GRASS}
	if val > 0.5: return {
		"tile": Vector2i(t_earth.x+randi_range(0, 3), t_earth.y), 
		"type": t_types.EARTH}
	return {
		"tile": Vector2i(t_stone.x+randi_range(0, 3), t_stone.y),
		"type": t_types.STONE}

func _on_generation_complete() -> void:
	pass
