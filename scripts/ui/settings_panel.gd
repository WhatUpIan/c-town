extends Control

signal closed

func _ready() -> void:
	$Panel/VBox/FontScale.value = float(GameSession.settings.get("font_scale", 1.0))
	$Panel/VBox/Volume.value = float(GameSession.settings.get("master_volume", 1.0))
	$Panel/VBox/ReducedMotion.button_pressed = bool(GameSession.settings.get("reduced_motion", false))
	$Panel/VBox/FontScale.value_changed.connect(func(v):
		GameSession.settings["font_scale"] = v
		get_tree().root.content_scale_factor = v
	)
	$Panel/VBox/Volume.value_changed.connect(func(v):
		GameSession.settings["master_volume"] = v
		AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))
	)
	$Panel/VBox/ReducedMotion.toggled.connect(func(on):
		GameSession.settings["reduced_motion"] = on
	)
	$Panel/VBox/CloseButton.pressed.connect(func():
		GameSession.save_settings()
		visible = false
		closed.emit()
	)
	visible = false

func open_panel() -> void:
	visible = true
	$Panel/VBox/CloseButton.grab_focus()
