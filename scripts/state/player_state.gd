class_name PlayerState
extends RefCounted

var id: String = "player.local"
var map_id: String = "village"
var position: Vector2 = Vector2(320, 160)
var facing: String = "down"
var inventory: InventoryState = InventoryState.new()
var wallet: int = 20
var selected_tool: String = "hand"
var tools: Array[String] = ["hand", "hoe", "watering_jug", "fishing_net"]

func clone() -> PlayerState:
	var c := PlayerState.new()
	c.id = id
	c.map_id = map_id
	c.position = position
	c.facing = facing
	c.inventory = inventory.clone()
	c.wallet = wallet
	c.selected_tool = selected_tool
	c.tools = tools.duplicate()
	return c
