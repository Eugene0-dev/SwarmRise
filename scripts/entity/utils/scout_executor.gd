
class_name ScoutExecutor
extends Executor

const COMMAND_EXTENSION := {
	"TAKEOFF": 100
}

func execute(command: commands, args: Dictionary):
	match command:
		COMMAND_EXTENSION["TAKEOFF"]:
			target.takeoff()
		_: super(command, args)
