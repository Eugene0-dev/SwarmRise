@tool
class_name Scout
extends Entity

var is_onflight: bool = false

func _ready() -> void:
	super()
	specific_commands.append("takeoff")

func AI() -> void:
	if position.distance_to(prefered_pos) > 250 : takeoff()
	elif position.distance_to(prefered_pos) < 50 and is_onflight: landing()
	super()

func exec_command(type: String, args: Array):
	match type:
		"takeoff": takeoff()
		_: return super(type, args)

func idle() -> void:
	if not is_onflight:
		super()
	else:
		if not sprite: return
		match get_face_dir():
			direction.DOWN: sprite.play("Flight Down")
			direction.UP: sprite.play("Flight Up")
			direction.RIGHT: sprite.play("Flight Right")
			direction.LEFT: sprite.play("Flight Left")

func fly(dir: Vector2):
	if abs(dir.x) > abs(dir.y):
		sprite.play("Flight Right" if dir.x > 0 else "Flight Left")
		face_dir = direction.RIGHT if dir.x > 0 else direction.LEFT
	else:
		sprite.play("Flight Down" if dir.y > 0 else "Flight Up")
		face_dir = direction.DOWN if dir.y > 0 else direction.UP
	sight_area.rotation = Vector2.DOWN.angle_to(Vector2(get_face_dir()))
	velocity = dir*speed*2
	move_and_slide()

func find_path(point: Vector2i, end_point: Vector2i) -> Array[Vector2i]:
	if is_onflight:
		return environment.nav_grid.get_id_path(point, end_point, true)
	else: return super(point, end_point)

func walk(dir: Vector2):
	if not is_onflight:
		super(dir)
	else: fly(dir)

func takeoff() -> void:
	is_onflight = true
	collision_mask = 3
	collision_layer = 3
	create_tween().tween_property(sprite, "scale", Vector2(0.85, 0.85), 0.3).set_trans(Tween.TRANS_SINE)
	match get_face_dir():
		direction.UP   : sprite.play("Takeoff Up")
		direction.DOWN : sprite.play("Takeoff Down")
		direction.LEFT : sprite.play("Takeoff Left")
		direction.RIGHT: sprite.play("Takeoff Right")

func landing() -> void:
	var tile = environment.get_cell(global_position)
	if environment.nav_grid.is_point_solid(tile): return
	is_onflight = false
	collision_mask = 1
	collision_layer = 2
	create_tween().tween_property(sprite, "scale", Vector2(0.706, 0.706), 0.3).set_trans(Tween.TRANS_SINE)
	match get_face_dir():
		direction.UP   : sprite.play("Landing Up")
		direction.DOWN : sprite.play("Landing Down")
		direction.LEFT : sprite.play("Landing Left")
		direction.RIGHT: sprite.play("Landing Right")
