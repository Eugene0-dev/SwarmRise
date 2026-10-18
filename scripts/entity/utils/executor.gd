
class_name Executor
# Entity command executor

enum commands {
	EXPIRE, LIFETIME, KILL, FEED,
	GIVE, DROP, EAT,
	POS, SECTOR, MV, MV_S, STEP,
	TEAM, ST, 
	PLAY, STOP, STOPALL, AI,
	CAM, FIND, 
}

var command_extension: Dictionary = {}
var target: Entity

func _init(subjcet: Entity) -> void:
	target = subjcet

func execute(command: commands, args: Dictionary):
	match command:
		commands.EXPIRE: 
			target.lifetime = 0
		commands.LIFETIME:
			target.lifetime = args["time"]
		commands.KILL:
			target.income_damage = target.max_health*100
		commands.FEED:
			target.hunger = 0
		commands.GIVE:
			if not args.has("item_id"): return
			var item_scene: PackedScene = load("res://scenes/objects/item.tscn")
			var item: Item = item_scene.instantiate()
		
			item.item_id = args["item_id"]
			if args.has("amount"): item.amount = args["amount"]
			target.hold_item.add_child(item)
		commands.DROP:
			target.drop_item()
		commands.EAT:
			target.eat()
		commands.POS:
			if args.size() == 0:
				return "pos: %d %d" % [target.position.x, target.position.y]
			else:
				var pos: Vector2 = args["pos"]
				target.prefered_pos = pos
				return "pref pos: %d %d" % [pos.x, pos.y]
		commands.SECTOR:
			var sec = target.current_sector
			return "sec: %d %d" % [sec.x, sec.y]
		commands.MV:
			var new_task = Task.new(Task.types.MOVE, {"pos": args["pos"]})
			target.tasks.push(new_task)
		commands.MV_S:
			var sec_key = args["sec_key"]
			var sec = target.environment.sectors.get(sec_key)
			if sec:
				var sec_center = sec.get_center()
				var new_task = Task.new(Task.types.MOVE, {"pos": Vector2(sec_center.x, sec_center.y)})
				target.tasks.push(new_task)
		commands.STEP:
			var new_task = Task.new(Task.types.MOVE, 
				{"pos": target.global_position + args["dest"]}
			)
			target.tasks.push(new_task)
		commands.TEAM:
			return "faction: %s" % target.faction
		commands.ST:
			if target.task and target.task.is_deployed:
				return "(%d) task: %s\n(%d) subtask: %s" % [
					target.tasks.schedule.size(), 
					Task.types.find_key(target.task.type), 
					target.task.subtasks.size(), 
					Task.types.find_key(target.task.subtasks[0].type)]
		commands.PLAY:
			target.sprite.play(args["anim_name"].replace("_"," "))
		commands.STOP:
			target.tasks.cancel_current()
			target.velocity = Vector2.ZERO
			target.task = null
		commands.STOPALL:
			target.tasks.cancel_all()
			target.velocity = Vector2.ZERO
			target.prefered_pos = target.global_position
			target.task = null
			target.idle()
		commands.AI:
			match args["option"]:
				"on", "1", "enable", "true": target.is_ai_enabled = true
				"off", "0", "disable", "false": target.is_ai_enabled = false
				_: target.is_ai_enabled = false
		
		
		
