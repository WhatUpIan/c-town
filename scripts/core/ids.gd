class_name Ids
extends Object

const PLAYER_LOCAL := "player.local"
const QUEST_FIRST_DELIVERY := "quest.first_delivery"
const NPC_MIRIAM := "npc.merchant_01"  # gardener / delivery giver (brief table uses merchant_01 style; Miriam)
const NPC_YEHUDAH := "npc.fisher_01"
const NPC_HANNAH := "npc.stall_01"
const MAP_VILLAGE := "village"

static func plot_id(index: int) -> String:
	return "plot.home_%02d" % index
