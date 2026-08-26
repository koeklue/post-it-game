extends Node2D

## Phase 1: wires the spawner to freshly spawned targets and reports raw hit data.
## Score, streak and speed logic follow in phase 2.

@onready var _spawner: Spawner = $Spawner
@onready var _debug_label: Label = $UI/DebugLabel

var _enemies_hit: int = 0
var _civilians_hit: int = 0
var _expired: int = 0


func _ready() -> void:
	_spawner.target_spawned.connect(_on_target_spawned)
	_spawner.start()
	_update_debug_label()


## Every target reports back through signals instead of reaching into the main scene.
func _on_target_spawned(target: Target) -> void:
	target.hit.connect(_on_target_hit)
	target.expired.connect(_on_target_expired)


func _on_target_hit(target: Target) -> void:
	if target.type == Target.Type.ENEMY:
		_enemies_hit += 1
	else:
		_civilians_hit += 1
	_update_debug_label()


func _on_target_expired(_target: Target) -> void:
	_expired += 1
	_update_debug_label()


func _update_debug_label() -> void:
	_debug_label.text = "Enemies: %d\nCivilians: %d\nExpired: %d" % [
		_enemies_hit, _civilians_hit, _expired
	]
