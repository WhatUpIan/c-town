class_name Targeting
extends RefCounted

## Keyboard/controller: nearest eligible within 48px; stable ID breaks ties.

static func pick_nearest(origin: Vector2, candidates: Array, max_dist: float = 48.0) -> Node:
	var best: Node = null
	var best_dist := max_dist
	var best_id := ""
	for c in candidates:
		if c == null or not (c is Node2D):
			continue
		var n: Node2D = c
		var d: float = origin.distance_to(n.global_position)
		var sid := ""
		if n.has_method("get_stable_id"):
			sid = str(n.call("get_stable_id"))
		elif "stable_id" in n:
			sid = str(n.get("stable_id"))
		if d < best_dist or (is_equal_approx(d, best_dist) and (best == null or sid < best_id)):
			if d <= max_dist:
				best = n
				best_dist = d
				best_id = sid
	return best
