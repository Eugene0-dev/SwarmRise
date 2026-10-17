extends Control

@export var world_map: WorldMap
@export var camera: Camera2D

@onready var progress: ProgressBar = $Panel/ProgressBar
@onready var seed_label: Label = $Panel/Seed_Label
@onready var entity: Entity = $Panel/Queen

func _ready() -> void:
	get_tree().paused = true
	process_mode = Node.PROCESS_MODE_ALWAYS
	if not visible: visible = true
	progress.max_value = world_map.map_width
	seed_label.text = "seed: %d" % world_map.world_seed
	entity.sprite.play("Walk Down")

func _process(delta: float) -> void:
	progress.value = world_map.progress
	entity.rotate(delta/10)
	camera.position.x += delta*60
	camera.position.y += delta*50
	if progress.value == progress.max_value:
		get_tree().paused = false
		queue_free()
