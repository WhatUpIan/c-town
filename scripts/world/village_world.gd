extends Node2D

@onready var ysort: Node2D = $YSort
@onready var ground_layer: TileMapLayer = $GroundLayer
@onready var player: CharacterBody2D = $YSort/Player
@onready var interact_prompt: Label = $UILayer/InteractPrompt

var _interactables: Array = []
var _current_target: Node = null
const INTERACT_RANGE_PX := 64.0
const MAP_ORIGIN := Vector2(400, 60)

func _ready() -> void:
	_build_tilemap_ground()
	_spawn_props()
	_spawn_villagers()
	if player and player.has_method("sync_from_state"):
		player.sync_from_state()
	_refresh_interactables()

func _build_tilemap_ground() -> void:
	ground_layer.position = MAP_ORIGIN
	ground_layer.tile_set = GroundBuilder.build_tileset()
	GroundBuilder.fill_village(ground_layer)
	GroundBuilder.add_water_collision(self, ground_layer)

func _cell_world(cell: Vector2i) -> Vector2:
	return GroundBuilder.cell_world_pos(ground_layer, cell)

func _spawn_props() -> void:
	_add_building(Vector2(220, 150), "res://assets/placeholders/house_basalt.png", "Home")
	_add_building(Vector2(300, 100), "res://assets/placeholders/synagogue_modest.png", "Synagogue")
	_add_interactable(Vector2(250, 200), "interact.bed", "Sleep", "res://assets/placeholders/prop_bed.png")
	_add_interactable(Vector2(340, 120), "interact.stall", "Stall", "res://assets/placeholders/prop_stall.png")
	# Walkable shoreline (cell x=17 is last non-water column)
	_add_interactable(_cell_world(Vector2i(17, 8)), "interact.fishing", "Fish", "res://assets/placeholders/prop_fishing.png")
	# Plots
	for i in range(6):
		var pid := "plot.home_%02d" % (i + 1)
		var cell := Vector2i(6 + (i % 3), 8 + int(i / 3))
		_add_plot(_cell_world(cell), pid)

func _add_building(pos: Vector2, tex_path: String, label_text: String) -> void:
	var n := Node2D.new()
	n.position = pos
	n.z_index = int(pos.y)
	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.centered = true
	spr.offset = Vector2(0, -30)
	n.add_child(spr)
	var lab := Label.new()
	lab.text = label_text
	lab.position = Vector2(-30, -70)
	lab.add_theme_font_size_override("font_size", 12)
	n.add_child(lab)
	# Static footprint
	var body := StaticBody2D.new()
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(50, 24)
	cs.shape = shape
	cs.position = Vector2(0, 10)
	body.add_child(cs)
	n.add_child(body)
	ysort.add_child(n)

func _add_interactable(pos: Vector2, sid: String, prompt: String, tex_path: String) -> void:
	var area := Area2D.new()
	area.set_script(load("res://scripts/interaction/interactable.gd"))
	area.position = pos
	area.stable_id = sid
	area.prompt = prompt
	area.collision_layer = 4
	area.collision_mask = 0
	var spr := Sprite2D.new()
	spr.texture = load(tex_path)
	spr.centered = true
	spr.offset = Vector2(0, -12)
	area.add_child(spr)
	var lab := Label.new()
	lab.text = prompt
	lab.position = Vector2(-20, -36)
	lab.add_theme_font_size_override("font_size", 11)
	area.add_child(lab)
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16
	cs.shape = shape
	area.add_child(cs)
	area.add_to_group("interactables")
	ysort.add_child(area)

func _add_plot(pos: Vector2, pid: String) -> void:
	var area := Area2D.new()
	area.set_script(load("res://scripts/interaction/interactable.gd"))
	area.position = pos
	area.stable_id = pid
	area.prompt = "Plot"
	area.collision_layer = 4
	var spr := Sprite2D.new()
	spr.name = "CropSprite"
	spr.texture = load("res://assets/placeholders/crop_empty.png")
	spr.centered = true
	area.add_child(spr)
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 14
	cs.shape = shape
	area.add_child(cs)
	area.add_to_group("interactables")
	area.add_to_group("plots")
	ysort.add_child(area)

func _spawn_villagers() -> void:
	var specs := [
		{"id": "npc.merchant_01", "name": "Miriam", "tex": "res://assets/placeholders/npc_miriam.png", "pos": Vector2(200, 180)},
		{"id": "npc.fisher_01", "name": "Yehudah", "tex": "res://assets/placeholders/npc_yehudah.png", "pos": Vector2(420, 200)},
		{"id": "npc.stall_01", "name": "Hannah", "tex": "res://assets/placeholders/npc_hannah.png", "pos": Vector2(360, 140)},
	]
	var scene_script := load("res://scripts/actors/villager_controller.gd")
	for s in specs:
		var v := CharacterBody2D.new()
		v.set_script(scene_script)
		v.npc_id = s["id"]
		v.display_name = s["name"]
		v.stable_id = s["id"]
		v.position = s["pos"]
		v.collision_layer = 2
		v.collision_mask = 1
		var spr := Sprite2D.new()
		spr.name = "Sprite2D"
		spr.texture = load(s["tex"])
		spr.centered = true
		spr.offset = Vector2(0, -24)
		v.add_child(spr)
		var lab := Label.new()
		lab.name = "Label"
		lab.text = s["name"]
		lab.position = Vector2(-24, -52)
		lab.add_theme_font_size_override("font_size", 12)
		v.add_child(lab)
		var cs := CollisionShape2D.new()
		var shape := CircleShape2D.new()
		shape.radius = 8
		cs.shape = shape
		cs.position = Vector2(0, 0)
		v.add_child(cs)
		# Soft: actors don't hard-block each other permanently
		v.collision_mask = 1
		ysort.add_child(v)
		if GameSession.world and GameSession.world.npcs.has(s["id"]):
			GameSession.world.npcs[s["id"]].position = s["pos"]

