@tool
class_name Item
extends Node2D

enum id {
	REDBALL, LAMPFRUIT, SUNFRUIT, PUSHFRUIT, 
	HELLBERRY, SUCKBERRY, WHITEBALLS, BLACKBALL, 
	CLOWNBERRY, SEGBERRY, BEGBERRY, SPIRITBERRY, 
	RUSHBERRY, LOG, BOLD_LOG, BRANCH,
	LEAF, GRASS, CLAY, SAND,
	ROCK, GRAVEL, MANDIBLE, PRIME_MANDIBLE
}

@export var item_id: id = -1:
	set(val):
		item_id = val
		update_sprite_region()

@export var atlas_columns: int
@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	update_sprite_region()

func update_sprite_region() -> void:
	if item_id == -1: visible = false
	else: visible = true
	if not sprite: return
	
	var atlas = sprite.texture as AtlasTexture
	var pos: Vector2i = Vector2i.ZERO
	pos.x = item_id % atlas_columns
	pos.y = item_id / atlas_columns
			
	atlas.region = Rect2(
		pos.x * 17 + 1, pos.y * 17 + 1,
			16, 16
	)
