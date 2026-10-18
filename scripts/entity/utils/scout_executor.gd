
class_name ScoutExecutor
extends Executor

const CMD_TAKEOFF := 100

func _init(subjcet: Entity) -> void:
	super(subjcet)
	command_extension["TAKEOFF"] = CMD_TAKEOFF

func execute(command: commands, args: Dictionary):
	match command:
		CMD_TAKEOFF:
			target.takeoff()
		_: return super(command, args)
