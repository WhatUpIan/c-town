class_name InventorySystem
extends RefCounted

var content: ContentDB

func bind(p_content: ContentDB) -> void:
	content = p_content

func can_add(player: PlayerState, item_id: String, qty: int) -> bool:
	if content == null or not content.items.has(item_id):
		return false
	if qty <= 0:
		return false
	return player.inventory.can_add(item_id, qty, content.max_stack(item_id))

func add(player: PlayerState, item_id: String, qty: int) -> bool:
	if not can_add(player, item_id, qty):
		return false
	return player.inventory.add(item_id, qty, content.max_stack(item_id))

func can_remove(player: PlayerState, item_id: String, qty: int) -> bool:
	if qty <= 0 or not content.items.has(item_id):
		return false
	return player.inventory.can_remove(item_id, qty)

func remove(player: PlayerState, item_id: String, qty: int) -> bool:
	if not can_remove(player, item_id, qty):
		return false
	return player.inventory.remove(item_id, qty)
