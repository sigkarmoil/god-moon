extends State

class_name IdleState

func enter():
	print("Player at idle state")
	
func handle_input(event: InputEvent):
	if Input.is_action_pressed("parry"):
		state_machine.change_state("player_counter_parry")
	elif Input.is_action_pressed("dodge"):
		state_machine.change_state("player_counter_dodge")
	elif Input.is_action_pressed("use_relic"):
		state_machine.change_state("player_use_relic")
		
	
