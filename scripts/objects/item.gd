@tool
class_name Item
extends Node2D

enum id {
	REDBALL, LAMPFRUIT, SUNFRUIT, PUSHFRUIT, HELLBERRY, SUCKBERRY, WHITEBALLS,
	BLACKBALL, CLOWNBERRY, SEGBERRY, BEGBERRY, SPIRITBERRY, RUSHBERRY, BUG_FLASH,
	MEAT, SMALL_MEAT, BONE, LEATHER, CHITINE, MANDIBLE, PRIME_MANDIBLE,
	LOG, BOLD_LOG, BRANCH, LEAF, GRASS, CLAY, SAND,
	ROCK, GRAVEL
}

@export var item_id: id = -1:
	set(val):
		item_id = val
		update_sprite_region()

@export var amount: int = 1:
	set(val):
		amount = val
		update_sprite_region()

var atlas_columns: int = 7
@onready var sprite: Sprite2D = $Sprite2D
@onready var stack_label: Label = $Counter_Label

func _ready() -> void:
	update_sprite_region()

func update_sprite_region() -> void:
	if not is_node_ready(): return
	if item_id == -1: visible = false
	else: visible = true
	if amount <= 1: stack_label.visible = false
	else: stack_label.visible = true
	if not sprite: return
	stack_label.text = "%d" % amount
	
	var atlas = sprite.texture as AtlasTexture
	var pos: Vector2i = Vector2i.ZERO
	pos.x = item_id % atlas_columns
	pos.y = item_id / atlas_columns
			
	atlas.region = Rect2(
		pos.x * 17 + 1, pos.y * 17 + 1,
			16, 16
	)
