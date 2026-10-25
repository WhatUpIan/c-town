extends Node

## Composition root: WorldState, systems, command processor, persistence.

signal inventory_changed(actor_id: String)
signal clock_changed
signal day_started(index: int)
signal quest_changed(id: String)
signal relationship_changed(npc_id: String)
signal save_finished(result: Dictionary)
signal notification(text: String)
signal mode_changed(playing: bool)
signal ui_feedback(reason_code: String)

var content: ContentDB = ContentDB.new()
var world: WorldState
var calendar: CalendarSystem = CalendarSystem.new()
var inventory: InventorySystem = InventorySystem.new()
var crops: CropSystem = CropSystem.new()
var economy: EconomySystem = EconomySystem.new()
var fishing: FishingSystem = FishingSystem.new()
var quests: QuestSystem = QuestSystem.new()
var relationships: RelationshipSystem = RelationshipSystem.new()
var npc_schedules: NpcScheduleSystem = NpcScheduleSystem.new()
var commands: CommandProcessor = CommandProcessor.new()
var saves: SaveService = SaveService.new()

var local_player_id: String = "player.local"
var simulation_paused: bool = true  # paused on title
var modal_pause: bool = false
var bypass_range_checks: bool = false  # tests
var settings: Dictionary = {
	"font_scale": 1.0,
	"master_volume": 1.0,
	"reduced_motion": false,
}
var dirty: bool = false
var _time_accum: float = 0.0
var _settings_path: String = "user://settings.json"

func _ready() -> void:
	if not content.load_all():
		push_error("ContentDB validation failed: %s" % str(content.errors))
	inventory.bind(content)
	saves.bind(content)
	commands.bind(self)
	quests.quest_changed.connect(func(id): quest_changed.emit(id))
	relationships.relationship_changed.connect(func(id): relationship_changed.emit(id))
	calendar.clock_changed.connect(func(): clock_changed.emit())
	calendar.day_started.connect(func(i): day_started.emit(i))
	calendar.notification.connect(func(k): notification.emit(content.tr_key(k)))
	saves.save_finished.connect(func(r): save_finished.emit(r))
	_load_settings()

func _process(delta: float) -> void:
	if world == null:
		return
	if simulation_paused or modal_pause:
		return
	# 1 real second = 1 game minute
	_time_accum += delta
	while _time_accum >= 1.0:
		_time_accum -= 1.0
		var cmd := GameCommand.make("advance_time", local_player_id, "", {"minutes": 1})
		cmd.session_id = world.session_id
		execute(cmd)

func start_new_game(story_mode: String = "everyday", rng_seed: int = 12345) -> void:
	world = WorldFactory.new_game(content, story_mode, rng_seed)
	_bind_world()
	npc_schedules.refresh_destinations()
	simulation_paused = false
	modal_pause = false
	dirty = true
	mode_changed.emit(true)
	clock_changed.emit()

func continue_game() -> Dictionary:
	var res := saves.load_preferred()
	if not bool(res.get("ok", false)):
		return res
	apply_loaded_world(res["world"])
	return res

func apply_loaded_world(w: WorldState) -> void:
	world = w
	_bind_world()
	npc_schedules.refresh_destinations()
	simulation_paused = false
	modal_pause = false
	dirty = false
	mode_changed.emit(true)
	clock_changed.emit()
	inventory_changed.emit(local_player_id)

func _bind_world() -> void:
	calendar.bind(world, content)
	crops.bind(world, content, inventory, calendar)
	economy.bind(world, content, inventory, calendar)
	fishing.bind(world, content, inventory)
	quests.bind(world, content, inventory)
	relationships.bind(world, calendar)
	npc_schedules.bind(world, calendar)
	npc_schedules.setup_default_village()

func return_to_title() -> void:
	simulation_paused = true
	modal_pause = false
	world = null
	mode_changed.emit(false)

func execute(cmd: GameCommand) -> CommandResult:
	if world == null:
		return CommandResult.fail("blocked")
	var result: CommandResult = commands.execute(cmd)
	if result.ok:
		dirty = true
		match cmd.kind:
			"buy", "sell", "harvest_plot", "plant_plot", "fish", "complete_quest":
				inventory_changed.emit(cmd.actor_id)
			"hoe_plot", "water_plot", "interact":
				inventory_changed.emit(cmd.actor_id)
			"talk":
				pass
		if result.reason_code != "ok":
			pass
	else:
		ui_feedback.emit(result.reason_code)
	return result

func clock_changed_notify() -> void:
	clock_changed.emit()

func request_autosave(reason: String = "") -> void:
	if world == null:
		return
	var r := saves.save_world(world)
	if bool(r.get("ok", false)):
		dirty = false
	notification.emit("Saved (%s)." % reason if reason != "" else "Saved.")

func manual_save() -> Dictionary:
	if world == null:
		return {"ok": false, "reason": "blocked"}
	var r := saves.save_world(world)
	if bool(r.get("ok", false)):
		dirty = false
	return r

func set_modal_pause(active: bool) -> void:
	# Single-player policy: modal panels pause simulation
	modal_pause = active

func has_continue() -> bool:
	return saves.has_valid_save()

func tr_reason(code: String) -> String:
	return content.tr_key("reason." + code) if content.localization.has("reason." + code) else code

func _load_settings() -> void:
	if not FileAccess.file_exists(_settings_path):
		return
	var f := FileAccess.open(_settings_path, FileAccess.READ)
	if f == null:
		return
	var parsed = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(parsed) == TYPE_DICTIONARY:
		for k in parsed:
			settings[k] = parsed[k]

func save_settings() -> void:
	var f := FileAccess.open(_settings_path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(settings, "\t"))
		f.close()
