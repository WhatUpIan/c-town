extends Control

@onready var list: ItemList = $Panel/VBox/ItemList
@onready var close_btn: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	visible = false
	close_btn.pressed.connect(close)
	GameSession.inventory_changed.connect(func(_a): if visible: refresh())

func open_panel() -> void:
	refresh()
	visible = true
	GameSession.set_modal_pause(true)
	close_btn.grab_focus()

func close() -> void:
	visible = false
	GameSession.set_modal_pause(false)

func refresh() -> void:
	list.clear()
	if GameSession.world == null:
		return
	var p := GameSession.world.local_player()
	for s in p.inventory.slots:
		if p.inventory.is_empty_slot(s):
			list.add_item("(empty)")
		else:
			var name := GameSession.content.tr_key(GameSession.content.item(str(s["item_id"])).get("name_key", s["item_id"]))
			list.add_item("%s × %d" % [name, int(s["quantity"])])
