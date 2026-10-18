
class_name NavAgent

var env: World
var worker: Entity

func _init(environment: World, subject: Entity) -> void:
	env = environment
	worker = subject

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

func find_path(end_point: Vector2i) -> Array[Vector2i]:
	var point = global_to_nav(worker.global_position)
	end_point = global_to_nav(end_point)
	var path = env.nav_grid.get_id_path(point, end_point)
	return compress_path(path)

func nav_to_global(cell: Vector2i) -> Vector2:
	return env.nav_grid.get_point_position(cell)

func global_to_nav(pos: Vector2) -> Vector2i:
	return env.get_cell(pos)
