class_name HeatSystem
extends Node

## Drives the heat / cooldown cycle.
## Pure logic - reports a speed multiplier, Main forwards it to the GameState.

enum State { IDLE, HEAT, COOLDOWN }

signal state_changed(state: State)
signal multiplier_changed(value: float)

@export var streak_threshold: int = 15 ## Streak needed to trigger a heat phase
@export var heat_duration: float = 6.0
@export var heat_multiplier: float = 2.0
@export var cooldown_duration: float = 3.0
@export var cooldown_multiplier: float = 0.7 ## Below 1.0 so the game settles back down
@export var blend_time: float = 0.4 ## Seconds to ease between two multipliers

var state: State = State.IDLE

## Eased by the phase transitions instead of jumping, so the speed change is readable.
var multiplier: float = 1.0:
	set(value):
		multiplier = value
		multiplier_changed.emit(value)

var _next_threshold: int = 0
var _blend_tween: Tween

@onready var _phase_timer: Timer = $PhaseTimer


func _ready() -> void:
	_phase_timer.timeout.connect(_on_phase_timer_timeout)


func reset() -> void:
	_phase_timer.stop()
	_next_threshold = streak_threshold
	state = State.IDLE
	state_changed.emit(state)
	_blend_to(1.0, 0.0)


## Connected to GameState.streak_changed.
func on_streak_changed(streak: int) -> void:
	if streak == 0:
		# Streak broke - the next heat has to be earned from scratch.
		_next_threshold = streak_threshold
		return

	if state == State.IDLE and streak >= _next_threshold:
		# Every further heat inside the same streak costs another full threshold.
		_next_threshold += streak_threshold
		_start_heat()


func _start_heat() -> void:
	_set_state(State.HEAT)
	_blend_to(heat_multiplier, blend_time)
	_phase_timer.start(heat_duration)


func _start_cooldown() -> void:
	_set_state(State.COOLDOWN)
	_blend_to(cooldown_multiplier, blend_time)
	_phase_timer.start(cooldown_duration)


func _on_phase_timer_timeout() -> void:
	match state:
		State.HEAT:
			_start_cooldown()
		State.COOLDOWN:
			_set_state(State.IDLE)
			_blend_to(1.0, blend_time)


func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	state_changed.emit(state)


func _blend_to(target: float, duration: float) -> void:
	# A running blend is killed first, otherwise two tweens fight over the property.
	if _blend_tween != null and _blend_tween.is_valid():
		_blend_tween.kill()

	if duration <= 0.0:
		multiplier = target
		return

	_blend_tween = create_tween()
	_blend_tween.tween_property(self, "multiplier", target, duration)
