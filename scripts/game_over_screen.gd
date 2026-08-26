class_name GameOverScreen
extends Control

## Shows the result of a finished round. Name entry follows in the next phase.

signal restart_requested

@onready var _result_label: Label = $Center/Panel/Rows/ResultLabel
@onready var _restart_button: Button = $Center/Panel/Rows/RestartButton


func _ready() -> void:
	_restart_button.pressed.connect(func() -> void: restart_requested.emit())


func show_result(score: int, best_streak: int) -> void:
	_result_label.text = "Score: %d\nBest streak: %d" % [score, best_streak]
	show()
