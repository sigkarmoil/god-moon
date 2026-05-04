extends CharacterBody2D

signal player_defeated

# Direct reference to the AnimationPlayer node named "anim" on this Player.
# This is the only way animations are played in this script.
@onready var anim: AnimationPlayer = $anim

## Variable to allow extraction of enemy data.
var enemy: CharacterBody2D = null

# Animations that lock out all player input while playing.
const LOCKING_ANIMS: Array[String] = [
	"player_vulnerable",
	"player_take_damage",
	"player_defeated",
	"player_vicious_attack",
]

# Permanent lock once player_defeated has been triggered.
var _is_defeated: bool = false

const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://god-moon/background/level/damage_number.tscn")

#+++++++++++++++++++++++++
# Player stats
#+++++++++++++++++++++++++
var max_health: int = 15
var health: int = max_health
var stamina: int = max_stamina + player_stamina_modifier
var max_stamina: int = 4
var player_stamina_modifier: int = 0
var defense: int = 3
const DEFENSE_RESET_VALUE: int = 3

#+++++++++++++++++++++++++
# Player attack data
# { animation_name: { "stamina": cost, "damage": dmg } }
# Edit values here to tune attacks.
#+++++++++++++++++++++++++
var attack_data: Dictionary = {
	"player_counter_parry":  {"stamina": 1, "damage": 1},
	"player_counter_dodge":  {"stamina": 1, "damage": 1},
	"player_vicious_attack": {"stamina": 0, "damage": 3},
}

#+++++++++++++++++++++++++
# Vicious Attack — S+D held for 0.5s during enemy vulnerable window
#+++++++++++++++++++++++++
var vicious_hold_timer: float = 0.0
const VICIOUS_HOLD_TIME: float = 0.2


func _process(delta: float) -> void:
	if _is_defeated:
		return
	_update_vicious_input(delta)
	player_input()


#+++++++++++++++++++++++++
# Vicious input detection.
# Only accumulates while enemy is in "enemy_vulnerable" anim AND
# we're not already mid-vicious. Resets to 0 if either key released
# or window closes.
#+++++++++++++++++++++++++
func _update_vicious_input(delta: float) -> void:
	var window_open: bool = enemy != null \
		and enemy.anim.current_animation == "enemy_vulnerable" \
		and anim.current_animation != "player_vicious_attack"
	if not window_open:
		vicious_hold_timer = 0.0
		return
	var both_held: bool = Input.is_action_pressed("parry") and Input.is_action_pressed("dodge")
	if both_held:
		vicious_hold_timer += delta
		if vicious_hold_timer >= VICIOUS_HOLD_TIME:
			vicious_hold_timer = 0.0
			_trigger_vicious_attack()
	else:
		vicious_hold_timer = 0.0


#+++++++++++++++++++++++++
# Vicious trigger — plays the anim. Damage is applied by the enemy
# hurtbox detecting player_attack_area (same flow as counter_parry /
# counter_dodge), so the player_vicious_attack animation must enable
# the player_attack_area collision during its active frames.
# After the anim finishes, ask the enemy to end its vulnerable state
# so the turn can wrap up.
#+++++++++++++++++++++++++
func _trigger_vicious_attack() -> void:
	print("[player] VICIOUS attack triggered")
	anim.play("player_vicious_attack")
	var finished_anim = await anim.animation_finished
	if finished_anim == "player_vicious_attack" \
			and enemy != null and enemy.has_method("cut_vulnerable"):
		enemy.cut_vulnerable()


#+++++++++++++++++++++++++
# Turn-start reset — called by preparation phase menu.
#+++++++++++++++++++++++++
func reset_for_turn() -> void:
	stamina = max_stamina + player_stamina_modifier
	defense = DEFENSE_RESET_VALUE
	print("[player] turn reset — stamina=%d defense=%d hp=%d/%d"
		% [stamina, defense, health, max_health])


