extends Node2D

const PreparationPhaseMenu := preload("res://god-moon/background/level/preparation_phase_menu.tscn")

#################
#Set of variables to pass
################
var turn_number = 1
var current_battle_phase: String = "preparation"
var _menu_instance: Node = null

#+++++++++++++++++++
#Enemy loader , pick which enemy to pick
#+++++++++++++++++++
@onready var current_enemy = $debug_enemy

#--------------------


#
#On Ready: set animation to finished
#
func _ready() -> void:
	current_enemy.sequence_finished.connect(turn_number_increase)
	enter_preparation_phase()

func _process(delta: float) -> void:
	pass


#+++++++++++++++++++
#Function To Handle Preparation Phase Menu
#+++++++++++++++++++
## Preparation Menu Pop Up
func enter_preparation_phase() -> void:
	current_battle_phase = "preparation"
	_menu_instance = PreparationPhaseMenu.instantiate()
	add_child(_menu_instance)
	_menu_instance.set_turn_number(turn_number)
	_menu_instance.space_pressed.connect(_on_space_pressed)

## Start Battle Phase
func _on_space_pressed() -> void:
	if _menu_instance != null:
		_menu_instance.queue_free()
		_menu_instance = null
	enter_enemy_attack_phase()

#----------------------

#+++++++++++++++++++
#Function To Handle Preparation Phase Menu
#+++++++++++++++++++
func enter_enemy_attack_phase() -> void:
	current_battle_phase = "enemy_attack"
	$Timer.start()


#+++++++++++++++++++++++
# Turn / Animation decider - tied to turn number
#++++++++++++++++++++++++
func _on_Timer_timeout() -> void:
	if turn_number % 2 == 1:
		current_enemy.turn_1_picker()
	else:
		current_enemy.turn_2_picker()
	current_enemy.play_sequence()
#----------------------------

#+++++++++++++++++++++++++++
# Turn number adder
#++++++++++++++++++++++++++++
func turn_number_increase() -> void:
	turn_number += 1
	enter_preparation_phase()
