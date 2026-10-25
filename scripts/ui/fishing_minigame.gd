extends Control

## Timing-band fishing: marker oscillates; press action while inside the target band.
## At most ~5 seconds. Modal — caller should pause simulation before opening.

signal finished(success: bool, canceled: bool)

const DURATION_SEC := 5.0
const BAND_CENTER := 0.5
const BAND_HALF_WIDTH := 0.12  # fraction of track (success zone ~24% of bar)
const MARKER_SPEED := 1.15  # cycles per second across 0..1 (ping-pong)

@onready var track: ColorRect = $Panel/VBox/Track
@onready var band: ColorRect = $Panel/VBox/Track/Band
@onready var marker: ColorRect = $Panel/VBox/Track/Marker
@onready var hint: Label = $Panel/VBox/Hint
@onready var timer_label: Label = $Panel/VBox/TimerLabel

var _active: bool = false
var _t: float = 0.0
var _marker_u: float = 0.0
var _dir: float = 1.0
var _reduced_motion: bool = false

func _ready() -> void:
	visible = false
	set_process(false)
	_layout_band()

func open_minigame() -> void:
	_reduced_motion = bool(GameSession.settings.get("reduced_motion", false))
	_active = true
	_t = 0.0
	_marker_u = 0.0
	_dir = 1.0
	visible = true
	GameSession.set_modal_pause(true)
	set_process(true)
	hint.text = "Press Space / E while the marker is in the lit band. Esc cancels."
	call_deferred("_layout_band")
	_update_marker_visual()

func _layout_band() -> void:
	if track == null:
		return
	var w: float = track.size.x
	if w < 8.0:
		w = 400.0
	var band_w: float = w * BAND_HALF_WIDTH * 2.0
	band.size = Vector2(band_w, maxf(track.size.y, 28.0))
	band.position = Vector2(w * BAND_CENTER - band_w * 0.5, 0.0)
	_update_marker_visual()

func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	var remaining: float = maxf(0.0, DURATION_SEC - _t)
	timer_label.text = "%.1fs" % remaining
	# Ping-pong marker along 0..1
	var speed: float = MARKER_SPEED * (0.55 if _reduced_motion else 1.0)
	_marker_u += _dir * speed * delta
	if _marker_u >= 1.0:
		_marker_u = 1.0
		_dir = -1.0
	elif _marker_u <= 0.0:
		_marker_u = 0.0
		_dir = 1.0
	_update_marker_visual()
	if _t >= DURATION_SEC:
		_end(false, false)

func _update_marker_visual() -> void:
	if track == null or marker == null:
		return
	var w: float = maxf(track.size.x, 1.0)
	var mw: float = marker.size.x
	marker.position = Vector2(_marker_u * (w - mw), (track.size.y - marker.size.y) * 0.5)
	var in_band := _is_in_band()
	marker.color = Color(0.95, 0.9, 0.35) if in_band else Color(0.95, 0.95, 0.95)

func _is_in_band() -> bool:
	return absf(_marker_u - BAND_CENTER) <= BAND_HALF_WIDTH

func _unhandled_input(event: InputEvent) -> void:
	if not _active:
		return
	if event.is_action_pressed("cancel") or event.is_action_pressed("pause"):
		_end(false, true)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("primary_action") or event.is_action_pressed("interact"):
		_end(_is_in_band(), false)
		get_viewport().set_input_as_handled()

func _end(success: bool, canceled: bool) -> void:
	if not _active:
		return
	_active = false
	set_process(false)
	visible = false
	GameSession.set_modal_pause(false)
	finished.emit(success, canceled)
