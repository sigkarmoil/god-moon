extends Node2D

#################
#Set of variables to pass
################
var turn_number = 1
var turn_start: bool = false
var preparation_phase: bool = true
var enemy_defeated: bool = false
var game_over: bool = false

#################
#Enemy loader
#################
@onready var current_enemy = $debug_enemy

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	#Function to tell transmit "turn number" variable to a function within the scene of current enemy.
	current_enemy.receive_turn_number(turn_number)

	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
