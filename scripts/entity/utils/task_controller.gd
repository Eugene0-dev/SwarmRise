
class_name TaskController

var planner: TaskPlanner
var schedule: Array[Task]
enum status {RUNNING, COMPLETE}

func _init(task_planner: TaskPlanner) -> void:
	planner = task_planner

func push(task: Task, priority: bool = false) -> void:
	task.status = Task.state.QUEUED
	if priority:
		schedule.push_front(task)
	else:
		schedule.push_back(task)

func pull() -> Task:
	if not is_busy():
		return Task.new(Task.types.WAIT, {"time": 1})

	var task = schedule[0]
	
	if not task.is_deployed:
		task.subtasks = planner.deploy(task)
		task.is_deployed = true

	if task.subtasks.is_empty():
		return Task.new(Task.types.WAIT, {"time": 1})

	task.status = Task.state.RUNNING
	return task.subtasks[0]

func complete() -> void:
	if schedule.is_empty():
		return

	var parent: Task = schedule[0]

	if parent.subtasks.is_empty():
		parent.status = Task.state.COMPLETE
		schedule.pop_front()
		return

	var subtask: Task = parent.subtasks.pop_front()
	subtask.status = Task.state.COMPLETE

	if parent.subtasks.is_empty():
		parent.status = Task.state.COMPLETE
		schedule.pop_front()

func fail() -> void:
	var task: Task
	if schedule[0].subtasks.is_empty(): task = schedule.pop_front()
	else: task = schedule[0].subtasks.pop_front()
	task.status = Task.state.FAILED

func is_busy() -> bool:
	if schedule.is_empty(): return false
	else: return true
