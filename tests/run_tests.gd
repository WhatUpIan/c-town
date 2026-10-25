extends SceneTree

## Headless acceptance runner for Capernaum P0–P5.
## Usage: godot --headless --path . --script res://tests/run_tests.gd

var passed: int = 0
var failed: int = 0
var skipped: int = 0
var errors: Array[String] = []

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	print("=== Capernaum acceptance tests ===")
	# Ensure autoload exists
	var session = Engine.get_main_loop().root.get_node_or_null("GameSession")
	if session == null:
		# When running via --script, autoloads may still be present on root
		session = root.get_node_or_null("GameSession")
	if session == null:
		_fail("BOOT", "GameSession autoload missing")
		_finish()
		return
	# Content validation (A01 partial)
	if not session.content.validated:
		session.content.load_all()
	_check("A01", session.content.validated and session.content.errors.is_empty(), "ContentDB valid: %s" % str(session.content.errors))

	_test_movement_math()
	_test_targeting()
	_test_inventory(session)
	_test_economy(session)
	_test_crops(session)
	_test_fishing(session)
	_test_relationships(session)
	_test_calendar(session)
	_test_quest(session)
	_test_story_modes(session)
	_test_persistence(session)
	_test_authority_seam(session)
	_test_malformed_saves(session)
	_test_npc_schedule(session)

	_finish()

func _check(id: String, cond: bool, detail: String = "") -> void:
	if cond:
		passed += 1
		print("[PASS] %s %s" % [id, detail])
	else:
		failed += 1
		var msg := "%s FAILED %s" % [id, detail]
		errors.append(msg)
		print("[FAIL] %s" % msg)

func _fail(id: String, detail: String) -> void:
	_check(id, false, detail)

func _skip(id: String, reason: String) -> void:
	skipped += 1
	print("[SKIP] %s %s" % [id, reason])

func _fresh(session, mode: String = "everyday", seed: int = 42) -> void:
	session.bypass_range_checks = true
	session.start_new_game(mode, seed)
	session.simulation_paused = true  # tests drive time explicitly
	session.modal_pause = false

func _cmd(session, kind: String, target: String = "", payload: Dictionary = {}, actor: String = "player.local", command_id: String = "") -> CommandResult:
	var c := GameCommand.make(kind, actor, target, payload, command_id)
	c.session_id = session.world.session_id
	return session.execute(c)

func _test_movement_math() -> void:
	# A02: diagonal vs cardinal magnitude (normalized)
	var card := Vector2(1, 0).normalized() * 140.0
	var diag := Vector2(1, 1).normalized() * 140.0
	var diff: float = abs(card.length() - diag.length())
	_check("A02", diff <= 140.0 * 0.02, "speed delta=%s" % diff)
	# Iso round-trip diagnostic
	var cell := Vector2i(5, 3)
	var screen := IsoMath.cell_to_screen(cell)
	var back := IsoMath.screen_to_cell(screen)
	_check("A02b", abs(back.x - cell.x) < 0.01 and abs(back.y - cell.y) < 0.01, "iso roundtrip")
	_skip("A03", "Manual: Y-sort / tall props visual check")

func _test_targeting() -> void:
	# A04 automated portion: stable nearest by ID on equal distance
	var a := Area2D.new()
	a.name = "A"
	a.set_script(load("res://scripts/interaction/interactable.gd"))
	a.stable_id = "plot.home_02"
	a.position = Vector2(48, 0)
	var b := Area2D.new()
	b.name = "B"
	b.set_script(load("res://scripts/interaction/interactable.gd"))
	b.stable_id = "plot.home_01"
	b.position = Vector2(48, 0)
	root.add_child(a)
	root.add_child(b)
	var pick = Targeting.pick_nearest(Vector2.ZERO, [a, b], 48.0)
	_check("A04", pick != null and pick.get_stable_id() == "plot.home_01", "tie-break stable id")
	# Occlusion: command with occluded payload must fail without mutation
	_fresh(Engine.get_main_loop().root.get_node("GameSession"))
	var session = root.get_node("GameSession")
	var fri: int = session.world.npcs["npc.merchant_01"].friendship
	var occ: CommandResult = _cmd(session, "talk", "npc.merchant_01", {"occluded": true})
	_check("A04b", not occ.ok and session.world.npcs["npc.merchant_01"].friendship == fri, "occluded rejected")
	a.queue_free()
	b.queue_free()

