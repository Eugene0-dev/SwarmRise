
class_name Egg
extends Entity

@export var type: String

func _ready() -> void:
	var entity_src = "res://entity/ants/%s.tscn" % type
	var is_entity_src_valid = FileAccess.file_exists(entity_src)
	sight_area.queue_free()
	if not is_entity_src_valid: 
		queue_free()

func move_at(pos: Vector2i) -> Dictionary:
	prefered_pos = position
	return {"status": 1}

func _physics_process(delta: float) -> void:
	if  Global.is_tick(delta):
		lifetime -= 1
		if lifetime <= 0:
			on_lifetime_end()

func on_lifetime_end() -> void:
	if environment:
		var subject = environment.create_entity("ants/%s" % type, position)
		if subject:
			subject.scale = Vector2(0.2, 0.2)
			subject.faction = faction
			var num = name.split("_")[2]
			subject.name = type.capitalize()+"_"+num
	super()
