class_name Target
extends Area2D

## A single whack-a-mole target: pops up, waits to be hit, then expires on its own.
## Supports two hit modes - a click, or dwelling on it with the cursor.

enum Type { ENEMY, CIVILIAN }

signal hit(target: Target)
signal expired(target: Target)

const COLORS := {
	Type.ENEMY: Color("d94f4f"),
	Type.CIVILIAN: Color("4f9dd9"),
}

var type: Type = Type.ENEMY
var radius: float = 44.0

var _lifetime: float = 1.6
var _hover_time: float = 0.0 # 0 = click mode, > 0 = trackpad dwell mode
var _hover_progress: float = 0.0
var _is_hovered: bool = false
var _is_consumed: bool = false # guards against hit and expire firing in the same frame

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _lifetime_timer: Timer = $LifetimeTimer


## Called by the spawner right after instantiation, before the node enters the tree.
func setup(target_type: Type, target_radius: float, lifetime: float, hover_time: float = 0.0) -> void:
	type = target_type
	radius = target_radius
	_lifetime = lifetime
	_hover_time = hover_time


func _ready() -> void:
	# A fresh shape per instance keeps the radius independent.
	var circle := CircleShape2D.new()
	circle.radius = radius
	_collision.shape = circle

	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	_lifetime_timer.start(_lifetime)

	if _hover_time > 0.0:
		mouse_entered.connect(_on_mouse_entered)
		mouse_exited.connect(_on_mouse_exited)
	else:
		# Clicks stay disabled in dwell mode, otherwise it would be the easier option.
		input_event.connect(_on_input_event)

	set_process(_hover_time > 0.0)
	queue_redraw()


func _process(delta: float) -> void:
	if not _is_hovered:
		return

	_hover_progress += delta
	queue_redraw()
	if _hover_progress >= _hover_time:
		consume_hit()


func _draw() -> void:
	# Placeholder visuals - sprites and effects come in a later phase.
	draw_circle(Vector2.ZERO, radius, COLORS[type])
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0, 0, 0, 0.4), 3.0, true)

	# Dwell feedback: a ring filling up tells the player the hold is registering.
	if _hover_time > 0.0 and _hover_progress > 0.0:
		var ratio := clampf(_hover_progress / _hover_time, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius - 7.0, -PI / 2.0, -PI / 2.0 + TAU * ratio, 32, Color.WHITE, 4.0, true)


func _on_mouse_entered() -> void:
	_is_hovered = true


func _on_mouse_exited() -> void:
	# Leaving resets the dwell - partial progress is never banked.
	_is_hovered = false
	_hover_progress = 0.0
	queue_redraw()


func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		consume_hit()


func consume_hit() -> void:
	if _is_consumed:
		return
	_is_consumed = true
	hit.emit(self)
	queue_free()


func _on_lifetime_timeout() -> void:
	if _is_consumed:
		return
	_is_consumed = true
	expired.emit(self)
	queue_free()
