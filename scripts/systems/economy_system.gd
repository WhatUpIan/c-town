class_name EconomySystem
extends RefCounted

var world: WorldState
var content: ContentDB
var inventory: InventorySystem
var calendar: CalendarSystem

func bind(p_world: WorldState, p_content: ContentDB, p_inv: InventorySystem, p_cal: CalendarSystem) -> void:
	world = p_world
	content = p_content
	inventory = p_inv
	calendar = p_cal

func buy(player: PlayerState, item_id: String, quantity: Variant, command_id: String) -> CommandResult:
	# Dedup
	var cached = world.get_economic(command_id)
	if cached != null:
		return CommandResult.fail("duplicate_command", cached if typeof(cached) == TYPE_DICTIONARY else {})
	if typeof(quantity) != TYPE_INT and typeof(quantity) != TYPE_FLOAT:
		return CommandResult.fail("invalid_quantity")
	if typeof(quantity) == TYPE_FLOAT and float(quantity) != floor(float(quantity)):
		return CommandResult.fail("invalid_quantity")
	var qty := int(quantity)
	if qty <= 0 or qty > 999:
		return CommandResult.fail("invalid_quantity")
	if not content.items.has(item_id):
		return CommandResult.fail("invalid_target")
	if not calendar.stall_open():
		return CommandResult.fail("stall_closed")
	var unit: int = int(content.item(item_id).get("buy_price", 0))
	var total: int = unit * qty
	if player.wallet < total:
		return CommandResult.fail("insufficient_funds")
	if not inventory.can_add(player, item_id, qty):
		return CommandResult.fail("inventory_full")
	player.wallet -= total
	inventory.add(player, item_id, qty)
	var result := {"ok": true, "reason_code": "ok", "item_id": item_id, "quantity": qty, "spent": total}
	world.remember_economic(command_id, result)
	world.bump_revision()
	return CommandResult.success([{"kind": "bought", "item_id": item_id, "quantity": qty, "spent": total}], result)

func sell(player: PlayerState, item_id: String, quantity: Variant, command_id: String) -> CommandResult:
	var cached = world.get_economic(command_id)
	if cached != null:
		return CommandResult.fail("duplicate_command", cached if typeof(cached) == TYPE_DICTIONARY else {})
	if typeof(quantity) != TYPE_INT and typeof(quantity) != TYPE_FLOAT:
		return CommandResult.fail("invalid_quantity")
	if typeof(quantity) == TYPE_FLOAT and float(quantity) != floor(float(quantity)):
		return CommandResult.fail("invalid_quantity")
	var qty := int(quantity)
	if qty <= 0 or qty > 999:
		return CommandResult.fail("invalid_quantity")
	if not content.items.has(item_id):
		return CommandResult.fail("invalid_target")
	if not calendar.stall_open():
		return CommandResult.fail("stall_closed")
	if not inventory.can_remove(player, item_id, qty):
		return CommandResult.fail("insufficient_items")
	var unit: int = int(content.item(item_id).get("sell_price", 0))
	var total: int = unit * qty
	inventory.remove(player, item_id, qty)
	player.wallet += total
	var result := {"ok": true, "reason_code": "ok", "item_id": item_id, "quantity": qty, "earned": total}
	world.remember_economic(command_id, result)
	world.bump_revision()
	return CommandResult.success([{"kind": "sold", "item_id": item_id, "quantity": qty, "earned": total}], result)
