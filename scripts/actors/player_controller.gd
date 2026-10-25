extends CharacterBody2D

const SPEED := 160.0  # ~140+ for 20s reachability across compact map

@onready var sprite: Sprite2D = $Sprite2D
@onready var camera: Camera2D = $Camera2D

var facing: String = "down"
var _bob_t: float = 0.0
var input_enabled: bool = true

func _physics_process(delta: float) -> void:
	if not input_enabled or GameSession.world == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	if GameSession.modal_pause or GameSession.simulation_paused:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() > 1.0:
		dir = dir.normalized()
	elif dir.length() > 0.0:
		dir = dir.normalized()
	velocity = dir * SPEED
	move_and_slide()
	if dir != Vector2.ZERO:
		_update_facing(dir)
		_bob_t += delta * 10.0
		sprite.position.y = -24.0 + sin(_bob_t) * (0.0 if GameSession.settings.get("reduced_motion", false) else 2.0)
		# Mirror for left/right
		sprite.flip_h = facing == "left"
	else:
		sprite.position.y = -24.0
	# Sync authoritative position periodically
	var p := GameSession.world.local_player()
	if p:
		p.position = global_position
		p.facing = facing

func _update_facing(dir: Vector2) -> void:
	if abs(dir.x) > abs(dir.y):
		facing = "right" if dir.x > 0.0 else "left"
	else:
		facing = "down" if dir.y > 0.0 else "up"

func sync_from_state() -> void:
	var p := GameSession.world.local_player() if GameSession.world else null
	if p:
		global_position = p.position
		facing = p.facing
