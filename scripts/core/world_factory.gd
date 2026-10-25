class_name WorldFactory
extends RefCounted

static func new_game(content: ContentDB, story_mode: String = "everyday", rng_seed: int = 12345) -> WorldState:
	var w := WorldState.new()
	w.story_mode = story_mode
	w.session_id = "session.%d" % Time.get_unix_time_from_system()
	w.absolute_minutes = 360  # day 0 @ 06:00
	w.rng.configure(rng_seed, 0)
	w.flags = {}
	w.processed_events = []

	var player := PlayerState.new()
	player.id = "player.local"
	player.map_id = "village"
	player.position = Vector2(280, 190)
	player.wallet = 20
	player.selected_tool = "hand"
	player.inventory._init()
	# Starting items: 3 barley seeds, 1 bread, 20 trade units (wallet)
	player.inventory.add("barley_seed", 3, content.max_stack("barley_seed"))
	player.inventory.add("bread", 1, content.max_stack("bread"))
	w.players["player.local"] = player

	# Six home plots; dawn index 0 already processed at New Game
	var plot_cells := [
		Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8),
		Vector2i(6, 9), Vector2i(7, 9), Vector2i(8, 9),
	]
	for i in range(6):
		var ps := PlotState.new()
		ps.id = "plot.home_%02d" % (i + 1)
		ps.cell = plot_cells[i]
		ps.tilled = false
		ps.last_processed_dawn = 0  # dawn index 0 already processed
		w.plots[ps.id] = ps

	for nid in content.npcs:
		var ns := NpcState.new()
		ns.id = nid
		ns.friendship = 0
		ns.last_talk_religious_day = -1
		ns.anchor_id = str(content.npcs[nid].get("home_anchor", "courtyard"))
		w.npcs[nid] = ns

	var qs := QuestState.new()
	qs.id = "quest.first_delivery"
	qs.status = "available"
	qs.reward_claimed = false
	w.quests[qs.id] = qs

	if story_mode == "biblical":
		w.flags["story.biblical_rumor"] = true

	return w
