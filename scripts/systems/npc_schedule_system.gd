class_name NpcScheduleSystem
extends RefCounted

## Named anchors and simple schedule destinations. Uses logical cells + projection.

var world: WorldState
var calendar: CalendarSystem

## anchor_id -> Vector2 world position
var anchors: Dictionary = {}
## walkable cell set for simple BFS
var walkable: Dictionary = {}

func bind(p_world: WorldState, p_cal: CalendarSystem) -> void:
	world = p_world
	calendar = p_cal

func setup_default_village() -> void:
	anchors = {
		"home_miriam": Vector2(200, 180),
		"home_yehudah": Vector2(420, 200),
		"home_hannah": Vector2(360, 140),
		"work_garden": Vector2(240, 200),
		"work_shore": IsoMath.cell_to_screen(Vector2i(15, 7)) + Vector2(400, 60),
		"work_stall": Vector2(340, 120),
		"courtyard": Vector2(300, 160),
	}
	# Logical walkability: rough rectangle of cells
	walkable.clear()
	for x in range(0, 24):
		for y in range(0, 18):
			walkable[Vector2i(x, y)] = true
	# Water edge blocked (right side)
	for y in range(0, 18):
		for x in range(20, 24):
			walkable.erase(Vector2i(x, y))

func current_anchor_for(npc_id: String, abs_min: int = -1) -> String:
	var a := world.absolute_minutes if abs_min < 0 else abs_min
	var m := CalendarSystem.minute_of_day(a)
	var sab := CalendarSystem.is_sabbath(a)
	var def: String = "courtyard"
	match npc_id:
		"npc.merchant_01":
			if sab:
				if m < 480:
					return "home_miriam"
				if m < 1080:
					return "courtyard"
				return "home_miriam"
			if m < 480:
				return "home_miriam"
			if m < 720:
				return "work_garden"
			if m < 840:
				return "courtyard"
			if m < 1080:
				return "work_garden"
			return "home_miriam"
		"npc.fisher_01":
			if sab:
				if m < 480:
					return "home_yehudah"
				if m < 1080:
					return "courtyard"
				return "home_yehudah"
			if m < 480:
				return "home_yehudah"
			if m < 720:
				return "work_shore"
			if m < 840:
				return "courtyard"
			if m < 1080:
				return "work_shore"
			return "home_yehudah"
		"npc.stall_01":
			if sab:
				if m < 480:
					return "home_hannah"
				if m < 1080:
					return "courtyard"
				return "home_hannah"
			if m < 480:
				return "home_hannah"
			if m < 720:
				return "work_stall"
			if m < 840:
				return "courtyard"
			if m < 1080:
				return "work_stall"
			return "home_hannah"
	return def

func refresh_destinations() -> void:
	for nid in world.npcs:
		var ns: NpcState = world.npcs[nid]
		var anchor := current_anchor_for(nid)
		ns.anchor_id = anchor
		if anchors.has(anchor):
			ns.position = anchors[anchor]

func path_to_anchor(from_pos: Vector2, anchor_id: String) -> PackedVector2Array:
	var path := PackedVector2Array()
	if not anchors.has(anchor_id):
		return path
	path.append(from_pos)
	path.append(anchors[anchor_id])
	return path
