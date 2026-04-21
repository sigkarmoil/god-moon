extends CharacterBody2D

# Direct reference to the AnimationPlayer node named "anim" on this Player.
# This is the only way animations are played in this script.
@onready var anim: AnimationPlayer = $anim


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("parry"):
		anim.play("player_counter_parry")
	elif Input.is_action_just_pressed("dodge"):
		anim.play("player_counter_dodge")
	elif Input.is_action_just_pressed("use_relic"):
		anim.play("player_use_relic")
	elif not anim.is_playing():
		anim.play("player_idle")
