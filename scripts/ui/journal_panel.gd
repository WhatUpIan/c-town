extends Control

@onready var body: RichTextLabel = $Panel/VBox/Body
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
	if GameSession.world == null:
		return
	var lines: PackedStringArray = []
	lines.append("[b]Journal[/b]")
	var q: QuestState = GameSession.world.quests.get("quest.first_delivery")
	if q:
		lines.append("Delivery for Miriam: %s" % q.status)
	if GameSession.world.story_mode == "biblical" and GameSession.world.flags.get("story.biblical_rumor", false):
		lines.append(GameSession.content.tr_key("story.biblical_rumor_summary"))
	else:
		lines.append("(Everyday Life — no biblical story entries.)")
	body.text = "\n".join(lines)
