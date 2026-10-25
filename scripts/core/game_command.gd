class_name GameCommand
extends RefCounted

var command_id: String = ""
var session_id: String = ""
var actor_id: String = "player.local"
var kind: String = ""
var target_id: String = ""
var payload: Dictionary = {}

static func make(kind: String, actor_id: String = "player.local", target_id: String = "", payload: Dictionary = {}, command_id: String = "") -> GameCommand:
	var c := GameCommand.new()
	c.kind = kind
	c.actor_id = actor_id
	c.target_id = target_id
	c.payload = payload.duplicate(true)
	c.command_id = command_id if command_id != "" else "%s_%d_%d" % [kind, Time.get_ticks_msec(), randi()]
	return c
