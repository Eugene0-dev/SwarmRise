@tool
class_name Queen
extends Entity

func _ready() -> void:
	super()
	specific_commands.append("breed")

func AI() -> void:
	if faction == "none":
		faction = create_faction()
	super()

func create_faction() -> String:
	var q_name = name.split("_")
	if len(q_name) > 1:
		var num = q_name[1]
		return "Swarm_%s" % num
	else:
		return "Swarm_NaN"

func exec_command(type: String, args: Array):
	match type:
		"breed": breed(args[0])
		_: return super(type, args)

func breed(type: String) -> void:
	if type == "queen": return
	if environment:
		var subject = environment.create_entity("ants/egg", position-Vector2(get_face_dir()*50), type)
		if subject:
			subject.type = type
			subject.faction = faction
