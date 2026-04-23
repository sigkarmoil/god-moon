extends CharacterBody2D

# Set of animations to be used at turn 1
var animation_set1: Array[String] = [
	"strong_attack",
	"multi_attack",
]

# Set of animations to be used at turn 2
var animation_set2: Array[String] = [
	"strong_attack",
	"multi_attack",
]

#length of animation
#variable that holds the sequence. Simplify later
const SEQUENCE_LENGTH: int = 1
var queued_sequence: Array[String] = []

#Success: this function is called by the level gdscript during test
#func level_signal() -> void:
	#print("level signal")

func _ready() -> void:
	$Timer.start()

##
#Animation loader
##
#Wait for timer to timeout.
#load an animation set using play_sequence
#When the timer runs out, play the sequence

func _on_timer_timeout() -> void:
	queued_sequence = turn_1_picker(SEQUENCE_LENGTH)
	await play_sequence(queued_sequence)

###
#A set of functions to receive data from levels
###
	#Function to receive the turn number from level. Determine the set of animation to perform
func receive_turn_number(value: int) -> void:
	print("Turn Number: ", value)
	
	#Function to see whether the preparation phase is starting or not
	#Function to see whether the battle phase is starting or not

###
#Action Picking function
###
func turn_1_picker(count: int) -> Array[String]:
	var pool := animation_set1.duplicate()
	pool.shuffle()
	var sequence: Array[String] = []
	for i in count:
		sequence.append(pool[i % pool.size()])
	return sequence

func play_sequence(sequence: Array[String]) -> void:
	for anim: String in sequence:
		$anim.play(anim)
		await $anim.animation_finished
