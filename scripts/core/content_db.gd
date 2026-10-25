class_name ContentDB
extends RefCounted

var items: Dictionary = {}  # id -> Dictionary def
var crops: Dictionary = {}
var npcs: Dictionary = {}
var dialogue: Dictionary = {}
var quests: Dictionary = {}
var calendar_events: Dictionary = {}
var localization: Dictionary = {}
var story: Dictionary = {}
var validated: bool = false
var errors: Array[String] = []

func load_all() -> bool:
	errors.clear()
	_load_builtin()
	_validate()
	validated = errors.is_empty()
	return validated

func _load_builtin() -> void:
	items = {
		"barley_seed": {"id": "barley_seed", "name_key": "item.barley_seed", "category": "seed", "max_stack": 20, "buy_price": 2, "sell_price": 1, "historical_note_id": "hn.barley"},
		"barley": {"id": "barley", "name_key": "item.barley", "category": "crop", "max_stack": 20, "buy_price": 4, "sell_price": 2, "historical_note_id": "hn.barley"},
		"lake_fish": {"id": "lake_fish", "name_key": "item.lake_fish", "category": "food", "max_stack": 20, "buy_price": 6, "sell_price": 3, "historical_note_id": "hn.fish"},
		"bread": {"id": "bread", "name_key": "item.bread", "category": "food", "max_stack": 20, "buy_price": 5, "sell_price": 2, "historical_note_id": "hn.bread"},
	}
	crops = {
		"barley_crop": {"id": "barley_crop", "seed_item_id": "barley_seed", "harvest_item_id": "barley", "growth_days": 3, "yield_count": 2, "water_required": true},
	}
	npcs = {
		"npc.merchant_01": {"id": "npc.merchant_01", "name_key": "npc.miriam", "home_anchor": "home_miriam", "schedule_id": "weekday_default", "dialogue_id": "dlg.miriam.root", "role": "gardener", "display_name": "Miriam"},
		"npc.fisher_01": {"id": "npc.fisher_01", "name_key": "npc.yehudah", "home_anchor": "home_yehudah", "schedule_id": "weekday_default", "dialogue_id": "dlg.yehudah.root", "role": "fisher", "display_name": "Yehudah"},
		"npc.stall_01": {"id": "npc.stall_01", "name_key": "npc.hannah", "home_anchor": "home_hannah", "schedule_id": "weekday_default", "dialogue_id": "dlg.hannah.root", "role": "merchant", "display_name": "Hannah"},
	}
	quests = {
		"quest.first_delivery": {
			"id": "quest.first_delivery",
			"giver_id": "npc.merchant_01",
			"requirements": {"lake_fish": 2},
			"reward": {"money": 10, "friendship_npc": "npc.merchant_01", "friendship_delta": 5},
			"prerequisites": [],
			"story_mode_filter": "any",
		},
	}
	dialogue = {
		"dlg.miriam.root": {"id": "dlg.miriam.root", "speaker_id": "npc.merchant_01", "text_key": "dlg.miriam.greeting", "choices": [
			{"text_key": "dlg.miriam.ask_garden", "next_id": "dlg.miriam.garden"},
			{"text_key": "dlg.miriam.quest", "next_id": "dlg.miriam.quest"},
			{"text_key": "dlg.common.goodbye", "next_id": ""},
		], "next_id": "", "mode_filter": "any"},
		"dlg.miriam.garden": {"id": "dlg.miriam.garden", "speaker_id": "npc.merchant_01", "text_key": "dlg.miriam.garden_text", "choices": [{"text_key": "dlg.common.back", "next_id": "dlg.miriam.root"}], "next_id": "", "mode_filter": "any"},
		"dlg.miriam.quest": {"id": "dlg.miriam.quest", "speaker_id": "npc.merchant_01", "text_key": "dlg.miriam.quest_text", "choices": [
			{"text_key": "dlg.miriam.accept", "next_id": "", "effects": [{"kind": "accept_quest", "quest_id": "quest.first_delivery"}]},
			{"text_key": "dlg.miriam.complete", "next_id": "", "effects": [{"kind": "complete_quest", "quest_id": "quest.first_delivery"}]},
			{"text_key": "dlg.common.back", "next_id": "dlg.miriam.root"},
		], "next_id": "", "mode_filter": "any"},
		"dlg.yehudah.root": {"id": "dlg.yehudah.root", "speaker_id": "npc.fisher_01", "text_key": "dlg.yehudah.greeting", "choices": [{"text_key": "dlg.common.goodbye", "next_id": ""}], "next_id": "", "mode_filter": "any"},
		"dlg.hannah.root": {"id": "dlg.hannah.root", "speaker_id": "npc.stall_01", "text_key": "dlg.hannah.greeting", "choices": [
			{"text_key": "dlg.hannah.trade", "next_id": "", "effects": [{"kind": "open_stall"}]},
			{"text_key": "dlg.common.goodbye", "next_id": ""},
		], "next_id": "", "mode_filter": "any"},
		"dlg.courtyard.passover": {"id": "dlg.courtyard.passover", "speaker_id": "npc.merchant_01", "text_key": "dlg.passover.notice", "choices": [{"text_key": "dlg.common.goodbye", "next_id": ""}], "next_id": "", "mode_filter": "any"},
		"dlg.biblical.rumor": {"id": "dlg.biblical.rumor", "speaker_id": "npc.fisher_01", "text_key": "dlg.biblical.rumor_text", "choices": [{"text_key": "dlg.common.goodbye", "next_id": ""}], "next_id": "", "mode_filter": "biblical"},
	}
	calendar_events = {
		"evt.passover_notice": {"id": "evt.passover_notice", "date_rule": "nisan_15", "duration_days": 1, "schedule_overrides": {}, "review_status": "provisional"},
	}
	story = {
		"story.biblical_rumor": {"id": "story.biblical_rumor", "mode_filter": "biblical", "passage_ref": "Mark 1:21 (reference only; no translation reproduced)", "journal_key": "story.biblical_rumor_summary"},
	}
	localization = {
		"item.barley_seed": "Barley seed",
		"item.barley": "Barley",
		"item.lake_fish": "Lake fish",
		"item.bread": "Bread",
		"npc.miriam": "Miriam",
		"npc.yehudah": "Yehudah",
		"npc.hannah": "Hannah",
		"dlg.miriam.greeting": "Peace to you. The garden beds need attention, and the lake is generous today.",
		"dlg.miriam.ask_garden": "How is the garden?",
		"dlg.miriam.garden_text": "Barley wants water each morning. Three watered dawns and it is ready.",
		"dlg.miriam.quest": "About the delivery…",
		"dlg.miriam.quest_text": "Could you bring me two lake fish? I will pay ten trade units.",
		"dlg.miriam.accept": "I will bring the fish.",
		"dlg.miriam.complete": "Here are two fish.",
		"dlg.yehudah.greeting": "The shoreline is quiet. Cast near the marker when the water flashes.",
		"dlg.hannah.greeting": "The stall is open while the sun is up—except on the Sabbath.",
		"dlg.hannah.trade": "Show me your goods.",
		"dlg.passover.notice": "Nisan 15 approaches. Neighbors speak of the Passover gathering in the courtyard. (Provisional notice — not a reconstructed ritual.)",
		"dlg.biblical.rumor_text": "Some say a teacher from Nazareth spoke in the synagogue. See journal note (Mark 1:21 referenced; original summary only).",
		"dlg.common.goodbye": "Peace.",
		"dlg.common.back": "Back",
		"story.biblical_rumor_summary": "Rumor of a teacher in Capernaum's synagogue. Original summary with passage reference only; no translation copied.",
		"tool.hand": "Hand",
		"tool.hoe": "Hoe",
		"tool.watering_jug": "Watering jug",
		"tool.fishing_net": "Fishing net",
		"notify.sabbath_approach": "The Sabbath approaches at sunset.",
		"notify.sabbath_begin": "Sabbath has begun. The stall is closed. Rest schedules apply.",
		"notify.sabbath_end": "Sabbath has ended.",
		"notify.rest_reminder": "It is late. A bed awaits at home.",
		"notify.rest_custom": "A day of rest. Gardening and fishing remain possible without penalty (design accommodation under review).",
		"reason.ok": "OK",
		"reason.insufficient_funds": "Not enough trade units.",
		"reason.insufficient_items": "Missing required items.",
		"reason.inventory_full": "Inventory is full.",
		"reason.invalid_quantity": "Invalid quantity.",
		"reason.stall_closed": "The stall is closed.",
		"reason.quest_incomplete": "Quest requirements not met.",
		"reason.quest_already_done": "Reward already claimed.",
		"reason.duplicate_command": "Command already applied.",
		"reason.wrong_session": "Wrong session.",
		"reason.invalid_target": "Invalid target.",
		"reason.blocked": "Action blocked.",
		"reason.bed_unavailable": "Bed usable from 18:00 until before 06:00.",
		"reason.not_tilled": "Soil needs tilling.",
		"reason.already_planted": "Plot already planted.",
		"reason.needs_water": "Already watered today, or nothing to water.",
		"reason.not_ripe": "Crop is not ripe.",
		"reason.no_seed": "No seed in inventory.",
		"reason.out_of_range": "Too far away.",
		"reason.save_invalid": "Save is invalid.",
		"reason.schema_future": "Save schema is newer than this build.",
		"reason.fishing_miss": "The fish slipped away — try again.",
		"reason.fishing_cancel": "You lower the net.",
	}

