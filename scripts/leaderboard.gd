class_name Leaderboard
extends Node

## Persists the top scores per input mode in a small JSON file under user://.

const SAVE_PATH := "user://leaderboard.json"
const MAX_ENTRIES := 10 ## Kept per input mode, not in total
const MAX_NAME_LENGTH := 12

## Remembered so the player does not retype their name every round.
var last_name: String = ""

var _entries: Array[Dictionary] = []


func _ready() -> void:
	_load()


## True if the score would make it onto the board for that mode.
func qualifies(score: int, mode: InputMode.Mode) -> bool:
	if score <= 0:
		return false

	var mode_entries := get_entries(mode)
	if mode_entries.size() < MAX_ENTRIES:
		return true
	return score > int(mode_entries[-1]["score"])


## Returns the 1-based rank of the new entry, or -1 if it did not make the list.
func add_entry(player_name: String, score: int, mode: InputMode.Mode) -> int:
	var entry := {
		"name": _sanitize_name(player_name),
		"score": score,
		"mode": int(mode),
	}
	last_name = entry["name"]

	_entries.append(entry)
	_sort_and_trim()
	_save()

	var mode_entries := get_entries(mode)
	for i in mode_entries.size():
		# Reference comparison - two players may share name and score.
		if is_same(mode_entries[i], entry):
			return i + 1
	return -1


func get_entries(mode: InputMode.Mode) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in _entries:
		if int(entry["mode"]) == int(mode):
			result.append(entry)
	return result


func _sanitize_name(player_name: String) -> String:
	var clean := player_name.strip_edges()
	if clean.is_empty():
		clean = "ANON"
	return clean.substr(0, MAX_NAME_LENGTH)


func _sort_and_trim() -> void:
	_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["score"] > b["score"])

	# Every mode keeps its own top list, so the cap is applied per mode.
	var kept: Array[Dictionary] = []
	var counts := {}
	for entry in _entries:
		var mode: int = int(entry["mode"])
		var count: int = counts.get(mode, 0)
		if count < MAX_ENTRIES:
			counts[mode] = count + 1
			kept.append(entry)
	_entries = kept


func _save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Leaderboard: cannot write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify({"last_name": last_name, "entries": _entries}, "\t"))


func _load() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Leaderboard: save file is unreadable, starting empty")
		return

	last_name = str(parsed.get("last_name", ""))
	for raw in parsed.get("entries", []):
		if typeof(raw) != TYPE_DICTIONARY or not raw.has("name") or not raw.has("score"):
			continue # skip anything that does not look like an entry
		_entries.append({
			"name": str(raw["name"]),
			"score": int(raw["score"]), # JSON only knows floats, so numbers come back cast
			"mode": int(raw.get("mode", InputMode.Mode.MOUSE)),
		})
	_sort_and_trim()