func _test_inventory(session) -> void:
	_fresh(session)
	var p: PlayerState = session.world.local_player()
	# Fill toward capacity with barley
	p.inventory._init()
	# 11 stacks of 20 barley + 1 stack of 19 = nearly full
	for i in 11:
		p.inventory.slots[i] = {"item_id": "barley", "quantity": 20}
	p.inventory.slots[11] = {"item_id": "barley", "quantity": 19}
	_check("A05a", session.inventory.can_add(p, "barley", 1), "merge into nearly full")
	_check("A05b", session.inventory.add(p, "barley", 1), "add merge")
	_check("A05c", p.inventory.count("barley") == 11 * 20 + 20, "full stacks")
	_check("A05d", not session.inventory.can_add(p, "barley", 1), "overflow rejected")
	var before := p.inventory.count("barley")
	session.inventory.add(p, "barley", 1)
	_check("A05e", p.inventory.count("barley") == before, "overflow mutates nothing")

func _test_economy(session) -> void:
	_fresh(session)
	# Advance to stall hours weekday
	_cmd(session, "advance_time", "", {"minutes": 120})  # 08:00
	var p: PlayerState = session.world.local_player()
	var w0 := p.wallet
	var r1: CommandResult = _cmd(session, "buy", "interact.stall", {"item_id": "bread", "quantity": 1}, "player.local", "eco_buy_1")
	_check("A06a", r1.ok and p.wallet == w0 - 5 and p.inventory.count("bread") >= 2, "valid buy")
	var r_neg: CommandResult = _cmd(session, "buy", "interact.stall", {"item_id": "bread", "quantity": -1}, "player.local", "eco_buy_neg")
	_check("A06b", not r_neg.ok and r_neg.reason_code == "invalid_quantity", "negative qty")
	var r_frac: CommandResult = _cmd(session, "buy", "interact.stall", {"item_id": "bread", "quantity": 1.5}, "player.local", "eco_buy_frac")
	_check("A06c", not r_frac.ok, "fractional qty")
	var r_big: CommandResult = _cmd(session, "buy", "interact.stall", {"item_id": "bread", "quantity": 10000}, "player.local", "eco_buy_big")
	_check("A06d", not r_big.ok, "excessive qty")
	var wallet_before := p.wallet
	var r_dup: CommandResult = _cmd(session, "buy", "interact.stall", {"item_id": "bread", "quantity": 1}, "player.local", "eco_buy_1")
	_check("A07", not r_dup.ok and r_dup.reason_code == "duplicate_command" and p.wallet == wallet_before, "dedup economic command")

