extends Control

@onready var status: Label = $Panel/VBox/Status
@onready var list: VBoxContainer = $Panel/VBox/List
@onready var close_btn: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close)

func open_panel() -> void:
	_refresh()
	visible = true
	GameSession.set_modal_pause(true)
	close_btn.grab_focus()

func close() -> void:
	visible = false
	GameSession.set_modal_pause(false)

func _refresh() -> void:
	for c in list.get_children():
		c.queue_free()
	var open := GameSession.calendar.stall_open()
	status.text = "Stall open (08:00–18:00, closed Sabbath)." if open else "Stall closed."
	if not open:
		return
	for item_id in ["barley_seed", "barley", "lake_fish", "bread"]:
		var def: Dictionary = GameSession.content.item(item_id)
		var row := HBoxContainer.new()
		var lab := Label.new()
		lab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lab.text = "%s  buy %d / sell %d" % [GameSession.content.tr_key(str(def.get("name_key", item_id))), int(def.get("buy_price", 0)), int(def.get("sell_price", 0))]
		row.add_child(lab)
		var buy := Button.new()
		buy.text = "Buy 1"
		buy.pressed.connect(_buy.bind(item_id))
		row.add_child(buy)
		var sell := Button.new()
		sell.text = "Sell 1"
		sell.pressed.connect(_sell.bind(item_id))
		row.add_child(sell)
		list.add_child(row)

func _buy(item_id: String) -> void:
	var cmd := GameCommand.make("buy", "player.local", "interact.stall", {"item_id": item_id, "quantity": 1}, "buy_%s_%d" % [item_id, Time.get_ticks_msec()])
	var res: CommandResult = GameSession.execute(cmd)
	if not res.ok:
		GameSession.notification.emit(GameSession.tr_reason(res.reason_code))
	_refresh()

func _sell(item_id: String) -> void:
	var cmd := GameCommand.make("sell", "player.local", "interact.stall", {"item_id": item_id, "quantity": 1}, "sell_%s_%d" % [item_id, Time.get_ticks_msec()])
	var res: CommandResult = GameSession.execute(cmd)
	if not res.ok:
		GameSession.notification.emit(GameSession.tr_reason(res.reason_code))
	_refresh()
