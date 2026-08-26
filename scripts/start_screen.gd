class_name StartScreen
extends Control

## Lets the player pick a control scheme and starts the round.

signal start_requested(mode: InputMode.Mode)

@onready var _mouse_button: Button = $Center/Panel/Rows/MouseButton
@onready var _trackpad_button: Button = $Center/Panel/Rows/TrackpadButton


func _ready() -> void:
	_mouse_button.pressed.connect(func() -> void: start_requested.emit(InputMode.Mode.MOUSE))
	_trackpad_button.pressed.connect(func() -> void: start_requested.emit(InputMode.Mode.TRACKPAD))