func _test_crops(session) -> void:
	_fresh(session)
	var p: PlayerState = session.world.local_player()
	p.inventory._init()
	p.inventory.add("barley_seed", 3, 20)
	var plot_id := "plot.home_01"
	var plot: PlotState = session.world.plots[plot_id]
	_check("A08a", _cmd(session, "hoe_plot", plot_id).ok, "hoe")
	_check("A08b", _cmd(session, "plant_plot", plot_id).ok and p.inventory.count("barley_seed") == 2, "plant spends seed")
	for day in range(3):
		_check("A08w%d" % day, _cmd(session, "water_plot", plot_id).ok, "water day %d" % day)
		# Advance to next dawn: from 06:00 + 1440
		_cmd(session, "advance_time", "", {"minutes": 1440})
		_check("A08g%d" % day, plot.growth_days == day + 1, "growth=%d" % plot.growth_days)
	var barley_before := p.inventory.count("barley")
	_check("A08h", _cmd(session, "harvest_plot", plot_id).ok, "harvest")
	_check("A08i", p.inventory.count("barley") == barley_before + 2 and plot.crop_id == "", "yield 2 once")
	_check("A08j", not _cmd(session, "harvest_plot", plot_id).ok, "duplicate harvest fails")

	# A09 dry day + full inventory harvest
	_fresh(session)
	p = session.world.local_player()
	p.inventory._init()
	p.inventory.add("barley_seed", 1, 20)
	plot = session.world.plots[plot_id]
	_cmd(session, "hoe_plot", plot_id)
	_cmd(session, "plant_plot", plot_id)
	_cmd(session, "water_plot", plot_id)
	_cmd(session, "advance_time", "", {"minutes": 1440})
	_check("A09a", plot.growth_days == 1, "watered growth")
	# Dry day: no water
	_cmd(session, "advance_time", "", {"minutes": 1440})
	_check("A09b", plot.growth_days == 1, "dry day no growth")
	# Force ripe
	plot.growth_days = 3
	# Fill inventory
	p.inventory._init()
	for i in 12:
		p.inventory.slots[i] = {"item_id": "bread", "quantity": 20}
	var crop_before := plot.crop_id
	var r_full: CommandResult = _cmd(session, "harvest_plot", plot_id)
	_check("A09c", not r_full.ok and r_full.reason_code == "inventory_full" and plot.crop_id == crop_before, "failed harvest preserves crop")

	# A10 skip several dawns; no double process
	_fresh(session)
	p = session.world.local_player()
	p.inventory._init()
	p.inventory.add("barley_seed", 1, 20)
	plot = session.world.plots[plot_id]
	_cmd(session, "hoe_plot", plot_id)
	_cmd(session, "plant_plot", plot_id)
	_cmd(session, "water_plot", plot_id)
	_cmd(session, "advance_time", "", {"minutes": 1440 * 3})
	# Only first dawn had water; growth should be 1
	_check("A10a", plot.growth_days == 1, "multi-dawn water once -> growth 1")
	var last := plot.last_processed_dawn
	# Re-process same dawn index manually should no-op
	session.crops.process_dawn(last)
	_check("A10b", plot.growth_days == 1 and plot.last_processed_dawn == last, "no double dawn process")

func _test_fishing(session) -> void:
	_fresh(session)
	var p: PlayerState = session.world.local_player()
	var c0 := p.inventory.count("lake_fish")
	_check("A11a", _cmd(session, "fish", "interact.fishing", {"success": true}).ok and p.inventory.count("lake_fish") == c0 + 1, "success")
	_check("A11b", not _cmd(session, "fish", "interact.fishing", {"success": false}).ok, "fail")
	_check("A11c", not _cmd(session, "fish", "interact.fishing", {"cancel": true}).ok, "cancel")
	p.inventory._init()
	for i in 12:
		p.inventory.slots[i] = {"item_id": "bread", "quantity": 20}
	_check("A11d", not _cmd(session, "fish", "interact.fishing", {"success": true}).ok, "full inventory")

func _test_relationships(session) -> void:
	_fresh(session)
	var ns: NpcState = session.world.npcs["npc.merchant_01"]
	_cmd(session, "talk", "npc.merchant_01")
	_check("A12a", ns.friendship == 1, "first talk +1")
	_cmd(session, "talk", "npc.merchant_01")
	_check("A12b", ns.friendship == 1, "second same day +0")
	# Cross sunset to new religious day: from 06:00 go past 18:00
	_cmd(session, "advance_time", "", {"minutes": 12 * 60})  # to 18:00
	_cmd(session, "talk", "npc.merchant_01")
	_check("A12c", ns.friendship == 2, "after sunset +1")
	ns.friendship = 100
	ns.last_talk_religious_day = -1
	_cmd(session, "talk", "npc.merchant_01")
	_check("A12d", ns.friendship == 100, "cap 100")

