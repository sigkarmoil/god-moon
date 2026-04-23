extends Node

class_name State

# Reference to the state machine
var state_machine: StateMachine

# Virtual methods that child states can override

# Enter is for initialization
func enter():
	pass

#Exit is for clean up
func exit():
	pass

#Update for frame logic - handles movement 
func update (delta:float):
	pass


#Physics update handles movement
func physics_update (delta:float):
	pass

#Handles Input for player input
func handle_input(event:InputEvent):
	pass
