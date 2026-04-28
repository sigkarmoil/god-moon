extends CharacterBody2D

# Direct reference to the AnimationPlayer node named "anim" on this Player.
# This is the only way animations are played in this script.
@onready var anim: AnimationPlayer = $anim

## Variable to allow extraction of enemy data.
var enemy: CharacterBody2D = null


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("parry"):
		anim.play("player_counter_parry")
	elif Input.is_action_just_pressed("dodge"):
		anim.play("player_counter_dodge")
	elif Input.is_action_just_pressed("use_relic"):
		anim.play("player_use_relic")
	elif not anim.is_playing():
		anim.play("player_idle")


#+++++++++++++++++++++++++
# Player damage recognition system
#+++++++++++++++++++++++++

## Function to mark parry vs dodge +++
var is_parrying: bool = false
var is_dodging: bool = false

func mark_parrying() -> void:
	is_parrying = true
	is_dodging = false

func mark_dodging() -> void:
	is_dodging = true
	is_parrying = false

func mark_neutral() -> void:
	is_parrying = false
	is_dodging = false
## ---

## Conditional logic to resolve hit
func resolve_hit() -> void:
	if is_dodging == true:
		# dodge works against everything
		pass
	elif is_parrying == true and enemy.is_strong_attack == false:
		# parry only works against regular attacks
		pass
	else:
		# player takes damage
		print ("Player takes damage")

#----------
