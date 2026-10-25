class_name CalendarSystem
extends RefCounted

## Clock, civil/religious day, dawn index, Sabbath, lunar labels.
## absolute_minutes starts at 360 (civil day 0 @ 06:00).

signal clock_changed
signal day_started(civil_day: int)
signal sabbath_changed(active: bool)
signal notification(text_key: String)
signal festival_notice(event_id: String)

const MINUTES_PER_DAY := 1440
const DAWN_MINUTE := 360   # 06:00
const SUNSET_MINUTE := 1080  # 18:00
const REST_REMINDER := 120  # 02:00
const SABBATH_WARN_MINUTE := 960  # 16:00

var world: WorldState
var content: ContentDB

func bind(p_world: WorldState, p_content: ContentDB) -> void:
	world = p_world
	content = p_content

static func civil_day(abs_min: int) -> int:
	return _floor_div(abs_min, MINUTES_PER_DAY)

static func religious_ordinal(abs_min: int) -> int:
	# Changes at 18:00: floor((abs + 360) / 1440); ordinal 0 = weekday 1
	return _floor_div(abs_min + 360, MINUTES_PER_DAY)

static func weekday(abs_min: int) -> int:
	# 1..7 with 7 = Sabbath
	var ord := religious_ordinal(abs_min)
	return (ord % 7) + 1

static func is_sabbath(abs_min: int) -> bool:
	return weekday(abs_min) == 7

static func dawn_index(abs_min: int) -> int:
	return _floor_div(abs_min - DAWN_MINUTE, MINUTES_PER_DAY)

static func minute_of_day(abs_min: int) -> int:
	var m := abs_min % MINUTES_PER_DAY
	if m < 0:
		m += MINUTES_PER_DAY
	return m

static func format_civil_time(abs_min: int) -> String:
	var m := minute_of_day(abs_min)
	return "%02d:%02d" % [m / 60, m % 60]

static func _floor_div(a: int, b: int) -> int:
	# Mathematical floor division
	var q := a / b
	var r := a % b
	if r != 0 and ((a < 0) != (b < 0)):
		q -= 1
	return q

## Simplified game calendar: ordinal 0 = Nisan 1; months alternate 30/29.
## Label as simplified — not historical reconstruction.
static func lunar_label(religious_ord: int) -> String:
	var month_lengths := [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29]
	var month_names := ["Nisan", "Iyar", "Sivan", "Tammuz", "Av", "Elul", "Tishrei", "Cheshvan", "Kislev", "Tevet", "Shevat", "Adar"]
	var day_index := religious_ord  # 0-based day within year cycle
	if day_index < 0:
		day_index = 0
	var year_len := 0
	for L in month_lengths:
		year_len += L
	day_index = day_index % year_len
	var remaining := day_index
	for i in month_lengths.size():
		if remaining < month_lengths[i]:
			return "%s %d (simplified game calendar)" % [month_names[i], remaining + 1]
		remaining -= month_lengths[i]
	return "Nisan 1 (simplified game calendar)"

static func is_nisan_15(religious_ord: int) -> bool:
	# Nisan has 30 days; day 15 is ordinal 14 within year if year starts Nisan 1
	var month_lengths := [30, 29, 30, 29, 30, 29, 30, 29, 30, 29, 30, 29]
	var year_len := 0
	for L in month_lengths:
		year_len += L
	var day_index := religious_ord % year_len
	if day_index < 0:
		day_index += year_len
	return day_index == 14  # Nisan 15

func weekday_name(abs_min: int = -1) -> String:
	var a := world.absolute_minutes if abs_min < 0 else abs_min
	var names := ["", "Weekday 1", "Weekday 2", "Weekday 3", "Weekday 4", "Weekday 5", "Weekday 6", "Sabbath"]
	return names[weekday(a)]

## Advance simulation time; enumerate crossed boundaries chronologically once.
func advance_minutes(delta: int) -> Array:
	var events: Array = []
	if delta == 0 or world == null:
		return events
	if delta < 0:
		push_warning("advance_minutes ignored negative delta")
		return events
	var start: int = world.absolute_minutes
	var end: int = start + delta
	# Collect boundary minutes in (start, end]
	var boundaries: Array[Dictionary] = []
	_collect_boundaries(start, end, boundaries)
	boundaries.sort_custom(func(a, b): return int(a["minute"]) < int(b["minute"]))
	var cursor := start
	for b in boundaries:
		var at: int = int(b["minute"])
		if at < cursor:
			continue
		# Allow multiple boundary kinds at the same minute (e.g. sunset + schedule_18)
		if at > cursor:
			cursor = at
		world.absolute_minutes = at
		var ev := _fire_boundary(str(b["kind"]), at)
		if not ev.is_empty():
			events.append(ev)
	world.absolute_minutes = end
	world.bump_revision()
	clock_changed.emit()
	return events

