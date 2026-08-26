class_name Spawner
extends Node2D

## Spawns targets at random, non-overlapping positions inside a rectangle.

signal target_spawned(target: Target)

const PLACEMENT_ATTEMPTS := 12
const MIN_GAP := 12.0 # extra pixels kept between two targets

@export var target_scene: PackedScene
@export var targets_root: Node2D

@export_group("Spawn rules")
@export var spawn_area := Rect2(140.0, 150.0, 1000.0, 440.0)
@export var base_interval: float = 0.75 ## Seconds between spawns at speed factor 1.0
@export var base_lifetime: float = 1.60 ## Seconds a target stays visible at speed factor 1.0
@export var base_radius: float = 44.0
@export_range(0.0, 1.0) var civilian_chance: float = 0.30
@export var max_active: int = 6

## Scales spawn rate and lifetime, driven by GameState.
var speed_factor: float = 1.0
## Multiplies target size, driven by the active input mode.
var radius_factor: float = 1.0
## Multiplies target lifetime, compensating the dwell time in trackpad mode.
var lifetime_factor: float = 1.0
var input_mode: InputMode.Mode = InputMode.Mode.MOUSE

@onready var _spawn_timer: Timer = $SpawnTimer


func _ready() -> void:
	# Debug-only guards: unassigned exports otherwise fail deep inside _try_spawn().
	assert(target_scene != null, "Spawner: target_scene is not assigned in the inspector")
	assert(targets_root != null, "Spawner: targets_root is not assigned in the inspector")
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)


## Trackpad targets are smaller, live longer and are hit by dwelling on them.
func set_input_mode(mode: InputMode.Mode) -> void:
	input_mode = mode
	var is_trackpad := mode == InputMode.Mode.TRACKPAD
	radius_factor = InputMode.TRACKPAD_RADIUS_FACTOR if is_trackpad else 1.0
	lifetime_factor = InputMode.TRACKPAD_LIFETIME_FACTOR if is_trackpad else 1.0


func start() -> void:
	_schedule_next()


func stop() -> void:
	_spawn_timer.stop()


func _on_spawn_timer_timeout() -> void:
	_try_spawn()
	# Rescheduled every tick so a changed speed factor takes effect immediately.
	_schedule_next()


func _schedule_next() -> void:
	_spawn_timer.start(base_interval / speed_factor)


func _try_spawn() -> void:
	if _active_targets().size() >= max_active:
		return

	var radius := base_radius * radius_factor
	var spawn_position := _find_free_position(radius)
	if spawn_position == Vector2.INF:
		return # no room right now, simply skip this tick

	var target: Target = target_scene.instantiate()
	var type := Target.Type.CIVILIAN if randf() < civilian_chance else Target.Type.ENEMY
	var hover_time: float = InputMode.TRACKPAD_HOVER_TIME if input_mode == InputMode.Mode.TRACKPAD else 0.0
	target.setup(type, radius, base_lifetime * lifetime_factor / speed_factor, hover_time)
	target.position = spawn_position
	targets_root.add_child(target)
	target_spawned.emit(target)


## Targets already queued for deletion no longer block a spawn slot.
func _active_targets() -> Array[Target]:
	var result: Array[Target] = []
	for child in targets_root.get_children():
		var target := child as Target
		if target != null and not target.is_queued_for_deletion():
			result.append(target)
	return result


func _find_free_position(radius: float) -> Vector2:
	for _attempt in PLACEMENT_ATTEMPTS:
		var candidate := Vector2(
			randf_range(spawn_area.position.x, spawn_area.end.x),
			randf_range(spawn_area.position.y, spawn_area.end.y)
		)
		if _is_free(candidate, radius):
			return candidate
	return Vector2.INF


func _is_free(candidate: Vector2, radius: float) -> bool:
	for target in _active_targets():
		if candidate.distance_to(target.position) < radius + target.radius + MIN_GAP:
			return false
	return true
