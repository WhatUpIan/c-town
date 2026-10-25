class_name QuestState
extends RefCounted

var id: String = ""
## unavailable | available | active | completed
var status: String = "unavailable"
var reward_claimed: bool = false

func clone() -> QuestState:
	var c := QuestState.new()
	c.id = id
	c.status = status
	c.reward_claimed = reward_claimed
	return c
