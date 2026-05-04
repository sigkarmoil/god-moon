extends CharacterBody2D

signal sequence_finished
signal enemy_vulnerable_started
signal enemy_defeated

@onready var anim: AnimationPlayer = $anim

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://god-moon/background/level/damage_number.tscn")

#+++++++++++++++++++++++++
# Enemy stats
#+++++++++++++++++++++++++
var max_health: int = 10
var health: int = max_health 
var stamina: int = 3
var max_stamina: int = 3
var vulnerable_threshold: int = 3
const VULNERABLE_THRESHOLD_RESET: int = 3

#+++++++++++++++++++++++++
# Action data
# { animation_name: { "stamina": cost, "damage": dmg } }
# Edit values here to tune actions.
#+++++++++++++++++++++++++
var action_data: Dictionary = {
	"multi_attack":  {"stamina": 1, "damage": 1},
	"strong_attack": {"stamina": 2, "damage": 2},
}

#+++++++++++++++++++++++++
# Per-turn allowed action pools
#+++++++++++++++++++++++++
var animation_set1: Array[String] = ["multi_attack"]
var animation_set2: Array[String] = ["strong_attack"]

# Picked queue for current turn (filled by turn_*_picker)
var queued_actions: Array[String] = []

# Vulnerable / interrupt flags
var _interrupted: bool = false
var _vulnerable_active: bool = false

#+++++++++++++++++++++++++
# Attack type tracking — driven by animation method tracks
#+++++++++++++++++++++++++
var is_strong_attack: bool = false

func mark_strong_attack() -> void:
	is_strong_attack = true

func mark_regular_attack() -> void:
	is_strong_attack = false

#+++++++++++++++++++++++++
# Turn-start reset (called by preparation phase menu).
# vulnerable_threshold is intentionally NOT reset here — it only resets
# after the "enemy_vulnerable" animation finishes.
#+++++++++++++++++++++++++
func reset_for_turn() -> void:
	stamina = max_stamina
	# Force idle so a leftover enemy_vulnerable / interrupted action
	# pose isn't visible during the next preparation phase.
	anim.play("idle")
	print("[enemy] turn reset — stamina=%d hp=%d/%d threshold=%d"
		% [stamina, health, max_health, vulnerable_threshold])

#+++++++++++++++++++++++++
# Turn pickers — fill the stamina budget with affordable actions
# from the per-turn pool.
#+++++++++++++++++++++++++
func turn_1_picker() -> void:
	queued_actions = _pick_actions(animation_set1)
	print("[enemy] turn 1 queue: %s" % str(queued_actions))

func turn_2_picker() -> void:
	queued_actions = _pick_actions(animation_set2)
	print("[enemy] turn 2 queue: %s" % str(queued_actions))

func _pick_actions(allowed: Array[String]) -> Array[String]:
	var picked: Array[String] = []
	var budget: int = stamina
	var safety: int = 0
	while budget > 0 and safety < 50:
		var affordable: Array[String] = []
		for name: String in allowed:
			if int(action_data[name]["stamina"]) <= budget:
				affordable.append(name)
		if affordable.is_empty():
			break
		var pick: String = affordable[randi_range(0, affordable.size() - 1)]
		picked.append(pick)
		budget -= int(action_data[pick]["stamina"])
		safety += 1
	return picked

#+++++++++++++++++++++++++
# Play queued actions, decrementing stamina as each plays.
# If vulnerable triggers mid-sequence the current animation is
# interrupted by "enemy_vulnerable" and the rest of the queue is dropped.
#+++++++++++++++++++++++++
func play_sequence() -> void:
	_interrupted = false
	_vulnerable_active = false
	for action: String in queued_actions:
		if _interrupted:
			break
		var cost: int = int(action_data[action]["stamina"])
		if stamina < cost:
			break
		stamina -= cost
		print("[enemy] play %s — stamina now %d" % [action, stamina])
		anim.play(action)
		await anim.animation_finished

	if _vulnerable_active:
		# The await above completed when enemy_vulnerable finished playing.
		vulnerable_threshold = VULNERABLE_THRESHOLD_RESET
		_vulnerable_active = false
		print("[enemy] vulnerable ended — threshold reset to %d" % vulnerable_threshold)

	emit_signal("sequence_finished")

#+++++++++++++++++++++++++
# Damage receival.
# Reads damage from the player's attack_data dictionary, keyed by
# the player's currently playing animation.
#+++++++++++++++++++++++++
func _on_enemy_hurtbox_area_entered(area: Area2D) -> void:
	if not area.is_in_group("player_attack_area"):
		return
	var player_node = area.get_parent()
	if player_node == null:
		return
	var current_anim: String = player_node.anim.current_animation
	var dmg: int = int(player_node.attack_data.get(current_anim, {}).get("damage", 0))
	take_damage(dmg)

func take_damage(amount: int) -> void:
	if amount <= 0:
		return
	health = max(0, health - amount)
	_spawn_damage_number(amount, Color.ORANGE)
	print("[enemy] took %d damage — hp=%d/%d threshold=%d"
		% [amount, health, max_health, vulnerable_threshold])
	if health <= 0:
		trigger_defeat()
		return
	vulnerable_threshold -= amount
	if vulnerable_threshold <= 0 and not _vulnerable_active:
		_trigger_vulnerable()


#+++++++++++++++++++++++++
# Defeat — plays "enemy_defeated" and emits enemy_defeated after the
# anim finishes. Sets _interrupted so any in-flight play_sequence loop
# breaks out instead of stepping to the next queued action.
#+++++++++++++++++++++++++
func trigger_defeat() -> void:
	_interrupted = true
	_vulnerable_active = false
	anim.animation_finished.connect(_on_anim_finished_for_defeat, CONNECT_ONE_SHOT)
	anim.play("enemy_defeated")
	print("[enemy] DEFEATED")


func _on_anim_finished_for_defeat(anim_name: StringName) -> void:
	if anim_name == "enemy_defeated":
		emit_signal("enemy_defeated")


#+++++++++++++++++++++++++
# Spawn a floating damage number at the enemy's position.
# Uses the arc variant (rise then slight dip) per spec.
#+++++++++++++++++++++++++
func _spawn_damage_number(amount: int, color: Color) -> void:
	var dn := DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dn)
	dn.global_position = global_position
	dn.setup(amount, color, true)

func _trigger_vulnerable() -> void:
	_interrupted = true
	_vulnerable_active = true
	anim.stop()
	anim.play("enemy_vulnerable")
	emit_signal("enemy_vulnerable_started")
	print("[enemy] VULNERABLE triggered")

#+++++++++++++++++++++++++
# End the vulnerable window early — called by the player after a successful
# vicious_attack. Resets threshold, clears the vulnerable flag, and forces
# the awaiting play_sequence() to unblock by playing the tiny RESET anim
# (anim.stop() alone does not emit animation_finished).
#+++++++++++++++++++++++++
func cut_vulnerable() -> void:
	if not _vulnerable_active:
		return
	vulnerable_threshold = VULNERABLE_THRESHOLD_RESET
	_vulnerable_active = false
	print("[enemy] vulnerable cut short by vicious — threshold reset to %d"
		% vulnerable_threshold)
	anim.play("RESET")
