class_name PauseScreen
extends Control

## Handles the pause toggle and runs while the tree is paused.

signal menu_requested

## Set by Main - pausing only makes sense while a round is running.
var can_pause: bool = false

@onready var _resume_button: Button = $Center/Panel/Rows/ResumeButton
@onready var _menu_button: Button = $Center/Panel/Rows/MenuButton


func _ready() -> void:
	# Without this the screen would freeze along with everything else
	# and could never unpause itself again.
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	_resume_button.pressed.connect(_resume)
	_menu_button.pressed.connect(_on_menu_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	if get_tree().paused:
		_resume()
	elif can_pause:
		_pause()
	else:
		return

	get_viewport().set_input_as_handled()


func _pause() -> void:
	get_tree().paused = true
	show()


func _resume() -> void:
	get_tree().paused = false
	hide()


func _on_menu_pressed() -> void:
	_resume() # unpause first, the menu has to be interactive
	menu_requested.emit()
