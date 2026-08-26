class_name HUD
extends Control

## Passive display - receives values through signals, holds no game logic itself.

@onready var _score_label: Label = $Margin/Rows/ScoreLabel
@onready var _streak_label: Label = $Margin/Rows/StreakLabel
@onready var _speed_label: Label = $Margin/Rows/SpeedLabel


func update_score(value: int) -> void:
	_score_label.text = "Score: %d" % value


func update_streak(value: int) -> void:
	_streak_label.text = "Streak: %d" % value


func update_speed(value: float) -> void:
	_speed_label.text = "Speed: x%.2f" % value
