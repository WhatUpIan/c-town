extends Control

signal resume
signal save_pressed
signal settings_pressed
signal title_pressed

@onready var confirm: ConfirmationDialog = $AbandonConfirm

func _ready() -> void:
	$Panel/VBox/ResumeButton.pressed.connect(func(): resume.emit())
	$Panel/VBox/SaveButton.pressed.connect(func(): save_pressed.emit())
	$Panel/VBox/SettingsButton.pressed.connect(func(): settings_pressed.emit())
	$Panel/VBox/TitleButton.pressed.connect(_on_title)
	visible = false

func open_menu() -> void:
	visible = true
	GameSession.set_modal_pause(true)
	$Panel/VBox/ResumeButton.grab_focus()

func close_menu() -> void:
	visible = false
	GameSession.set_modal_pause(false)

func _on_title() -> void:
	if GameSession.dirty:
		confirm.popup_centered()
		confirm.confirmed.connect(func(): title_pressed.emit(), CONNECT_ONE_SHOT)
	else:
		title_pressed.emit()
