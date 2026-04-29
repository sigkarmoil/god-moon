extends Node2D

#################
#Set of variables to pass
################
var turn_number = 1
var current_battle_phase: String = "preparation"

#+++++++++++++++++++
#Enemy loader , pick which enemy to pick
#+++++++++++++++++++
@onready var current_enemy = $debug_enemy
@onready var player := $debug_characters
@onready var preparation_menu := $Preparation_phase_menu

#--------------------


#
#On Ready: kick off the loop by entering the preparation phase
#
func _ready() -> void:
	## Pass enemy data to player. Useful to transmit attack type  ++
	assign_player()


	current_enemy.sequence_finished.connect(turn_number_increase)
	preparation_menu.enter_preparation_phase(turn_number)

func _process(delta: float) -> void:
	pass


#+++++++++++++++++++
#Function To Handle Enemy Attack Phase
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
# Turn number adder - called when enemy sequence finishes,
# then hands control back to the preparation menu.
#++++++++++++++++++++++++++++
func turn_number_increase() -> void:
	turn_number += 1
	preparation_menu.enter_preparation_phase(turn_number)


#++++++++++++++++
#+++++++++++++++
func assign_player() -> void:
	player.enemy = current_enemy
#--------------------
