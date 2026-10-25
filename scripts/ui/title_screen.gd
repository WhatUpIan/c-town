extends Control

signal start_everyday
signal start_biblical
signal continue_pressed
signal open_settings
signal quit_pressed

@onready var continue_btn: Button = $Center/Panel/VBox/ContinueButton
@onready var confirm: ConfirmationDialog = $ReplaceConfirm

func _ready() -> void:
	_refresh()
	$Center/Panel/VBox/NewEveryday.pressed.connect(_on_new_everyday_pressed)
	$Center/Panel/VBox/NewBiblical.pressed.connect(_on_new_biblical_pressed)
	continue_btn.pressed.connect(_on_continue_pressed)
	$Center/Panel/VBox/SettingsButton.pressed.connect(func(): open_settings.emit())
	$Center/Panel/VBox/QuitButton.pressed.connect(func(): quit_pressed.emit())
	_focus_primary()

func _on_continue_pressed() -> void:
	# Never route Continue through the replace-save New Game confirm.
	if confirm.visible:
		confirm.hide()
	continue_pressed.emit()

func _on_new_everyday_pressed() -> void:
	if GameSession.has_continue():
		confirm.dialog_text = "Starting a new Everyday Life game will replace your existing save. Continue?"
		confirm.popup_centered()
		if not confirm.confirmed.is_connected(_new_everyday):
			confirm.confirmed.connect(_new_everyday, CONNECT_ONE_SHOT)
	else:
		_new_everyday()

func _on_new_biblical_pressed() -> void:
	if GameSession.has_continue():
		var d := ConfirmationDialog.new()
		d.dialog_text = "Replace existing save with a new Biblical Story game?"
		add_child(d)
		d.popup_centered()
		d.confirmed.connect(func(): start_biblical.emit(); d.queue_free())
		d.canceled.connect(func(): d.queue_free())
	else:
		start_biblical.emit()

func _new_everyday() -> void:
	start_everyday.emit()

func _refresh() -> void:
	continue_btn.disabled = not GameSession.has_continue()
	_focus_primary()

func _focus_primary() -> void:
	if not continue_btn.disabled:
		continue_btn.grab_focus()
	else:
		$Center/Panel/VBox/NewEveryday.grab_focus()
