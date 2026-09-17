extends Camera2D

@onready var background: ColorRect = $Background

@export var speed: float = 500.0
@export var zoom_speed: float = 0.1
var move_lock: bool = false

var view: Rect2:
	get:
		var viewport = get_viewport()
		if not viewport: return Rect2()
		var screen_size = viewport.get_visible_rect().size
		var cam_center = get_screen_center_position()
		var half_extents = (screen_size / 2.0) / zoom
		return Rect2(cam_center - half_extents, half_extents * 2.0)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom -= Vector2(zoom_speed, zoom_speed)
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom += Vector2(zoom_speed, zoom_speed)

func _process(delta: float) -> void:
	var direction = Input.get_vector("left", "right", "up", "down")
	
	if Input.is_action_just_pressed("alt"): move_lock = !move_lock
	if Input.is_action_just_pressed("enter"): move_lock = false
	
	if not move_lock:
		position += direction * speed * delta / zoom.x
		
		if Input.is_action_pressed("shift"):
			zoom += Vector2(zoom_speed, zoom_speed)
		if Input.is_action_pressed("space"):
			zoom -= Vector2(zoom_speed, zoom_speed)
	
	zoom = zoom.clamp(Vector2(0.2, 0.2), Vector2(3.0, 3.0))
	
	background.size = view.size
	background.position = -view.size/2
	
	if background and background.material:
		background.material.set_shader_parameter("camera_offset", global_position/8)
