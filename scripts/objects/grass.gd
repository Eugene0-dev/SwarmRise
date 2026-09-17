@tool
class_name Grass
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@export var atlas_columns: int

enum types{GRASS0, GRASS1, GRASS2, GRASS3, GRASS4, GRASS5,
SEAGRASS_C0, SEAGRASS_C1, SEAGRASS_C2, SEAGRASS_C3, SEAGRASS_C4, SEAGRASS_C5,
SEAGRASS_L0, SEAGRASS_L1, SEAGRASS_L2, SEAGRASS_L3, SEAGRASS_L4, SEAGRASS_L5,
SEAGRASS_O0, SEAGRASS_O1, SEAGRASS_O2, SEAGRASS_O3, SEAGRASS_O4, SEAGRASS_O5}
@export var type: types = types.GRASS0:
	set(val):
		type = val
		update_sprite_region()

func _ready() -> void:
	update_sprite_region()

func update_sprite_region() -> void:
	if not sprite: return
	
	var atlas = sprite.texture as AtlasTexture
	var pos: Vector2i = Vector2i.ZERO
	pos.x = type % atlas_columns
	pos.y = type / atlas_columns
			
	atlas.region = Rect2(
		pos.x * 9 + 1, pos.y * 9 + 1,
			8, 8
	)
