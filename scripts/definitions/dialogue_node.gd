class_name DialogueNode
extends Resource

@export var id: String = ""
@export var speaker_id: String = ""
@export var text_key: String = ""
@export var choices: Array = []  # [{text_key, next_id, effects}]
@export var next_id: String = ""
@export var mode_filter: String = "any"  # any | everyday | biblical
@export var flag_conditions: Dictionary = {}