func _collect_boundaries(start: int, end: int, out: Array[Dictionary]) -> void:
	# Scan each civil day range that intersects (start, end]
	var day0 := civil_day(start)
	var day1 := civil_day(end) + 1
	for d in range(day0, day1 + 1):
		for kind_min in [
			["dawn", d * MINUTES_PER_DAY + DAWN_MINUTE],
			["sunset", d * MINUTES_PER_DAY + SUNSET_MINUTE],
			["rest_reminder", d * MINUTES_PER_DAY + REST_REMINDER],
			["sabbath_warn", d * MINUTES_PER_DAY + SABBATH_WARN_MINUTE],
			["schedule_06", d * MINUTES_PER_DAY + 360],
			["schedule_08", d * MINUTES_PER_DAY + 480],
			["schedule_12", d * MINUTES_PER_DAY + 720],
			["schedule_14", d * MINUTES_PER_DAY + 840],
			["schedule_18", d * MINUTES_PER_DAY + 1080],
			["civil_midnight", (d + 1) * MINUTES_PER_DAY],
		]:
			var kind: String = kind_min[0]
			var m: int = int(kind_min[1])
			if m > start and m <= end:
				out.append({"kind": kind, "minute": m})

func _fire_boundary(kind: String, at: int) -> Dictionary:
	var key := "%s@%d" % [kind, at]
	match kind:
		"dawn":
			var di := dawn_index(at)
			day_started.emit(civil_day(at))
			return {"kind": "dawn", "dawn_index": di, "absolute_minutes": at, "key": key}
		"sunset":
			var became_sabbath := is_sabbath(at)
			var was_sabbath := is_sabbath(at - 1)
			var primary: Dictionary = {"kind": "sunset", "absolute_minutes": at, "key": key}
			if became_sabbath and not was_sabbath:
				_mark_event("sabbath_begin@%d" % religious_ordinal(at))
				notification.emit("notify.sabbath_begin")
				sabbath_changed.emit(true)
				primary = {"kind": "sabbath_begin", "absolute_minutes": at, "key": "sabbath_begin@%d" % religious_ordinal(at)}
			elif was_sabbath and not became_sabbath:
				_mark_event("sabbath_end@%d" % religious_ordinal(at - 1))
				notification.emit("notify.sabbath_end")
				sabbath_changed.emit(false)
				primary = {"kind": "sabbath_end", "absolute_minutes": at, "key": "sabbath_end@%d" % religious_ordinal(at - 1)}
			# Passover notice at start of Nisan 15 (may share the sunset with Sabbath end)
			if is_nisan_15(religious_ordinal(at)):
				var ek := "evt.passover_notice@%d" % religious_ordinal(at)
				if _mark_event(ek):
					festival_notice.emit("evt.passover_notice")
					notification.emit("dlg.passover.notice")
					primary = {"kind": "festival", "event_id": "evt.passover_notice", "key": ek, "also": primary.get("kind", "sunset")}
			return primary
		"rest_reminder":
			notification.emit("notify.rest_reminder")
			return {"kind": "rest_reminder", "absolute_minutes": at}
		"sabbath_warn":
			# 16:00 on weekday 6 (day before Sabbath)
			if weekday(at) == 6:
				notification.emit("notify.sabbath_approach")
				return {"kind": "sabbath_warn", "absolute_minutes": at}
			return {}
		"civil_midnight":
			return {"kind": "civil_midnight", "civil_day": civil_day(at), "absolute_minutes": at}
		_:
			if kind.begins_with("schedule_"):
				return {"kind": "schedule", "boundary": kind, "absolute_minutes": at}
	return {}

func _mark_event(key: String) -> bool:
	if key in world.processed_events:
		return false
	world.processed_events.append(key)
	return true

func stall_open(abs_min: int = -1) -> bool:
	var a := world.absolute_minutes if abs_min < 0 else abs_min
	if is_sabbath(a):
		return false
	var m := minute_of_day(a)
	return m >= 480 and m < 1080  # 08:00–18:00

func bed_usable(abs_min: int = -1) -> bool:
	var a := world.absolute_minutes if abs_min < 0 else abs_min
	var m := minute_of_day(a)
	return m >= SUNSET_MINUTE or m < DAWN_MINUTE

func minutes_until_next_dawn(abs_min: int = -1) -> int:
	var a := world.absolute_minutes if abs_min < 0 else abs_min
	var m := minute_of_day(a)
	if m < DAWN_MINUTE:
		return DAWN_MINUTE - m
	return MINUTES_PER_DAY - m + DAWN_MINUTE
