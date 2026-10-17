
class_name Corpse
extends Node2D

@onready var sprite: AnimatedSprite2D = $Sprite

enum dirrection {UP, DOWN, LEFT, RIGHT}
var face_dir: int = 0

func _physics_process(delta: float) -> void:
	match face_dir:
		dirrection.DOWN : sprite.play("Down")
		dirrection.UP   : sprite.play("Up")
		dirrection.LEFT : sprite.play("Left")
		dirrection.RIGHT: sprite.play("Right")
