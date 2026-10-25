extends CanvasLayer

@onready var title: Control = $TitleScreen
@onready var pause_menu: Control = $PauseMenu
@onready var settings: Control = $SettingsPanel
@onready var inventory: Control = $InventoryPanel
@onready var journal: Control = $JournalPanel
@onready var dialogue: Control = $DialoguePanel
@onready var stall: Control = $StallPanel
@onready var fishing: Control = $FishingMinigame
@onready var hud: CanvasLayer = $HUD
@onready var village_host: Node = get_parent().get_node_or_null("VillageHost")

var _village: Node = null

func _ready() -> void:
	add_to_group("main_ui")
	hud.visible = false
	title.start_everyday.connect(func(): _begin_game("everyday"))
	title.start_biblical.connect(func(): _begin_game("biblical"))
	title.continue_pressed.connect(_continue)
	title.open_settings.connect(func(): settings.open_panel())
	title.quit_pressed.connect(func(): get_tree().quit())
	pause_menu.resume.connect(func(): pause_menu.close_menu())
	pause_menu.save_pressed.connect(func():
		var r := GameSession.manual_save()
		GameSession.notification.emit("Saved." if bool(r.get("ok", false)) else "Save failed: %s" % r.get("reason", ""))
	)
	pause_menu.settings_pressed.connect(func(): settings.open_panel())
	pause_menu.title_pressed.connect(_to_title)
	dialogue.open_stall_requested.connect(open_stall)
	fishing.finished.connect(_on_fishing_finished)
	GameSession.mode_changed.connect(_on_mode)

func _on_mode(playing: bool) -> void:
	title.visible = not playing
	hud.visible = playing

func _begin_game(mode: String) -> void:
	GameSession.start_new_game(mode)
	_load_village()
	title.visible = false
	hud.visible = true

func _continue() -> void:
	var res := GameSession.continue_game()
	if not bool(res.get("ok", false)):
		GameSession.notification.emit(str(res.get("reason", "save_invalid")))
		if bool(res.get("main_damaged", false)):
			GameSession.notification.emit("Main save damaged; loaded backup.")
		return
	if str(res.get("source", "")) == "backup":
		GameSession.notification.emit("Loaded backup save (main was damaged).")
	_load_village()
	title.visible = false
	hud.visible = true

func _load_village() -> void:
	if _village and is_instance_valid(_village):
		var old: Node = _village
		_village = null
		# Free immediately so stale interactables leave the group before the new village scans
		old.free()
	var packed := load("res://scenes/world/village.tscn")
	_village = packed.instantiate()
	if village_host:
		village_host.add_child(_village)
	else:
		get_parent().add_child(_village)

func _to_title() -> void:
	pause_menu.close_menu()
	if _village and is_instance_valid(_village):
		var old: Node = _village
		_village = null
		old.free()
	GameSession.return_to_title()
	title.visible = true
	hud.visible = false
	title._refresh()

func _unhandled_input(event: InputEvent) -> void:
	if not hud.visible:
		return
	if event.is_action_pressed("pause"):
		if dialogue.visible or stall.visible or inventory.visible or journal.visible or settings.visible or fishing.visible:
			return
		if pause_menu.visible:
			pause_menu.close_menu()
		else:
			pause_menu.open_menu()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if fishing.visible:
			return
		if inventory.visible:
			inventory.close()
		else:
			inventory.open_panel()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		if fishing.visible:
			return
		if journal.visible:
			journal.close()
		else:
			journal.open_panel()
		get_viewport().set_input_as_handled()

func open_dialogue(npc_id: String) -> void:
	dialogue.open_for(npc_id)

func open_stall() -> void:
	stall.open_panel()

func open_fishing() -> void:
	fishing.open_minigame()

func _on_fishing_finished(success: bool, canceled: bool) -> void:
	if canceled:
		var cancel_cmd := GameCommand.make("fish", "player.local", "interact.fishing", {"cancel": true})
		GameSession.execute(cancel_cmd)
		GameSession.notification.emit("You lower the net.")
		return
	var cmd := GameCommand.make("fish", "player.local", "interact.fishing", {"success": success})
	var res: CommandResult = GameSession.execute(cmd)
	if res.ok:
		GameSession.notification.emit("Caught a lake fish.")
	else:
		GameSession.notification.emit(GameSession.tr_reason(res.reason_code))
