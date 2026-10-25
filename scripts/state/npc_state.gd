class_name NpcState
extends RefCounted

var id: String = ""
var position: Vector2 = Vector2.ZERO
var anchor_id: String = "home"
var friendship: int = 0
var last_talk_religious_day: int = -1

func clone() -> NpcState:
	var c := NpcState.new()
	c.id = id
	c.position = position
	c.anchor_id = anchor_id
	c.friendship = friendship
	c.last_talk_religious_day = last_talk_religious_day
	return c
