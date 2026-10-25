class_name CalendarEventDef
extends Resource

@export var id: String = ""
@export var date_rule: String = ""  # e.g. nisan_15
@export var duration_days: int = 1
@export var schedule_overrides: Dictionary = {}
@export var review_status: String = "provisional"
