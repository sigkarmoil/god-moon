extends Control

signal space_pressed

@onready var _label: Label = $Label

func set_turn_number(n: int) -> void:
	if _label == null:
		_label = $Label
	_label.text = "Press space to start Turn " + str(n)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			emit_signal("space_pressed")
			get_viewport().set_input_as_handled()
