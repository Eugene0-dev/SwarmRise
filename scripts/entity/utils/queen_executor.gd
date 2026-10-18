
class_name QueenExecutor
extends Executor

const CMD_BREED := 100

func _init(subjcet: Entity) -> void:
	super(subjcet)
	command_extension["BREED"] = CMD_BREED

func execute(command: commands, args: Dictionary):
	match command:
		CMD_BREED:
			target.breed(args["unit_type"])
		_:
			return super(command, args)
