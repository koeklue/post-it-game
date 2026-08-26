class_name HUD
extends Control

## Passive display - receives values through signals, holds no game logic itself.

const HEAT_COLORS := {
	HeatSystem.State.IDLE: Color("9aa0a6"),
	HeatSystem.State.HEAT: Color("ff9d3d"),
	HeatSystem.State.COOLDOWN: Color("6ba7ff"),
}

@onready var _score_label: Label = $Margin/Rows/ScoreLabel
@onready var _streak_label: Label = $Margin/Rows/StreakLabel
@onready var _speed_label: Label = $Margin/Rows/SpeedLabel
@onready var _heat_label: Label = $Margin/Rows/HeatLabel
@onready var _time_label: Label = $Margin/Rows/TimeLabel


func update_score(value: int) -> void:
	_score_label.text = "Score: %d" % value


func update_streak(value: int) -> void:
	_streak_label.text = "Streak: %d" % value


func update_speed(value: float) -> void:
	_speed_label.text = "Speed: x%.2f" % value


func update_time(seconds: float) -> void:
	_time_label.text = "Time: %.1f" % maxf(seconds, 0.0)


func update_heat_state(state: HeatSystem.State) -> void:
	match state:
		HeatSystem.State.HEAT:
			_heat_label.text = "HEAT MODE"
		HeatSystem.State.COOLDOWN:
			_heat_label.text = "Cooldown"
		_:
			_heat_label.text = "Heat: ready"
	_heat_label.modulate = HEAT_COLORS[state]
