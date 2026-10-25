class_name CropSystem
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

func process_dawn(dawn_idx: int) -> Array:
	var events: Array = []
	for pid in world.plots:
		var plot: PlotState = world.plots[pid]
		if plot.last_processed_dawn >= dawn_idx:
			continue
		# Only process this dawn once
		if plot.crop_id != "" and plot.watered_for_day:
			var def: Dictionary = content.crops.get(plot.crop_id, {})
			var max_g: int = int(def.get("growth_days", 3))
			if plot.growth_days < max_g:
				plot.growth_days += 1
				events.append({"kind": "crop_grew", "plot_id": pid, "growth_days": plot.growth_days})
		# Dry day: no growth, crop not killed
		plot.watered_for_day = false
		plot.last_processed_dawn = dawn_idx
	return events

func hoe(plot: PlotState) -> CommandResult:
	if plot.tilled and plot.crop_id == "":
		return CommandResult.fail("already_tilled")
	if plot.crop_id != "":
		return CommandResult.fail("already_planted")
	plot.tilled = true
	return CommandResult.success([{"kind": "tilled", "plot_id": plot.id}])

func plant(plot: PlotState, player: PlayerState, crop_id: String = "barley_crop") -> CommandResult:
	if not plot.tilled:
		return CommandResult.fail("not_tilled")
	if plot.crop_id != "":
		return CommandResult.fail("already_planted")
	var def: Dictionary = content.crops.get(crop_id, {})
	if def.is_empty():
		return CommandResult.fail("invalid_target")
	var seed_id: String = str(def.get("seed_item_id", ""))
	if not inventory.can_remove(player, seed_id, 1):
		return CommandResult.fail("no_seed")
	inventory.remove(player, seed_id, 1)
	plot.crop_id = crop_id
	plot.growth_days = 0
	plot.watered_for_day = false
	return CommandResult.success([{"kind": "planted", "plot_id": plot.id, "crop_id": crop_id}])

func water(plot: PlotState) -> CommandResult:
	if plot.crop_id == "":
		return CommandResult.fail("needs_water")
	if plot.watered_for_day:
		return CommandResult.fail("needs_water")
	var def: Dictionary = content.crops.get(plot.crop_id, {})
	var max_g: int = int(def.get("growth_days", 3))
	if plot.growth_days >= max_g:
		return CommandResult.fail("needs_water")
	plot.watered_for_day = true
	return CommandResult.success([{"kind": "watered", "plot_id": plot.id}])

func harvest(plot: PlotState, player: PlayerState) -> CommandResult:
	if plot.crop_id == "":
		return CommandResult.fail("not_ripe")
	var def: Dictionary = content.crops.get(plot.crop_id, {})
	var max_g: int = int(def.get("growth_days", 3))
	if plot.growth_days < max_g:
		return CommandResult.fail("not_ripe")
	var item_id: String = str(def.get("harvest_item_id", ""))
	var qty: int = int(def.get("yield_count", 2))
	if not inventory.can_add(player, item_id, qty):
		return CommandResult.fail("inventory_full")
	inventory.add(player, item_id, qty)
	# Reset to tilled empty soil
	plot.crop_id = ""
	plot.growth_days = 0
	plot.watered_for_day = false
	plot.tilled = true
	return CommandResult.success([{"kind": "harvested", "plot_id": plot.id, "item_id": item_id, "quantity": qty}])
