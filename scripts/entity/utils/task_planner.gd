
class_name TaskPlanner

var nav: NavAgent

func _init(navigation: NavAgent) -> void:
	nav = navigation

func deploy(task: Task) -> Array[Task]:
	var subtasks: Array[Task]
	match  task.type:
		Task.types.MOVE:
			var path = nav.find_path(task.args["pos"])
			if path.is_empty():
				task.status = Task.state.COMPLETE
				task.is_deployed = true
				return subtasks
				
			for cell in path:
					var cell_pos = nav.nav_to_global(cell)
					subtasks.append(Task.new(Task.types.MOVE, {"pos": cell_pos}))
					
	task.is_deployed = true
	return subtasks
