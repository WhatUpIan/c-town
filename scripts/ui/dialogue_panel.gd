extends Control

signal closed
signal open_stall_requested

@onready var speaker: Label = $Panel/VBox/Speaker
@onready var text_label: RichTextLabel = $Panel/VBox/Text
@onready var choices: VBoxContainer = $Panel/VBox/Choices

var _npc_id: String = ""
var _node_id: String = ""

func _ready() -> void:
	visible = false

func open_for(npc_id: String) -> void:
	_npc_id = npc_id
	var def: Dictionary = GameSession.content.npcs.get(npc_id, {})
	_node_id = str(def.get("dialogue_id", ""))
	# Biblical rumor injection for Yehudah
	if GameSession.world.story_mode == "biblical" and npc_id == "npc.fisher_01":
		_node_id = "dlg.biblical.rumor"
	_show_node(_node_id)
	visible = true
	GameSession.set_modal_pause(true)

func _show_node(node_id: String) -> void:
	for c in choices.get_children():
		c.queue_free()
	if node_id == "" or not GameSession.content.dialogue.has(node_id):
		close()
		return
	var node: Dictionary = GameSession.content.dialogue[node_id]
	var mode_f := str(node.get("mode_filter", "any"))
	if mode_f != "any" and mode_f != GameSession.world.story_mode:
		# Skip filtered nodes
		close()
		return
	var sid := str(node.get("speaker_id", ""))
	speaker.text = str(GameSession.content.npcs.get(sid, {}).get("display_name", sid))
	text_label.text = GameSession.content.tr_key(str(node.get("text_key", "")))
	var first_btn: Button = null
	for ch in node.get("choices", []):
		var btn := Button.new()
		btn.text = GameSession.content.tr_key(str(ch.get("text_key", "")))
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		var next_id := str(ch.get("next_id", ""))
		var effects: Array = ch.get("effects", [])
		btn.pressed.connect(_on_choice.bind(next_id, effects))
		choices.add_child(btn)
		if first_btn == null:
			first_btn = btn
	if first_btn:
		first_btn.grab_focus()

func _on_choice(next_id: String, effects: Array) -> void:
	for e in effects:
		var kind := str(e.get("kind", ""))
		match kind:
			"accept_quest":
				GameSession.execute(GameCommand.make("accept_quest", "player.local", str(e.get("quest_id", ""))))
			"complete_quest":
				var res: CommandResult = GameSession.execute(GameCommand.make("complete_quest", "player.local", str(e.get("quest_id", "")), {}, "quest_complete_" + str(Time.get_ticks_msec())))
				if not res.ok:
					GameSession.notification.emit(GameSession.tr_reason(res.reason_code))
			"open_stall":
				close()
				open_stall_requested.emit()
				return
	if next_id == "":
		close()
	else:
		_show_node(next_id)

func close() -> void:
	visible = false
	GameSession.set_modal_pause(false)
	closed.emit()
