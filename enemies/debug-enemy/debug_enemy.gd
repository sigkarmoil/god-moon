extends CharacterBody2D

signal sequence_finished

#+++++++++++++++++++
#Animation Sets
#+++++++++++++++++++
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
#-------------------

#variable that holds the sequence
var queued_sequence: String

#+++++++++++++++++++++++++++++++
#Action Picking / Playing function
#+++++++++++++++++++++++++++++++
### For animation set 1
func turn_1_picker() -> void:
	var index := randi_range(0, animation_set1.size() - 1)
	queued_sequence = animation_set1[index]

### For animation set 2
func turn_2_picker() -> void:
	var index := randi_range(0, animation_set2.size() - 1)
	queued_sequence = animation_set1[index]

#### Action Playing Function
func play_sequence() -> void:
	$anim.play(queued_sequence)
	await $anim.animation_finished
	emit_signal("sequence_finished")

#----------------------------------------

#+++++++++++++++++++++++++++++++
#A set of functions to receive data from levels
#++++++++++++++++++++++++++++++++


#----------------------------------------
