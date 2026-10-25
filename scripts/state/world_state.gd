class_name WorldState
extends RefCounted

const SCHEMA_VERSION := 1
const GAME_VERSION := "0.1.0"
const ERA_ID := "galilee_village"
const CALENDAR_ID := "prototype_lunar_v1"
const ECONOMIC_CACHE_SIZE := 256

var schema_version: int = SCHEMA_VERSION
var game_version: String = GAME_VERSION
var world_revision: int = 0
var era_id: String = ERA_ID
var calendar_id: String = CALENDAR_ID
var story_mode: String = "everyday"  # everyday | biblical
var session_id: String = "session.local"
var absolute_minutes: int = 360  # civil day 0 at 06:00
var rng: RngState = RngState.new()
var players: Dictionary = {}  # id -> PlayerState
var plots: Dictionary = {}  # id -> PlotState
var npcs: Dictionary = {}  # id -> NpcState
var quests: Dictionary = {}  # id -> QuestState
var flags: Dictionary = {}
var processed_events: Array[String] = []
## command_id -> {ok, reason_code, summary}
var recent_economic_commands: Dictionary = {}
var _economic_order: Array[String] = []

func local_player() -> PlayerState:
	return players.get("player.local") as PlayerState

func bump_revision() -> void:
	world_revision += 1

func remember_economic(command_id: String, result: Dictionary) -> void:
	if command_id == "":
		return
	if recent_economic_commands.has(command_id):
		return
	recent_economic_commands[command_id] = result.duplicate(true)
	_economic_order.append(command_id)
	while _economic_order.size() > ECONOMIC_CACHE_SIZE:
		var old: String = _economic_order.pop_front()
		recent_economic_commands.erase(old)

func get_economic(command_id: String) -> Variant:
	return recent_economic_commands.get(command_id, null)
