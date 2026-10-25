class_name InventoryState
extends RefCounted

const SLOT_COUNT := 12

## Array of {item_id: String, quantity: int} or empty Dictionary for empty slot
var slots: Array = []

func _init() -> void:
	slots.clear()
	for _i in SLOT_COUNT:
		slots.append({})

func clone() -> InventoryState:
	var c := InventoryState.new()
	c.slots = []
	for s in slots:
		c.slots.append(s.duplicate())
	return c

func count(item_id: String) -> int:
	var total := 0
	for s in slots:
		if s.get("item_id", "") == item_id:
			total += int(s.get("quantity", 0))
	return total

func is_empty_slot(s: Dictionary) -> bool:
	return s.is_empty() or str(s.get("item_id", "")) == "" or int(s.get("quantity", 0)) <= 0

func can_add(item_id: String, quantity: int, max_stack: int) -> bool:
	if quantity <= 0 or item_id == "" or max_stack <= 0:
		return false
	var remaining := quantity
	# Fill existing stacks
	for s in slots:
		if s.get("item_id", "") == item_id:
			var space: int = max_stack - int(s.get("quantity", 0))
			if space > 0:
				remaining -= mini(space, remaining)
				if remaining <= 0:
					return true
	# Empty slots
	for s in slots:
		if is_empty_slot(s):
			remaining -= mini(max_stack, remaining)
			if remaining <= 0:
				return true
	return remaining <= 0

func add(item_id: String, quantity: int, max_stack: int) -> bool:
	if not can_add(item_id, quantity, max_stack):
		return false
	var remaining := quantity
	for i in slots.size():
		var s: Dictionary = slots[i]
		if s.get("item_id", "") == item_id:
			var space: int = max_stack - int(s.get("quantity", 0))
			if space > 0:
				var take: int = mini(space, remaining)
				s["quantity"] = int(s.get("quantity", 0)) + take
				slots[i] = s
				remaining -= take
				if remaining <= 0:
					return true
	for i in slots.size():
		if is_empty_slot(slots[i]):
			var take: int = mini(max_stack, remaining)
			slots[i] = {"item_id": item_id, "quantity": take}
			remaining -= take
			if remaining <= 0:
				return true
	return remaining <= 0

func can_remove(item_id: String, quantity: int) -> bool:
	return quantity > 0 and count(item_id) >= quantity

func remove(item_id: String, quantity: int) -> bool:
	if not can_remove(item_id, quantity):
		return false
	var remaining := quantity
	for i in range(slots.size() - 1, -1, -1):
		var s: Dictionary = slots[i]
		if s.get("item_id", "") != item_id:
			continue
		var q: int = int(s.get("quantity", 0))
		var take: int = mini(q, remaining)
		q -= take
		remaining -= take
		if q <= 0:
			slots[i] = {}
		else:
			slots[i] = {"item_id": item_id, "quantity": q}
		if remaining <= 0:
			return true
	return remaining <= 0

func to_array() -> Array:
	var out: Array = []
	for s in slots:
		if not is_empty_slot(s):
			out.append({"item_id": s["item_id"], "quantity": int(s["quantity"])})
	return out

func from_array(arr: Array) -> void:
	_init()
	for entry in arr:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var id := str(entry.get("item_id", ""))
		var q := int(entry.get("quantity", 0))
		if id == "" or q <= 0:
			continue
		# Place into first empty / stack without max check during restore; validated elsewhere
		var placed := false
		for i in slots.size():
			if is_empty_slot(slots[i]):
				slots[i] = {"item_id": id, "quantity": q}
				placed = true
				break
		if not placed:
			push_warning("Inventory overflow while restoring: %s x%d" % [id, q])
