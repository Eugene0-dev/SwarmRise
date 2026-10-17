
class_name DevFeatures
extends Node2D

var camera: Camera2D

var entity: Entity
var nav_grid: AStarGrid2D
enum debug {PATHWAYS, NAVLAYOUT}
var trace: int = -1

func _init(world_camera: Camera2D) -> void:
	camera = world_camera
	z_index = 1
	
	Global.track_navigation_enabled.connect(_on_track_navigation_enabled)
	Global.track_navigation_disabled.connect(_on_track_navigation_disabled)
	Global.nav_layer_enabled.connect(_on_nav_layer_enabled)
	Global.nav_layer_disabled.connect(_on_nav_layer_disabled)
	print("debug initialised")

func _physics_process(delta: float) -> void:
	if not trace == -1:
		queue_redraw()

func _on_track_navigation_enabled(target: Entity):
	entity = target
	trace = debug.PATHWAYS
	print("signal captured [pathtracing_on], trace settled as %d" % trace)

func _on_track_navigation_disabled():
	entity = null
	trace = -1
	print("signal captured [pathtracing_off], trace settled as %d" % trace)

func _on_nav_layer_enabled(grid: AStarGrid2D):
	nav_grid = grid
	trace = debug.NAVLAYOUT
	print("signal captured [navlayout_on], trace settled as %d" % trace)

func _on_nav_layer_disabled():
	nav_grid = null
	trace = -1
	print("signal captured [navlayout_off, trace settled as %d" % trace)
	queue_redraw()

func _draw():
	match trace:
		debug.NAVLAYOUT:
			if nav_grid:
				var size = nav_grid.cell_size
				var view = camera.view
				var view_rect = Rect2i(
					int(view.position.x) >> 3,
					int(view.position.y) >> 3,
					int(view.size.x) >> 3,
					int(view.size.y) >> 3
				)
				var min_x = max(nav_grid.region.position.x, view_rect.position.x)
				var min_y = max(nav_grid.region.position.y, view_rect.position.y)
				var max_x = min(nav_grid.region.end.x, view_rect.end.x)
				var max_y = min(nav_grid.region.end.y, view_rect.end.y)
				for x in range(min_x, max_x):
					for y in range(min_y, max_y):
						var pos = Vector2i(x * size.x, y * size.y)
						draw_rect(
							Rect2(pos, size),
							(Color(1, 0, 0, 0.5) if nav_grid.is_point_solid(Vector2i(x, y)) else Color(0, 1, 1, 0.2)))
		debug.PATHWAYS:
			if entity:
				var path: Array[Vector2]
				var size = entity.environment.nav_grid.cell_size
				for subtask in entity.subtasks:
					if subtask["type"] == "mv":
						path.append(subtask["pos"])
					
				for i in range(path.size() - 1):
					draw_line(path[i], path[i + 1], Color.MIDNIGHT_BLUE, 2.0)
					draw_circle(path[i], 2.0, Color.CRIMSON)
		_:
			draw_rect(Rect2(0, 0, 100000000000, 10000000000), Color(0, 0, 0, 0))
