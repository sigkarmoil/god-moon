extends CharacterBody2D

# Direct reference to the AnimationPlayer node named "anim" on this Player.
# This is the only way animations are played in this script.
@onready var anim: AnimationPlayer = $anim

## Variable to allow extraction of enemy data.
var enemy: CharacterBody2D = null



func _process(_delta: float) -> void:
	player_input()


#+++++++++++++++++++++++++
# Player input
#+++++++++++++++++++++++++
func player_input():
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

	## Call Method Track - Function to differentiate parry vs dodge, called at Animation Player +++
var is_parrying: bool = false
var is_dodging: bool = false

func mark_parrying() -> void:
	is_parrying = true
	is_dodging = false
	print (is_parrying)

func mark_dodging() -> void:
	is_dodging = true
	is_parrying = false

	## On every action, remember to call neutral after every action.
func mark_neutral() -> void:
	is_parrying = false
	is_dodging = false
	## ---

	## Conditional logic to resolve hit +++
func resolve_hit() -> void:
	if is_dodging == true:
		# dodge works against everything
		print("Player dodged")
		pass
	elif is_parrying == true and enemy.is_strong_attack == false:
		# parry only works against regular attacks
		print("Player parried")
		pass
	else:
		# player takes damage
		print ("Player takes damage")

	##---

	## Player damage receival +++

func _on_player_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_attack"):
		#print ("player takes damage")
		resolve_hit()

#---------------------------
