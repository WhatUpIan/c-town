class_name CommandResult
extends RefCounted

var ok: bool = false
var reason_code: String = ""
var events: Array = []  # Array of Dictionary event records
var data: Dictionary = {}

static func success(events: Array = [], data: Dictionary = {}) -> CommandResult:
	var r := CommandResult.new()
	r.ok = true
	r.reason_code = "ok"
	r.events = events.duplicate(true)
	r.data = data.duplicate(true)
	return r

static func fail(reason_code: String, data: Dictionary = {}) -> CommandResult:
	var r := CommandResult.new()
	r.ok = false
	r.reason_code = reason_code
	r.data = data.duplicate(true)
	return r

func to_dict() -> Dictionary:
	return {"ok": ok, "reason_code": reason_code, "events": events.duplicate(true), "data": data.duplicate(true)}