func _refresh_interactables() -> void:
	_interactables = get_tree().get_nodes_in_group("interactables")

func _process(_delta: float) -> void:
	if GameSession.world == null:
		return
	_update_plot_visuals()
	_update_targeting()
	_handle_actions()

func _update_plot_visuals() -> void:
	for n in get_tree().get_nodes_in_group("plots"):
		var sid: String = n.stable_id if "stable_id" in n else ""
		var plot: PlotState = GameSession.world.plots.get(sid)
		if plot == null:
			continue
		var spr: Sprite2D = n.get_node_or_null("CropSprite")
		if spr == null:
			continue
		if plot.crop_id == "":
			spr.texture = load("res://assets/placeholders/crop_empty.png" if not plot.tilled else "res://assets/placeholders/crop_sown.png")
			if plot.tilled and plot.crop_id == "":
				spr.texture = load("res://assets/placeholders/crop_sown.png")
				# empty tilled looks like soil sown-ready; use empty outline
				spr.texture = load("res://assets/placeholders/crop_empty.png")
		elif plot.growth_days <= 0:
			spr.texture = load("res://assets/placeholders/crop_sown.png")
		elif plot.growth_days < 3:
			spr.texture = load("res://assets/placeholders/crop_growing.png")
		else:
			spr.texture = load("res://assets/placeholders/crop_ripe.png")

func _main_ui() -> Node:
	# Village lives under Main/VillageHost; UI is Main/UI — never parent.get_node("UI").
	var host := get_parent()
	if host:
		var main := host.get_parent()
		if main:
			var ui := main.get_node_or_null("UI")
			if ui:
				return ui
	return get_tree().get_first_node_in_group("main_ui")

func _update_targeting() -> void:
	_refresh_interactables()
	# Prefer activity markers (fish/bed/stall/plots) over NPCs when nearly equidistant
	var activities: Array = []
	var people: Array = []
	for n in _interactables:
		if n == null:
			continue
		var sid := ""
		if n.has_method("get_stable_id"):
			sid = str(n.call("get_stable_id"))
		if sid.begins_with("npc."):
			people.append(n)
		else:
			activities.append(n)
	_current_target = Targeting.pick_nearest(player.global_position, activities, INTERACT_RANGE_PX)
	if _current_target == null:
		_current_target = Targeting.pick_nearest(player.global_position, people, INTERACT_RANGE_PX)
	if _current_target and interact_prompt:
		var prompt := "E: Interact"
		if _current_target.has_method("get_prompt"):
			prompt = "E: " + str(_current_target.call("get_prompt"))
		interact_prompt.text = prompt
		interact_prompt.visible = true
	elif interact_prompt:
		interact_prompt.visible = false

func _handle_actions() -> void:
	if GameSession.modal_pause or GameSession.simulation_paused:
		return
	if Input.is_action_just_pressed("cycle_tool"):
		GameSession.execute(GameCommand.make("cycle_tool"))
	if Input.is_action_just_pressed("interact") and _current_target:
		var sid := ""
		if _current_target.has_method("get_stable_id"):
			sid = str(_current_target.call("get_stable_id"))
		_do_interact(sid)
	if Input.is_action_just_pressed("primary_action") and _current_target:
		var sid2 := ""
		if _current_target.has_method("get_stable_id"):
			sid2 = str(_current_target.call("get_stable_id"))
		if sid2.begins_with("plot.") or sid2 == "interact.fishing":
			_do_interact(sid2)

func _do_interact(sid: String) -> void:
	if sid == "":
		return
	if sid == "interact.fishing":
		var ui_fish := _main_ui()
		if ui_fish and ui_fish.has_method("open_fishing"):
			ui_fish.open_fishing()
		else:
			GameSession.notification.emit("Fishing UI unavailable.")
		return
	if sid == "interact.stall":
		var ui := _main_ui()
		if ui and ui.has_method("open_stall"):
			ui.open_stall()
		else:
			GameSession.notification.emit("Stall UI unavailable.")
		return
	if sid.begins_with("npc."):
		var ui2 := _main_ui()
		if ui2 and ui2.has_method("open_dialogue"):
			ui2.open_dialogue(sid)
		else:
			GameSession.notification.emit("Dialogue UI unavailable.")
		GameSession.execute(GameCommand.make("talk", "player.local", sid))
		return
	if sid == "interact.bed":
		var res2: CommandResult = GameSession.execute(GameCommand.make("sleep"))
		if not res2.ok:
			GameSession.notification.emit(GameSession.tr_reason(res2.reason_code))
		return
	if sid.begins_with("plot."):
		var player_state := GameSession.world.local_player()
		var tool := player_state.selected_tool
		var kind := "interact"
		match tool:
			"hoe":
				kind = "hoe_plot"
			"watering_jug":
				kind = "water_plot"
			"hand":
				var plot: PlotState = GameSession.world.plots.get(sid)
				if plot and plot.crop_id != "" and plot.growth_days >= 3:
					kind = "harvest_plot"
				elif plot and plot.tilled and plot.crop_id == "":
					kind = "plant_plot"
				elif plot and not plot.tilled:
					kind = "hoe_plot"
				else:
					kind = "water_plot" if plot and plot.crop_id != "" else "interact"
		var res3: CommandResult = GameSession.execute(GameCommand.make(kind, "player.local", sid))
		if not res3.ok:
			GameSession.notification.emit(GameSession.tr_reason(res3.reason_code))
