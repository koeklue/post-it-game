class_name GameState
extends Node

## Owns score, streak and the derived game speed.
## Pure logic - never touches the scene tree, only reports through signals.

signal score_changed(score: int)
signal streak_changed(streak: int)
signal speed_changed(speed_factor: float)

@export_group("Scoring")
@export var enemy_points: int = 10
@export var civilian_penalty: int = 25
@export var streak_step: int = 5 ## Streak needed to unlock the next bonus step
@export var points_per_streak_step: int = 5

@export_group("Speed")
@export var speed_per_streak: float = 0.04
@export var max_speed_factor: float = 2.5

var score: int = 0
var streak: int = 0
var best_streak: int = 0

## Set by the heat system in phase 3, multiplies the streak based speed.
var speed_multiplier: float = 1.0:
	set(value):
		speed_multiplier = value
		_emit_speed()


func reset() -> void:
	score = 0
	streak = 0
	best_streak = 0
	speed_multiplier = 1.0
	score_changed.emit(score)
	streak_changed.emit(streak)
	_emit_speed()


func register_enemy_hit() -> void:
	_add_score(enemy_points + get_streak_bonus())
	streak += 1
	best_streak = maxi(best_streak, streak)
	streak_changed.emit(streak)
	_emit_speed()


func register_civilian_hit() -> void:
	_add_score(-civilian_penalty)
	_break_streak()


## A missed enemy costs no points but ends the streak - staying accurate matters.
func register_enemy_missed() -> void:
	_break_streak()


## Bonus points for the streak the player is currently holding.
func get_streak_bonus() -> int:
	return (streak / streak_step) * points_per_streak_step


func get_speed_factor() -> float:
	var streak_speed := 1.0 + streak * speed_per_streak
	return minf(streak_speed * speed_multiplier, max_speed_factor)


func _add_score(amount: int) -> void:
	score = maxi(0, score + amount) # the score never drops below zero
	score_changed.emit(score)


func _break_streak() -> void:
	if streak == 0:
		return
	streak = 0
	streak_changed.emit(streak)
	_emit_speed()


func _emit_speed() -> void:
	speed_changed.emit(get_speed_factor())
