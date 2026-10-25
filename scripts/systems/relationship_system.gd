class_name RelationshipSystem
extends RefCounted

signal relationship_changed(npc_id: String)

var world: WorldState
var calendar: CalendarSystem

func bind(p_world: WorldState, p_cal: CalendarSystem) -> void:
	world = p_world
	calendar = p_cal

func talk(npc_id: String) -> CommandResult:
	var ns: NpcState = world.npcs.get(npc_id)
	if ns == null:
		return CommandResult.fail("invalid_target")
	var rel_day := CalendarSystem.religious_ordinal(world.absolute_minutes)
	var gained := 0
	if ns.last_talk_religious_day != rel_day:
		if ns.friendship < 100:
			ns.friendship = mini(100, ns.friendship + 1)
			gained = 1
		ns.last_talk_religious_day = rel_day
		relationship_changed.emit(npc_id)
		world.bump_revision()
	return CommandResult.success([{"kind": "talked", "npc_id": npc_id, "friendship_gained": gained, "friendship": ns.friendship}], {"friendship": ns.friendship, "gained": gained})
