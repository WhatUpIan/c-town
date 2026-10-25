class_name SaveService
extends RefCounted

signal save_finished(result: Dictionary)

var content: ContentDB
var slot_path: String = "user://saves/slot_01.json"
var test_root: String = "user://test_saves/"

## Test hooks
var fail_write: bool = false
var fail_rename: bool = false

func bind(p_content: ContentDB) -> void:
	content = p_content

func set_slot(path: String) -> void:
	slot_path = path

func ensure_dir(path: String) -> void:
	var dir_path := path.get_base_dir()
	# Godot 4 static helper (user:// and absolute paths)
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir_path))
	if err != OK and err != ERR_ALREADY_EXISTS:
		# Fallback for nested user:// paths
		var parts := dir_path.trim_prefix("user://").split("/")
		var acc := "user://"
		for part in parts:
			if part == "":
				continue
			acc = acc.path_join(part) if acc != "user://" else "user://%s" % part
			DirAccess.make_dir_absolute(ProjectSettings.globalize_path(acc))

func has_valid_save(path: String = "") -> bool:
	var p := path if path != "" else slot_path
	var res := load_candidate(p)
	return bool(res.get("ok", false))

func save_world(world: WorldState, path: String = "") -> Dictionary:
	var p := path if path != "" else slot_path
	ensure_dir(p)
	var data := SaveCodec.encode(world)
	var json := JSON.stringify(data, "\t")
	var bytes := json.to_utf8_buffer()
	if bytes.size() > SaveCodec.MAX_BYTES:
		var r := {"ok": false, "reason": "save_too_large"}
		save_finished.emit(r)
		return r
	if fail_write:
		var r2 := {"ok": false, "reason": "write_failed"}
		save_finished.emit(r2)
		return r2
	var tmp := p + ".tmp"
	var bak := p + ".bak"
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		var r3 := {"ok": false, "reason": "write_failed"}
		save_finished.emit(r3)
		return r3
	f.store_string(json)
	f.flush()
	f.close()
	# Reopen/validate
	var verify := load_candidate(tmp)
	if not bool(verify.get("ok", false)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
		var r4 := {"ok": false, "reason": "validate_failed"}
		save_finished.emit(r4)
		return r4
	if fail_rename:
		var r5 := {"ok": false, "reason": "rename_failed"}
		save_finished.emit(r5)
		return r5
	# Preserve previous valid main as .bak
	if FileAccess.file_exists(p):
		var prev_ok := bool(load_candidate(p).get("ok", false))
		if prev_ok:
			DirAccess.copy_absolute(ProjectSettings.globalize_path(p), ProjectSettings.globalize_path(bak))
	var err := DirAccess.rename_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(p))
	if err != OK:
		# Fallback: copy then remove tmp
		var copy_err := DirAccess.copy_absolute(ProjectSettings.globalize_path(tmp), ProjectSettings.globalize_path(p))
		if copy_err != OK:
			var r6 := {"ok": false, "reason": "rename_failed"}
			save_finished.emit(r6)
			return r6
		DirAccess.remove_absolute(ProjectSettings.globalize_path(tmp))
	var ok := {"ok": true, "reason": "ok", "path": p}
	save_finished.emit(ok)
	return ok

func load_candidate(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "reason": "missing"}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {"ok": false, "reason": "read_failed"}
	var text := f.get_as_text()
	f.close()
	if text.length() > SaveCodec.MAX_BYTES:
		return {"ok": false, "reason": "save_too_large"}
	var json := JSON.new()
	var err := json.parse(text)
	if err != OK:
		return {"ok": false, "reason": "save_invalid"}
	var parsed: Variant = json.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"ok": false, "reason": "save_invalid"}
	return SaveCodec.decode(parsed, content)

func load_preferred(path: String = "") -> Dictionary:
	## Prefer valid main; if damaged, offer valid backup without silently overwriting.
	var p := path if path != "" else slot_path
	var main_res := load_candidate(p)
	if bool(main_res.get("ok", false)):
		main_res["source"] = "main"
		return main_res
	var bak := p + ".bak"
	var bak_res := load_candidate(bak)
	if bool(bak_res.get("ok", false)):
		bak_res["source"] = "backup"
		bak_res["main_damaged"] = true
		bak_res["main_reason"] = str(main_res.get("reason", "save_invalid"))
		return bak_res
	return main_res

func write_raw(path: String, text: String) -> void:
	ensure_dir(path)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(text)
		f.close()