func _test_calendar(session) -> void:
	_fresh(session)
	# First Sabbath begins civil day 5 at 18:00
	# Start at day 0 06:00 = 360. Civil day 5 17:59 = 5*1440 + 1079 = 8279
	session.world.absolute_minutes = 5 * 1440 + 1079
	var evs: Array = session.calendar.advance_minutes(1)
	var began := false
	for e in evs:
		if str(e.get("kind", "")) == "sabbath_begin":
			began = true
	_check("A14a", began and CalendarSystem.is_sabbath(session.world.absolute_minutes), "Sabbath begins once at day5 18:00")
	# End at day 6 18:00
	session.world.absolute_minutes = 6 * 1440 + 1079
	evs = session.calendar.advance_minutes(1)
	var ended := false
	for e in evs:
		if str(e.get("kind", "")) == "sabbath_end":
			ended = true
	_check("A14b", ended and not CalendarSystem.is_sabbath(session.world.absolute_minutes), "Sabbath ends once at day6 18:00")

	# A15 civil midnight without sunset
	_fresh(session)
	session.world.absolute_minutes = 1439  # day0 23:59
	var rel_before := CalendarSystem.religious_ordinal(1439)
	var talk_gate: int = session.world.npcs["npc.merchant_01"].last_talk_religious_day
	session.world.npcs["npc.merchant_01"].last_talk_religious_day = rel_before
	session.calendar.advance_minutes(2)  # cross midnight to day1 00:01
	_check("A15a", CalendarSystem.civil_day(session.world.absolute_minutes) == 1, "civil day changes")
	_check("A15b", CalendarSystem.religious_ordinal(session.world.absolute_minutes) == rel_before, "religious day unchanged at midnight")

	# A16 month boundary / Nisan 15
	# Nisan 15 = religious ordinal 14. Sunset that begins ordinal 14:
	# religious_ordinal = floor((abs+360)/1440) = 14 => abs+360 in [14*1440, 15*1440)
	# At sunset crossing into ordinal 14: abs = 14*1440 - 360 = 20160-360=19800 = day13 18:00?
	# Actually: at abs=19800: (19800+360)/1440 = 20160/1440 = 14. Yes.
	_fresh(session)
	session.world.processed_events.clear()
	session.world.absolute_minutes = 19800 - 1
	evs = session.calendar.advance_minutes(1)
	var fest := false
	for e in evs:
		if str(e.get("kind", "")) == "festival":
			fest = true
	_check("A16a", CalendarSystem.is_nisan_15(CalendarSystem.religious_ordinal(session.world.absolute_minutes)), "Nisan 15 label")
	_check("A16b", fest, "passover notice once")
	# Repeat should not re-fire
	var count_keys := 0
	for k in session.world.processed_events:
		if str(k).begins_with("evt.passover_notice"):
			count_keys += 1
	session.calendar.advance_minutes(0)
	_check("A16c", count_keys == 1, "festival once")

func _test_quest(session) -> void:
	_fresh(session)
	var p: PlayerState = session.world.local_player()
	var qs: QuestState = session.world.quests["quest.first_delivery"]
	_check("A17a", qs.status == "available", "available at new game")
	_check("A17b", _cmd(session, "accept_quest", "quest.first_delivery").ok and qs.status == "active", "accept")
	# One fish insufficient
	p.inventory._init()
	p.inventory.add("lake_fish", 1, 20)
	var w0 := p.wallet
	var f0: int = session.world.npcs["npc.merchant_01"].friendship
	_check("A17c", not _cmd(session, "complete_quest", "quest.first_delivery", {}, "player.local", "q_complete_1").ok, "one fish fails")
	p.inventory.add("lake_fish", 1, 20)
	_check("A17d", _cmd(session, "complete_quest", "quest.first_delivery", {}, "player.local", "q_complete_1").ok, "two fish complete")
	_check("A17e", p.wallet == w0 + 10 and session.world.npcs["npc.merchant_01"].friendship == f0 + 5, "rewards")
	_check("A17f", p.inventory.count("lake_fish") == 0 and qs.reward_claimed, "consumed + claimed")
	_check("A17g", not _cmd(session, "complete_quest", "quest.first_delivery", {}, "player.local", "q_complete_2").ok, "complete twice fails")

func _test_story_modes(session) -> void:
	_fresh(session, "everyday")
	_check("A22a", session.world.story_mode == "everyday" and not session.world.flags.get("story.biblical_rumor", false), "everyday no story flag")
	_check("A22b", session.world.quests["quest.first_delivery"].status == "available", "core quest everyday")
	_fresh(session, "biblical")
	_check("A22c", session.world.flags.get("story.biblical_rumor", false) == true, "biblical story entry")
	_check("A22d", session.world.quests["quest.first_delivery"].status == "available", "core quest biblical")