#+++++++++++++++++++++++++
# Player input
#+++++++++++++++++++++++++
func player_input():
	# Block all input while locked (vulnerable / take_damage / defeated / vicious).
	if _is_input_locked():
		return
	# Block parry/dodge during enemy vulnerable window — only vicious is allowed.
	var vulnerable_window: bool = enemy != null \
		and enemy.anim.current_animation == "enemy_vulnerable"
	if Input.is_action_just_pressed("parry") and not vulnerable_window:
		_try_play_attack("player_counter_parry")
	elif Input.is_action_just_pressed("dodge") and not vulnerable_window:
		_try_play_attack("player_counter_dodge")
	elif Input.is_action_just_pressed("use_relic"):
		# use_relic does NOT consume stamina
		anim.play("player_use_relic")
	elif not anim.is_playing():
		anim.play("player_idle")


func _is_input_locked() -> bool:
	if _is_defeated:
		return true
	return anim.current_animation in LOCKING_ANIMS and anim.is_playing()


#+++++++++++++++++++++++++
# Stamina-gated attack play.
# Blocks the input if stamina cost cannot be paid.
#+++++++++++++++++++++++++
func _try_play_attack(anim_name: String) -> void:
	var cost: int = int(attack_data.get(anim_name, {}).get("stamina", 0))
	if stamina < cost:
		print("[player] %s blocked — stamina %d < cost %d" % [anim_name, stamina, cost])
		return
	stamina -= cost
	print("[player] %s — stamina now %d" % [anim_name, stamina])
	anim.play(anim_name)

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
	# A hit while in player_vulnerable always lands and interrupts.
	if anim.current_animation == "player_vulnerable":
		_apply_enemy_damage()
		return
	if is_dodging:
		# dodge works against everything
		print("[player] dodged")
		return
	if is_parrying and enemy != null and not enemy.is_strong_attack:
		# parry only works against regular attacks
		print("[player] parried")
		return
	_apply_enemy_damage()


#+++++++++++++++++++++++++
# Apply enemy damage — looks up damage in enemy.action_data keyed
# by the enemy's currently playing animation. Decrements defense,
# then plays player_vulnerable (defense just hit 0) or player_take_damage.
# Triggers defeat when health reaches 0.
#+++++++++++++++++++++++++
func _apply_enemy_damage() -> void:
	if _is_defeated:
		return
	var dmg: int = 0
	if enemy != null:
		var enemy_anim: String = enemy.anim.current_animation
		dmg = int(enemy.action_data.get(enemy_anim, {}).get("damage", 0))
	if dmg <= 0:
		return
	health = max(0, health - dmg)
	_spawn_damage_number(dmg, Color.RED)
	print("[player] took %d damage — hp=%d/%d defense=%d"
		% [dmg, health, max_health, defense])

	if health <= 0:
		_trigger_defeat()
		return

	# Clear stale parry/dodge flags — the take_damage / vulnerable
	# anim doesn't have a method track to call mark_neutral.
	mark_neutral()

	if defense > 0:
		defense -= 1
		if defense == 0:
			print("[player] defense broken — entering player_vulnerable")
			anim.play("player_vulnerable")
		else:
			anim.play("player_take_damage")
	else:
		# Already broken — interrupts player_vulnerable if mid-anim.
		anim.play("player_take_damage")


#+++++++++++++++++++++++++
# Spawn a floating damage number at the player's position.
# Spawned as a child of the level so it's not affected by the
# player's own transform / queue_free.
#+++++++++++++++++++++++++
func _spawn_damage_number(amount: int, color: Color) -> void:
	var dn := DAMAGE_NUMBER_SCENE.instantiate()
	get_parent().add_child(dn)
	dn.global_position = global_position
	dn.setup(amount, color, false)


#+++++++++++++++++++++++++
# Lock the player out of any further input / animation triggers,
# without playing the defeated anim. Called by the level when the
# enemy is defeated (player wins).
#+++++++++++++++++++++++++
func freeze() -> void:
	_is_defeated = true


#+++++++++++++++++++++++++
# Defeat — plays anim, locks input permanently, then emits signal
# for the level to handle (Game Over).
#+++++++++++++++++++++++++
func _trigger_defeat() -> void:
	_is_defeated = true
	print("[player] DEFEATED")
	anim.play("player_defeated")
	var finished = await anim.animation_finished
	if finished == "player_defeated":
		emit_signal("player_defeated")


	## Player damage receival +++

func _on_player_hurtbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemy_attack"):
		resolve_hit()

#---------------------------