func tr_key(key: String) -> String:
	return str(localization.get(key, key))

func item(id: String) -> Dictionary:
	return items.get(id, {})

func max_stack(item_id: String) -> int:
	return int(item(item_id).get("max_stack", 0))

func _validate() -> void:
	for qid in quests:
		var q: Dictionary = quests[qid]
		for req_item in q.get("requirements", {}):
			if not items.has(req_item):
				errors.append("Quest %s requires unknown item %s" % [qid, req_item])
		var giver: String = str(q.get("giver_id", ""))
		if giver != "" and not npcs.has(giver):
			errors.append("Quest %s giver missing: %s" % [qid, giver])
	for did in dialogue:
		var d: Dictionary = dialogue[did]
		var sid: String = str(d.get("speaker_id", ""))
		if sid != "" and not npcs.has(sid) and not sid.begins_with("narrator"):
			# courtyard notice reuses Miriam — ok if present
			if not npcs.has(sid):
				errors.append("Dialogue %s unknown speaker %s" % [did, sid])
		for ch in d.get("choices", []):
			var nid: String = str(ch.get("next_id", ""))
			if nid != "" and not dialogue.has(nid):
				errors.append("Dialogue %s choice points to missing %s" % [did, nid])
	for cid in crops:
		var c: Dictionary = crops[cid]
		if not items.has(str(c.get("seed_item_id", ""))):
			errors.append("Crop %s missing seed" % cid)
		if not items.has(str(c.get("harvest_item_id", ""))):
			errors.append("Crop %s missing harvest item" % cid)
