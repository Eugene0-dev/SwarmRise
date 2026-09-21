
class_name Food

static var fruits: Array[Item.id] = [
	Item.id.REDBALL, Item.id.LAMPFRUIT, Item.id.SUNFRUIT, Item.id.PUSHFRUIT,
	Item.id.HELLBERRY, Item.id.SUCKBERRY
]

static var meat: Array[Item.id] = []

static func get_value(item_id: Item.id) -> int:
	if is_meat(item_id): return 300
	if is_fruit(item_id): return 100
	
	return 0

static func is_fruit(item_id: Item.id) -> bool:
	return item_id in fruits
	
static func is_meat(item_id: Item.id) -> bool:
	return item_id in meat
	
static func is_edible(item_id: Item.id) -> bool:
	return is_fruit(item_id) or is_meat(item_id)
