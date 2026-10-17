
extends Node

var raw: Dictionary

static func get_raw(object: Object) -> Dictionary:
	if not is_instance_valid(object):
		return {}
	
	if object is Entity:
		return extract_entity(object)
	if object is Item:
		return extract_item(object)
		
	return {}
	
static func extract_entity(entity: Entity) -> Dictionary:
	return {
		"type_name": entity.type_name,
		"group": entity.group,
		"lifetime": entity.lifetime,
		"income_damage": entity.income_damage,
		"hunger": entity.hunger,
		"faction": entity.faction,
		"position": entity.position,
		"face_dir": entity.face_dir,
		"schedule": entity.schedule,
		"subtasks": entity.subtasks
	}

static func extract_item(item: Item) -> Dictionary:
	return {
		"item_id": item.item_id,
		"position": item.position
	}
	
	
	
	
	
	
	
