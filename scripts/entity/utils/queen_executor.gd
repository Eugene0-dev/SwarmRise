
class_name QueenExecutor
extends Executor

const COMMAND_EXTENSION := { "BREED": 100 }

func execute(command: commands, args: Dictionary):
	match command:
		COMMAND_EXTENSION["BREED"]:
			target.breed(args["unit_type"])
		_:
			return super(command, args)
