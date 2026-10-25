extends CanvasLayer

@onready var time_label: Label = $Margin/VBox/TopRow/TimeLabel
@onready var date_label: Label = $Margin/VBox/TopRow/DateLabel
@onready var wallet_label: Label = $Margin/VBox/TopRow/WalletLabel
@onready var tool_label: Label = $Margin/VBox/TopRow/ToolLabel
@onready var notify_label: Label = $Margin/VBox/NotifyLabel

func _ready() -> void:
	GameSession.clock_changed.connect(_refresh)
	GameSession.inventory_changed.connect(func(_a): _refresh())
	GameSession.notification.connect(_on_notify)
	_refresh()

func _refresh() -> void:
	if GameSession.world == null:
		return
	var abs_m := GameSession.world.absolute_minutes
	time_label.text = CalendarSystem.format_civil_time(abs_m)
	var rel := CalendarSystem.religious_ordinal(abs_m)
	date_label.text = "%s · %s" % [CalendarSystem.lunar_label(rel), GameSession.calendar.weekday_name()]
	var p := GameSession.world.local_player()
	if p:
		wallet_label.text = "%d trade units" % p.wallet
		tool_label.text = GameSession.content.tr_key("tool." + p.selected_tool)

func _on_notify(text: String) -> void:
	notify_label.text = text
	notify_label.visible = true
	get_tree().create_timer(4.0).timeout.connect(func():
		if notify_label.text == text:
			notify_label.visible = false
	)
