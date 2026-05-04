extends Node2D

#################
#Set of variables to pass
################
var turn_number = 1
var current_battle_phase: String = "preparation"
var _game_over: bool = false

const GAME_OVER_SCENE := preload("res://god-moon/background/level/game_over.tscn")
const STATUS_UI_SCENE := preload("res://god-moon/background/level/status_ui.tscn")

var status_ui

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
	if player.has_signal("player_defeated"):
		player.player_defeated.connect(_on_player_defeated)

	status_ui = STATUS_UI_SCENE.instantiate()
	add_child(status_ui)
	status_ui.bind(player, current_enemy)

	preparation_menu.enter_preparation_phase(turn_number)

func _process(delta: float) -> void:
	pass


#+++++++++++++++++++
#Function To Handle Enemy Attack Phase
#+++++++++++++++++++
func enter_enemy_attack_phase() -> void:
	if _game_over:
		return
	current_battle_phase = "enemy_attack"
	$Timer.start()


#+++++++++++++++++++++++
# Turn / Animation decider - tied to turn number
#++++++++++++++++++++++++
func _on_Timer_timeout() -> void:
	if _game_over:
		return
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
	if _game_over:
		return
	turn_number += 1
	# Wait until the player isn't mid-animation (vulnerable, take_damage, etc.)
	# before showing the preparation menu — per the "all anims finished" rule.
	await _wait_for_player_idle()
	# Re-check after the await — defeat may have triggered while we were waiting.
	if _game_over:
		return
	preparation_menu.enter_preparation_phase(turn_number)


#+++++++++++++++++++++++++++
# Game Over — instantiate the game_over scene and freeze game logic.
#++++++++++++++++++++++++++++
func _on_player_defeated() -> void:
	if _game_over:
		return
	_game_over = true
	current_battle_phase = "game_over"
	if preparation_menu:
		preparation_menu.visible = false
	var go = GAME_OVER_SCENE.instantiate()
	add_child(go)
	print("[level] GAME OVER")


func _wait_for_player_idle() -> void:
	var safety := 0
	while player.anim.is_playing() \
			and player.anim.current_animation != "player_idle" \
			and safety < 20:
		await player.anim.animation_finished
		safety += 1


#++++++++++++++++
#+++++++++++++++
func assign_player() -> void:
	player.enemy = current_enemy
#--------------------