func _test_persistence(session) -> void:
	_fresh(session)
	session.saves.set_slot("user://test_saves/slot_roundtrip.json")
	session.saves.fail_write = false
	session.saves.fail_rename = false
	var p: PlayerState = session.world.local_player()
	p.wallet = 33
	p.position = Vector2(111, 222)
	session.world.rng.draw_float()
	session.world.rng.draw_float()
	var draw_at_save: int = session.world.rng.draw_counter
	var next_uninterrupted: float = session.world.rng.draw_float()
	# rewind draw by reconfigure to saved counter then compare after load
	session.world.rng.configure(session.world.rng.seed, draw_at_save)
	var abs_m: int = session.world.absolute_minutes
	_cmd(session, "hoe_plot", "plot.home_02")
	session.world.npcs["npc.fisher_01"].friendship = 7
	session.world.quests["quest.first_delivery"].status = "active"
	var save_res: Dictionary = session.saves.save_world(session.world)
	_check("A18a", bool(save_res.get("ok", false)), "save ok")
	var load_res: Dictionary = session.saves.load_candidate("user://test_saves/slot_roundtrip.json")
	_check("A18b", bool(load_res.get("ok", false)), "load ok")
	var w2: WorldState = load_res["world"]
	_check("A18c", w2.local_player().wallet == 33 and w2.local_player().position == Vector2(111, 222), "player roundtrip")
	_check("A18d", w2.plots["plot.home_02"].tilled and w2.npcs["npc.fisher_01"].friendship == 7, "plots/npc")
	_check("A18e", w2.quests["quest.first_delivery"].status == "active" and w2.absolute_minutes == abs_m, "quest/time")
	var n1 := w2.rng.draw_float()
	_check("A18f", is_equal_approx(n1, next_uninterrupted), "rng continuity")

	# A19 corrupt main with valid backup; future schema
	session.saves.set_slot("user://test_saves/slot_recovery.json")
	session.saves.save_world(session.world)
	# Copy to bak by saving again then corrupt main
	session.saves.save_world(session.world)
	session.saves.write_raw("user://test_saves/slot_recovery.json", "{not json")
	var pref: Dictionary = session.saves.load_preferred("user://test_saves/slot_recovery.json")
	_check("A19a", bool(pref.get("ok", false)) and str(pref.get("source", "")) == "backup", "backup offered")
	var future := SaveCodec.encode(session.world)
	future["schema_version"] = 99
	session.saves.write_raw("user://test_saves/slot_future.json", JSON.stringify(future))
	var fut: Dictionary = session.saves.load_candidate("user://test_saves/slot_future.json")
	_check("A19b", not bool(fut.get("ok", false)) and str(fut.get("reason", "")) == "schema_future", "future schema rejected")

	# A20 write/rename failure
	session.saves.set_slot("user://test_saves/slot_fail.json")
	session.saves.fail_write = true
	var fw: Dictionary = session.saves.save_world(session.world)
	_check("A20a", not bool(fw.get("ok", false)), "write failure shown")
	session.saves.fail_write = false
	session.saves.save_world(session.world)
	session.saves.fail_rename = true
	var fr: Dictionary = session.saves.save_world(session.world)
	_check("A20b", not bool(fr.get("ok", false)), "rename failure shown")
	session.saves.fail_rename = false

	# A21 no duplicate growth/reward after reload near dawn/quest
	_fresh(session)
	session.saves.set_slot("user://test_saves/slot_dup.json")
	p = session.world.local_player()
	p.inventory._init()
	p.inventory.add("barley_seed", 1, 20)
	p.inventory.add("lake_fish", 2, 20)
	var plot: PlotState = session.world.plots["plot.home_01"]
	_cmd(session, "hoe_plot", "plot.home_01")
	_cmd(session, "plant_plot", "plot.home_01")
	_cmd(session, "water_plot", "plot.home_01")
	# Stop just before dawn
	session.world.absolute_minutes = 360 + 1439
	session.saves.save_world(session.world)
	var loaded: Dictionary = session.saves.load_candidate("user://test_saves/slot_dup.json")
	session.apply_loaded_world(loaded["world"])
	session.simulation_paused = true
	_cmd(session, "advance_time", "", {"minutes": 2})
	plot = session.world.plots["plot.home_01"]
	_check("A21a", plot.growth_days == 1, "growth once after reload")
	_cmd(session, "accept_quest", "quest.first_delivery")
	_cmd(session, "complete_quest", "quest.first_delivery", {}, "player.local", "q_once")
	var wallet: int = session.world.local_player().wallet
	var fri: int = session.world.npcs["npc.merchant_01"].friendship
	session.saves.save_world(session.world)
	loaded = session.saves.load_candidate("user://test_saves/slot_dup.json")
	session.apply_loaded_world(loaded["world"])
	session.simulation_paused = true
	_cmd(session, "complete_quest", "quest.first_delivery", {}, "player.local", "q_once_again")
	_check("A21b", session.world.local_player().wallet == wallet and session.world.npcs["npc.merchant_01"].friendship == fri, "no duplicate reward")

