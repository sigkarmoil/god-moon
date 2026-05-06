extends Control

@onready var enemy_present_label: Label = $EnemyPresentLabel
@onready var start_prompt_label: Label = $StartPromptLabel

var _level: Node = null

func _ready() -> void:
	enemy_present_label.text = "debug_enemy is present"
	_level = get_parent()

#+++++++++++++++++++
# Preparation phase entry — called by the level when a new turn begins.
#+++++++++++++++++++
func enter_preparation_phase(turn_number: int) -> void:
	visible = true
	if _level:
		_level.current_battle_phase = "preparation"
		var p = _level.player
		if p and p.has_method("reset_for_turn"):
			p.reset_for_turn()
		var e = _level.current_enemy
		if e and e.has_method("reset_for_turn"):
			e.reset_for_turn()
	start_prompt_label.text = "Press space to start Turn " + str(turn_number)
	_set_player_animations_enabled(false)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_on_space_pressed()
			get_viewport().set_input_as_handled()

#+++++++++++++++++++
# Space pressed: hide menu, kick off enemy attack, and keep the player
# locked out for 0.5s so the same space press doesn't trigger an action.
#+++++++++++++++++++
func _on_space_pressed() -> void:
	visible = false
	if _level and _level.has_method("enter_enemy_attack_phase"):
		_level.enter_enemy_attack_phase()
	await get_tree().create_timer(0.1).timeout
	_set_player_animations_enabled(true)

func _set_player_animations_enabled(enabled: bool) -> void:
	if _level == null:
		return
	var p = _level.player
	if p:
		p.set_process(enabled)
