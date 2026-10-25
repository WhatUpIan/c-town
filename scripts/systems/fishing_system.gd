class_name FishingSystem
extends RefCounted

var world: WorldState
var content: ContentDB
var inventory: InventorySystem

## Injected outcome for tests: null = use RNG, true/false = force
var injected_outcome: Variant = null

func bind(p_world: WorldState, p_content: ContentDB, p_inv: InventorySystem) -> void:
	world = p_world
	content = p_content
	inventory = p_inv

func attempt(player: PlayerState, success_override: Variant = null) -> CommandResult:
	var outcome: bool
	if success_override != null:
		outcome = bool(success_override)
	elif injected_outcome != null:
		outcome = bool(injected_outcome)
	else:
		outcome = world.rng.draw_bool(0.7)
	if not outcome:
		return CommandResult.fail("fishing_miss", {"success": false})
	if not inventory.can_add(player, "lake_fish", 1):
		return CommandResult.fail("inventory_full", {"success": true})
	inventory.add(player, "lake_fish", 1)
	world.bump_revision()
	return CommandResult.success([{"kind": "fish_caught", "item_id": "lake_fish", "quantity": 1}], {"success": true})
