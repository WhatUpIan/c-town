class_name QuestDef
extends Resource

@export var id: String = ""
@export var giver_id: String = ""
@export var requirements: Dictionary = {}  # item_id -> qty
@export var reward: Dictionary = {}  # money, friendship_npc, friendship_delta
@export var prerequisites: Array[String] = []
@export var story_mode_filter: String = "any"
