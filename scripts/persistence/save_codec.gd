class_name SaveCodec
extends RefCounted

const SCHEMA_VERSION := 1
const MAX_BYTES := 5 * 1024 * 1024

static func encode(world: WorldState) -> Dictionary:
	var players := {}
	for pid in world.players:
		var p: PlayerState = world.players[pid]
		players[pid] = {
			"map_id": p.map_id,
			"position": [p.position.x, p.position.y],
			"facing": p.facing,
			"wallet": p.wallet,
			"selected_tool": p.selected_tool,
			"inventory": p.inventory.to_array(),
		}
	var plots := []
	for plot_id in world.plots:
		var pl: PlotState = world.plots[plot_id]
		plots.append({
			"id": pl.id,
			"cell": [pl.cell.x, pl.cell.y],
			"tilled": pl.tilled,
			"crop_id": pl.crop_id,
			"growth_days": pl.growth_days,
			"watered_for_day": pl.watered_for_day,
			"last_processed_dawn": pl.last_processed_dawn,
		})
	var npcs := {}
	for nid in world.npcs:
		var n: NpcState = world.npcs[nid]
		npcs[nid] = {
			"position": [n.position.x, n.position.y],
			"anchor_id": n.anchor_id,
			"friendship": n.friendship,
			"last_talk_religious_day": n.last_talk_religious_day,
		}
	var quests := {}
	for qid in world.quests:
		var q: QuestState = world.quests[qid]
		quests[qid] = {"status": q.status, "reward_claimed": q.reward_claimed}
	return {
		"schema_version": SCHEMA_VERSION,
		"game_version": world.game_version,
		"world_revision": world.world_revision,
		"era_id": world.era_id,
		"calendar_id": world.calendar_id,
		"story_mode": world.story_mode,
		"session_id": world.session_id,
		"absolute_minutes": world.absolute_minutes,
		"rng": {"seed": world.rng.seed, "draw_counter": world.rng.draw_counter},
		"players": players,
		"plots": plots,
		"npcs": npcs,
		"quests": quests,
		"flags": world.flags.duplicate(true),
		"processed_events": world.processed_events.duplicate(),
		"recent_economic_commands": world.recent_economic_commands.duplicate(true),
		"economic_order": world._economic_order.duplicate(),
	}

static func decode(data: Dictionary, content: ContentDB) -> Dictionary:
	## Returns {ok: bool, reason: String, world: WorldState}
	var check := validate(data, content)
	if not bool(check.get("ok", false)):
		return check
	var w := WorldState.new()
	w.schema_version = int(data.get("schema_version", 1))
	w.game_version = str(data.get("game_version", WorldState.GAME_VERSION))
	w.world_revision = int(data.get("world_revision", 0))
	w.era_id = str(data.get("era_id", WorldState.ERA_ID))
	w.calendar_id = str(data.get("calendar_id", WorldState.CALENDAR_ID))
	w.story_mode = str(data.get("story_mode", "everyday"))
	w.session_id = str(data.get("session_id", "session.loaded"))
	w.absolute_minutes = int(data.get("absolute_minutes", 360))
	var rng: Dictionary = data.get("rng", {})
	w.rng.configure(int(rng.get("seed", 12345)), int(rng.get("draw_counter", 0)))
	w.flags = data.get("flags", {}).duplicate(true)
	w.processed_events.clear()
	for e in data.get("processed_events", []):
		w.processed_events.append(str(e))
	w.recent_economic_commands = data.get("recent_economic_commands", {}).duplicate(true)
	w._economic_order.clear()
	for cid in data.get("economic_order", []):
		w._economic_order.append(str(cid))

	var players_data: Dictionary = data.get("players", {})
	for pid in players_data:
		var pd: Dictionary = players_data[pid]
		var p := PlayerState.new()
		p.id = str(pid)
		p.map_id = str(pd.get("map_id", "village"))
		var pos = pd.get("position", [280.0, 190.0])
		if typeof(pos) != TYPE_ARRAY or pos.size() < 2:
			return {"ok": false, "reason": "invalid_position"}
		p.position = Vector2(float(pos[0]), float(pos[1]))
		p.facing = str(pd.get("facing", "down"))
		p.wallet = int(pd.get("wallet", 0))
		p.selected_tool = str(pd.get("selected_tool", "hand"))
		p.inventory.from_array(pd.get("inventory", []))
		w.players[p.id] = p

	for pl in data.get("plots", []):
		if typeof(pl) != TYPE_DICTIONARY:
			continue
		var ps := PlotState.new()
		ps.id = str(pl.get("id", ""))
		var cell = pl.get("cell", [0, 0])
		ps.cell = Vector2i(int(cell[0]), int(cell[1]))
		ps.tilled = bool(pl.get("tilled", false))
		ps.crop_id = str(pl.get("crop_id", ""))
		ps.growth_days = int(pl.get("growth_days", 0))
		ps.watered_for_day = bool(pl.get("watered_for_day", false))
		ps.last_processed_dawn = int(pl.get("last_processed_dawn", 0))
		w.plots[ps.id] = ps

	var npcs_data: Dictionary = data.get("npcs", {})
	for nid in npcs_data:
		var nd: Dictionary = npcs_data[nid]
		var ns := NpcState.new()
		ns.id = str(nid)
		var npos = nd.get("position", [0.0, 0.0])
		ns.position = Vector2(float(npos[0]), float(npos[1]))
		ns.anchor_id = str(nd.get("anchor_id", ""))
		ns.friendship = int(nd.get("friendship", 0))
		ns.last_talk_religious_day = int(nd.get("last_talk_religious_day", -1))
		w.npcs[ns.id] = ns

	var quests_data: Dictionary = data.get("quests", {})
	for qid in quests_data:
		var qd: Dictionary = quests_data[qid]
		var qs := QuestState.new()
		qs.id = str(qid)
		qs.status = str(qd.get("status", "unavailable"))
		qs.reward_claimed = bool(qd.get("reward_claimed", false))
		w.quests[qs.id] = qs

	return {"ok": true, "reason": "ok", "world": w}

