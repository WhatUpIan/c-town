extends CharacterBody2D

@export var npc_id: String = ""
@export var display_name: String = ""
@export var stable_id: String = ""

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

var move_speed: float = 60.0

func _ready() -> void:
	if stable_id == "":
		stable_id = npc_id
	label.text = display_name
	add_to_group("interactables")
	add_to_group("villagers")

func get_stable_id() -> String:
	return stable_id

func get_prompt() -> String:
	return "Talk (%s)" % display_name

func _physics_process(delta: float) -> void:
	if GameSession.world == null or GameSession.simulation_paused or GameSession.modal_pause:
		return
	var ns: NpcState = GameSession.world.npcs.get(npc_id)
	if ns == null:
		return
	var target: Vector2 = ns.position
	var to := target - global_position
	if to.length() > 4.0:
		velocity = to.normalized() * move_speed
		move_and_slide()
		# Gentle separation already via CharacterBody; permissive collision
	else:
		velocity = Vector2.ZERO
		global_position = target
	ns.position = global_position

func apply_texture(tex: Texture2D) -> void:
	if sprite:
		sprite.texture = tex
