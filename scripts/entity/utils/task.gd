
class_name Task

enum types {MOVE, WAIT}
enum state {QUEUED, RUNNING, COMPLETE, FAILED}

var type: types
var args: Dictionary
var status: state
var is_deployed: bool = false
var subtasks: Array[Task]

func _init(task_type: types, task_args: Dictionary) -> void:
	type = task_type
	args = task_args
