class_name QuestSystem
extends RefCounted

signal quest_changed(quest_id: String)

var world: WorldState
var content: ContentDB
var inventory: InventorySystem

func bind(p_world: WorldState, p_content: ContentDB, p_inv: InventorySystem) -> void:
	world = p_world
	content = p_content
	inventory = p_inv

func accept(quest_id: String) -> CommandResult:
	var qs: QuestState = world.quests.get(quest_id)
	if qs == null:
		return CommandResult.fail("invalid_target")
	var def: Dictionary = content.quests.get(quest_id, {})
	var mode_filter: String = str(def.get("story_mode_filter", "any"))
	if mode_filter != "any" and mode_filter != world.story_mode:
		return CommandResult.fail("blocked")
	if qs.status == "completed":
		return CommandResult.fail("quest_already_done")
	if qs.status == "active":
		return CommandResult.success([], {"already_active": true})
	if qs.status != "available":
		return CommandResult.fail("blocked")
	qs.status = "active"
	world.bump_revision()
	quest_changed.emit(quest_id)
	return CommandResult.success([{"kind": "quest_accepted", "quest_id": quest_id}])

func complete(quest_id: String, player: PlayerState, command_id: String = "") -> CommandResult:
	var qs: QuestState = world.quests.get(quest_id)
	if qs == null:
		return CommandResult.fail("invalid_target")
	if command_id != "":
		var cached = world.get_economic(command_id)
		if cached != null:
			return CommandResult.fail("duplicate_command")
	if qs.status != "active":
		if qs.status == "completed" or qs.reward_claimed:
			return CommandResult.fail("quest_already_done")
		return CommandResult.fail("quest_incomplete")
	if qs.reward_claimed:
		return CommandResult.fail("quest_already_done")
	var def: Dictionary = content.quests.get(quest_id, {})
	var reqs: Dictionary = def.get("requirements", {})
	for item_id in reqs:
		var need: int = int(reqs[item_id])
		if not inventory.can_remove(player, item_id, need):
			return CommandResult.fail("insufficient_items")
	# Atomic: remove items, grant rewards
	for item_id in reqs:
		inventory.remove(player, item_id, int(reqs[item_id]))
	var reward: Dictionary = def.get("reward", {})
	var money: int = int(reward.get("money", 0))
	player.wallet += money
	var fnpc: String = str(reward.get("friendship_npc", ""))
	var fdelta: int = int(reward.get("friendship_delta", 0))
	if fnpc != "" and world.npcs.has(fnpc):
		var ns: NpcState = world.npcs[fnpc]
		ns.friendship = mini(100, ns.friendship + fdelta)
	qs.status = "completed"
	qs.reward_claimed = true
	if command_id != "":
		world.remember_economic(command_id, {"ok": true, "quest_id": quest_id})
	world.bump_revision()
	quest_changed.emit(quest_id)
	return CommandResult.success([{"kind": "quest_completed", "quest_id": quest_id, "money": money}], {"money": money})
