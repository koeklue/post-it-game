extends Node2D

## Phase 4: owns the round flow - start screen, timed round, game over screen.
## Main is the only node that knows all systems, they stay unaware of each other.

enum Phase { READY, PLAYING, OVER }

@export var round_duration: float = 45.0

@onready var _spawner: Spawner = $Spawner
@onready var _game_state: GameState = $GameState
@onready var _heat_system: HeatSystem = $HeatSystem
@onready var _targets: Node2D = $Targets
@onready var _round_timer: Timer = $RoundTimer
@onready var _hud: HUD = $UI/HUD
@onready var _start_screen: StartScreen = $UI/StartScreen
@onready var _game_over_screen: GameOverScreen = $UI/GameOverScreen

var _phase: Phase = Phase.READY


func _ready() -> void:
	_game_state.score_changed.connect(_hud.update_score)
	_game_state.streak_changed.connect(_hud.update_streak)
	_game_state.speed_changed.connect(_on_speed_changed)

	# The streak feeds the heat system, its multiplier feeds back into the speed.
	_game_state.streak_changed.connect(_heat_system.on_streak_changed)
	_heat_system.multiplier_changed.connect(_on_heat_multiplier_changed)
	_heat_system.state_changed.connect(_hud.update_heat_state)

	_spawner.target_spawned.connect(_on_target_spawned)
	_round_timer.timeout.connect(_on_round_finished)
	_start_screen.start_requested.connect(_start_round)
	_game_over_screen.restart_requested.connect(_show_start_screen)

	_show_start_screen()


func _process(_delta: float) -> void:
	# Polling the timer is simpler than mirroring the remaining time in a variable.
	if _phase == Phase.PLAYING:
		_hud.update_time(_round_timer.time_left)


func _show_start_screen() -> void:
	_phase = Phase.READY
	_spawner.stop()
	_clear_targets()
	_heat_system.reset()
	_game_state.reset()
	_hud.update_time(round_duration)

	_game_over_screen.hide()
	_start_screen.show()


func _start_round(mode: InputMode.Mode) -> void:
	_phase = Phase.PLAYING
	_start_screen.hide()

	_spawner.set_input_mode(mode)
	_heat_system.reset()
	_game_state.reset()

	_round_timer.start(round_duration)
	_spawner.start()


func _on_round_finished() -> void:
	_phase = Phase.OVER
	_spawner.stop()
	_clear_targets() # leftover targets would still be clickable behind the overlay
	_hud.update_time(0.0)
	_game_over_screen.show_result(_game_state.score, _game_state.best_streak)


func _clear_targets() -> void:
	for child in _targets.get_children():
		child.queue_free()


## Every target reports back through signals instead of reaching into the main scene.
func _on_target_spawned(target: Target) -> void:
	target.hit.connect(_on_target_hit)
	target.expired.connect(_on_target_expired)


func _on_target_hit(target: Target) -> void:
	if target.type == Target.Type.ENEMY:
		_game_state.register_enemy_hit()
	else:
		_game_state.register_civilian_hit()


func _on_target_expired(target: Target) -> void:
	# Letting a civilian disappear is correct play, only missed enemies hurt.
	if target.type == Target.Type.ENEMY:
		_game_state.register_enemy_missed()


func _on_heat_multiplier_changed(value: float) -> void:
	_game_state.speed_multiplier = value


func _on_speed_changed(speed_factor: float) -> void:
	_spawner.speed_factor = speed_factor
	_hud.update_speed(speed_factor)
