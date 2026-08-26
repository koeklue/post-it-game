extends Node2D

## Phase 2: connects targets, game state and HUD.
## Main is the only node that knows all three - they stay unaware of each other.

@onready var _spawner: Spawner = $Spawner
@onready var _game_state: GameState = $GameState
@onready var _hud: HUD = $UI/HUD


func _ready() -> void:
	_game_state.score_changed.connect(_hud.update_score)
	_game_state.streak_changed.connect(_hud.update_streak)
	_game_state.speed_changed.connect(_on_speed_changed)

	_spawner.target_spawned.connect(_on_target_spawned)

	_game_state.reset()
	_spawner.start()


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


func _on_speed_changed(speed_factor: float) -> void:
	_spawner.speed_factor = speed_factor
	_hud.update_speed(speed_factor)
