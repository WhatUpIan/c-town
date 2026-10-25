class_name PlotState
extends RefCounted

var id: String = ""
var cell: Vector2i = Vector2i.ZERO
var tilled: bool = false
var crop_id: String = ""
var growth_days: int = 0
var watered_for_day: bool = false
var last_processed_dawn: int = 0

func clone() -> PlotState:
	var c := PlotState.new()
	c.id = id
	c.cell = cell
	c.tilled = tilled
	c.crop_id = crop_id
	c.growth_days = growth_days
	c.watered_for_day = watered_for_day
	c.last_processed_dawn = last_processed_dawn
	return c
