class_name Target
extends Area2D

## A single whack-a-mole target: pops up, waits to be hit, then expires on its own.

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
var _is_consumed: bool = false # guards against hit and expire firing in the same frame

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _lifetime_timer: Timer = $LifetimeTimer


## Called by the spawner right after instantiation, before the node enters the tree.
func setup(target_type: Type, target_radius: float, lifetime: float) -> void:
	type = target_type
	radius = target_radius
	_lifetime = lifetime


func _ready() -> void:
	# A fresh shape per instance keeps the radius independent
	# (trackpad mode will shrink targets by 20%).
	var circle := CircleShape2D.new()
	circle.radius = radius
	_collision.shape = circle

	_lifetime_timer.timeout.connect(_on_lifetime_timeout)
	_lifetime_timer.start(_lifetime)

	input_event.connect(_on_input_event)
	queue_redraw()


func _draw() -> void:
	# Placeholder visuals - sprites and effects come in a later phase.
	draw_circle(Vector2.ZERO, radius, COLORS[type])
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(0, 0, 0, 0.4), 3.0, true)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		consume_hit()


## Public entry point so trackpad mode (hover-hold) can trigger a hit as well.
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
