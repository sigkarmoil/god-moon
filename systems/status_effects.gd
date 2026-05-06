extends Node

# Autoload singleton: StatusEffects
# Holds the registry of status effect classes and provides apply/tick helpers
# that operate on any target with an `active_effects` Dictionary and
# (optionally) an `effects_changed` signal.

##++++++++++++++ Base Status Effect Class 
class StatusEffect:
	var name: String = ""
	var explanation: String = ""
	var deplete_per_turn: int = 0
	var icon_small: String = ""

	func apply(target, quantity: int) -> void:
		var current: int = int(target.active_effects.get(name, 0))
		target.active_effects[name] = current + quantity

	func on_turn_start(_target) -> void:
		pass

	func on_turn_end(_target) -> void:
		pass

	func get_damage_received_multiplier(_target) -> float:
		return 1.0

	func get_damage_dealt_multiplier(_target) -> float:
		return 1.0

##--------------Base Status Effect Class 

## +++++++++++++ Library of Status Effects 

#### ++ StackReader: print the current Stack of effect
class StackReader extends StatusEffect:
	##### ++ X stacks of the StatusEffect
	func _init() -> void:
		name = "stack_reader"
		explanation = "Prints the current number of stacks."
		deplete_per_turn = 1
		icon_small = "res://resources/status_effects/stackreader.png"

##### ++ Method of Application
##### ++  Takes Effect On Apply: 
	func apply(target, quantity: int) -> void:
		super.apply(target, quantity)
		###### ++ Put The code of the effect here  
		print("[stack_reader] stacks: %d" % int(target.active_effects.get(name, 0)))


#### -- StackReader

#### ++ Burn: deals 1 damage at turn end per stack
class Burn extends StatusEffect:
	##### ++ X stacks of the StatusEffect
	func _init() -> void:
		name = "burn"
		explanation = "deals 1 damage at turn end per stack"
		deplete_per_turn = 1
		icon_small = "res://resources/status_effects/burn.png"

##### ++   Method of Application:
##### ++  End of Turn
	func on_turn_end(target) -> void:
		var stacks: int = int(target.active_effects.get(name, 0))
		if stacks <= 0:
			return
		if target.has_method("take_damage"):
			target.take_damage(stacks)

#### -- Burn

##----------------- Library of Status Effects 



##+++++++++++++++++++ Dispatcher function 
##Explanation: Always put the status in dispatcher, otherwise it will not be recognizable

var dispatcher: Dictionary = {
	"stack_reader": StackReader,
	"burn": Burn
}

##--------------- Dispatcher function 


##+++++++++++++++++++ Apply Effect Function
func apply_effect(effect_name: String, target, quantity: int) -> void:
	if not dispatcher.has(effect_name):
		push_warning("StatusEffects.apply_effect: unknown effect '%s'" % effect_name)
		return
	var cls = dispatcher[effect_name]
	var instance = cls.new()
	instance.apply(target, quantity)
	if target.has_signal("effects_changed"):
		target.emit_signal("effects_changed")
##------------------- Apply Effect Function

##+++++++++++++++++++ Tick Effects
## Explanation:  fires each effect's turn-end logic, 
## then counts down its stacks, removes it if it hits zero, and tells the UI to update.

func tick_effects(target) -> void:
	if target == null or not ("active_effects" in target):
		return
	for effect_name in target.active_effects.keys():
		if not dispatcher.has(effect_name):
			continue
		var cls = dispatcher[effect_name]
		var instance = cls.new()
		instance.on_turn_end(target)
		var current: int = int(target.active_effects.get(effect_name, 0))
		var new_val: int = current - instance.deplete_per_turn
		if new_val <= 0:
			target.active_effects.erase(effect_name)
		else:
			target.active_effects[effect_name] = new_val
	if target.has_signal("effects_changed"):
		target.emit_signal("effects_changed")
##------------------- Tick Effects


## +++++++++++++  Helper for UI: 
##Explanation: returns the small icon path for a registered effect.
func get_effect_icon(effect_name: String) -> String:
	if not dispatcher.has(effect_name):
		return ""
	var cls = dispatcher[effect_name]
	var instance = cls.new()
	return instance.icon_small
## ---------------  Helper for UI: 
