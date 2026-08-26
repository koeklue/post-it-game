class_name GameOverScreen
extends Control

## Shows the result, takes the player name and displays the leaderboard.

signal score_submitted(player_name: String)
signal restart_requested

@onready var _result_label: Label = $Center/Panel/Rows/ResultLabel
@onready var _entry_row: HBoxContainer = $Center/Panel/Rows/EntryRow
@onready var _name_edit: LineEdit = $Center/Panel/Rows/EntryRow/NameEdit
@onready var _submit_button: Button = $Center/Panel/Rows/EntryRow/SubmitButton
@onready var _list_label: Label = $Center/Panel/Rows/ListLabel
@onready var _restart_button: Button = $Center/Panel/Rows/RestartButton


func _ready() -> void:
	_submit_button.pressed.connect(_submit)
	_name_edit.text_submitted.connect(func(_text: String) -> void: _submit())
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())


func show_result(score: int, best_streak: int, suggested_name: String, can_submit: bool) -> void:
	_result_label.text = "Score: %d\nBest streak: %d" % [score, best_streak]
	_name_edit.text = suggested_name
	_entry_row.visible = can_submit
	show()

	if can_submit:
		_name_edit.grab_focus()
		_name_edit.select_all()


func update_list(entries: Array[Dictionary], title: String) -> void:
	var lines := [title]
	if entries.is_empty():
		lines.append("no entries yet")
	for i in entries.size():
		lines.append("%2d. %-12s %6d" % [i + 1, entries[i]["name"], entries[i]["score"]])
	_list_label.text = "\n".join(lines)


func show_rank(rank: int) -> void:
	if rank > 0:
		_result_label.text += "\nNew entry at #%d" % rank


func _submit() -> void:
	_entry_row.hide() # one submission per round
	score_submitted.emit(_name_edit.text)