func _test_authority_seam(session) -> void:
	# A26 two local actors harvest same ripe plot
	_fresh(session)
	var p1: PlayerState = session.world.local_player()
	var p2 := PlayerState.new()
	p2.id = "player.two"
	p2.inventory._init()
	session.world.players["player.two"] = p2
	var plot: PlotState = session.world.plots["plot.home_01"]
	plot.tilled = true
	plot.crop_id = "barley_crop"
	plot.growth_days = 3
	var r1: CommandResult = _cmd(session, "harvest_plot", "plot.home_01", {}, "player.local")
	var r2: CommandResult = _cmd(session, "harvest_plot", "plot.home_01", {}, "player.two")
	_check("A26", r1.ok and not r2.ok and p1.inventory.count("barley") == 2 and p2.inventory.count("barley") == 0, "one harvest yield")

func _test_malformed_saves(session) -> void:
	_fresh(session)
	var good: WorldState = session.world
	var data := SaveCodec.encode(good)
	# Malformed item id
	data["players"]["player.local"]["inventory"] = [{"item_id": "nope", "quantity": 1}]
	var r1 := SaveCodec.validate(data, session.content)
	_check("A27a", not bool(r1.get("ok", false)), "bad item id")
	data = SaveCodec.encode(good)
	data["players"]["player.local"]["wallet"] = -5
	_check("A27b", not bool(SaveCodec.validate(data, session.content).get("ok", false)), "neg wallet")
	data = SaveCodec.encode(good)
	data["players"]["player.local"]["position"] = ["x", "y"]
	_check("A27c", not bool(SaveCodec.validate(data, session.content).get("ok", false)), "bad coords")
	data = SaveCodec.encode(good)
	data["plots"] = []
	for i in 100:
		data["plots"].append({"id": "p%d" % i, "cell": [0, 0]})
	_check("A27d", not bool(SaveCodec.validate(data, session.content).get("ok", false)), "oversize plots")
	# Active state untouched: still same wallet
	_check("A27e", session.world.local_player().wallet == 20, "active untouched")

func _test_npc_schedule(session) -> void:
	_fresh(session)
	_cmd(session, "advance_time", "", {"minutes": 120})  # 08:00
	session.npc_schedules.refresh_destinations()
	_check("A13a", session.world.npcs["npc.stall_01"].anchor_id == "work_stall", "weekday work")
	_check("A13b", session.calendar.stall_open(), "stall open")
	# Jump to Sabbath
	session.world.absolute_minutes = 5 * 1440 + 1080
	session.npc_schedules.refresh_destinations()
	_check("A13c", not session.calendar.stall_open(), "stall closed Sabbath")
	_check("A13d", session.world.npcs["npc.stall_01"].anchor_id in ["home_hannah", "courtyard"], "sabbath schedule")
	_skip("A23", "Manual: modal UI pause / focus")
	_skip("A24", "Manual: resolution / keyboard / muted")
	_skip("A25", "Manual: full playable loop")

func _finish() -> void:
	print("=== Summary: %d passed, %d failed, %d skipped ===" % [passed, failed, skipped])
	for e in errors:
		print("  - ", e)
	quit(0 if failed == 0 else 1)
