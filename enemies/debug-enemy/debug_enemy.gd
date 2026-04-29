extends CharacterBody2D

signal sequence_finished

#


#+++++++++++++++++++
#Animation Sets
#+++++++++++++++++++
# Set of animations to be used at turn 1
var animation_set1: Array[String] = [
	
	"multi_attack"
]

# Set of animations to be used at turn 2
var animation_set2: Array[String] = [
	
	"strong_attack"
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
	print("Odd turn loop")

### For animation set 2
func turn_2_picker() -> void:
	var index := randi_range(0, animation_set2.size() - 1)
	queued_sequence = animation_set2[index]
	print("Even turn loop")

#### Action Playing Function
func play_sequence() -> void:
	$anim.play(queued_sequence)
	await $anim.animation_finished
	emit_signal("sequence_finished")

#----------------------------------------

#+++++++++++++++++++++++++++++++
# Determine enemy attack type
#++++++++++++++++++++++++++++++++
var is_strong_attack: bool = false

func mark_strong_attack() -> void:
	is_strong_attack = true

func mark_regular_attack() -> void:
	is_strong_attack = false

#----------------------------------------


#+++++++++++++++++++++++++++++++++++++++++
#Enemy damage receival function
#-----------------------------------------
func _on_enemy_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("player_attack_area"): ##And attack type strong??
		print("Enemy got hit")

#-----------------------------------------