static func validate(data: Dictionary, content: ContentDB) -> Dictionary:
	if data.is_empty():
		return {"ok": false, "reason": "save_invalid"}
	var schema: Variant = data.get("schema_version", null)
	if typeof(schema) != TYPE_INT and typeof(schema) != TYPE_FLOAT:
		return {"ok": false, "reason": "save_invalid"}
	if int(schema) > SCHEMA_VERSION:
		return {"ok": false, "reason": "schema_future"}
	if int(schema) < 1:
		return {"ok": false, "reason": "save_invalid"}
	var mode := str(data.get("story_mode", ""))
	if mode != "everyday" and mode != "biblical":
		return {"ok": false, "reason": "save_invalid"}
	var abs_m: Variant = data.get("absolute_minutes", null)
	if not _is_int_value(abs_m):
		return {"ok": false, "reason": "save_invalid"}
	var players: Variant = data.get("players", null)
	if typeof(players) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "save_invalid"}
	if players.size() > 8:
		return {"ok": false, "reason": "save_invalid"}
	for pid in players:
		var pd: Variant = players[pid]
		if typeof(pd) != TYPE_DICTIONARY:
			return {"ok": false, "reason": "save_invalid"}
		if not _is_int_value(pd.get("wallet", null)):
			return {"ok": false, "reason": "save_invalid"}
		if int(pd.get("wallet", -1)) < 0:
			return {"ok": false, "reason": "save_invalid"}
		var pos: Variant = pd.get("position", null)
		if typeof(pos) != TYPE_ARRAY or pos.size() != 2:
			return {"ok": false, "reason": "save_invalid"}
		if typeof(pos[0]) != TYPE_FLOAT and typeof(pos[0]) != TYPE_INT:
			return {"ok": false, "reason": "save_invalid"}
		if typeof(pos[1]) != TYPE_FLOAT and typeof(pos[1]) != TYPE_INT:
			return {"ok": false, "reason": "save_invalid"}
		if not is_finite(float(pos[0])) or not is_finite(float(pos[1])):
			return {"ok": false, "reason": "save_invalid"}
		# Map bounds soft check
		if abs(float(pos[0])) > 10000.0 or abs(float(pos[1])) > 10000.0:
			return {"ok": false, "reason": "save_invalid"}
		for entry in pd.get("inventory", []):
			if typeof(entry) != TYPE_DICTIONARY:
				return {"ok": false, "reason": "save_invalid"}
			var iid := str(entry.get("item_id", ""))
			if content and not content.items.has(iid):
				return {"ok": false, "reason": "save_invalid"}
			if not _is_int_value(entry.get("quantity", null)):
				return {"ok": false, "reason": "save_invalid"}
			if int(entry.get("quantity", 0)) <= 0:
				return {"ok": false, "reason": "save_invalid"}
	var plots: Variant = data.get("plots", [])
	if typeof(plots) != TYPE_ARRAY or plots.size() > 64:
		return {"ok": false, "reason": "save_invalid"}
	var npcs: Variant = data.get("npcs", {})
	if typeof(npcs) != TYPE_DICTIONARY or npcs.size() > 64:
		return {"ok": false, "reason": "save_invalid"}
	return {"ok": true, "reason": "ok"}

static func _is_int_value(v: Variant) -> bool:
	if typeof(v) == TYPE_INT:
		return true
	if typeof(v) == TYPE_FLOAT:
		return float(v) == floor(float(v)) and is_finite(float(v))
	return false
