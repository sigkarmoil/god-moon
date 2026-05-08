extends Control

signal prep_confirmed(slot_assignments: Array)

@onready var enemy_name_label: Label = $TopSection/EnemyNameLabel
@onready var enemy_description_label: Label = $TopSection/EnemyDescriptionLabel
@onready var enemy_effects_row: HBoxContainer = $TopSection/EnemyEffectsRow
@onready var effect_tooltip_popup: PanelContainer = $EffectTooltipPopup
@onready var effect_tooltip_name_label: Label = $EffectTooltipPopup/TooltipBox/EffectTooltipNameLabel
@onready var effect_tooltip_explanation_label: Label = $EffectTooltipPopup/TooltipBox/EffectTooltipExplanationLabel
@onready var start_prompt_label: Label = $StartPromptLabel
@onready var relic_info_popup: PopupPanel = $RelicInfoPopup
@onready var relic_artwork: TextureRect = $RelicInfoPopup/RelicInfoBox/RelicArtwork
@onready var relic_description_label: Label = $RelicInfoPopup/RelicInfoBox/RelicDescriptionLabel

# PLACEHOLDER artwork path for relic info popup — replace when real art exists
const PLACEHOLDER_RELIC_ARTWORK: String = "res://resources/relics/stackreader.png"

@onready var _slot_panels: Array = [
	$RelicSlotsRow/Slot1,
	$RelicSlotsRow/Slot2,
	$RelicSlotsRow/Slot3,
]
@onready var _slot_labels: Array = [
	$RelicSlotsRow/Slot1/Slot1Box/Slot1Label,
	$RelicSlotsRow/Slot2/Slot2Box/Slot2Label,
	$RelicSlotsRow/Slot3/Slot3Box/Slot3Label,
]
@onready var _slot_icons: Array = [
	$RelicSlotsRow/Slot1/Slot1Box/Slot1Icon,
	$RelicSlotsRow/Slot2/Slot2Box/Slot2Icon,
	$RelicSlotsRow/Slot3/Slot3Box/Slot3Icon,
]
@onready var background_dimmer: ColorRect = $BackgroundDimmer
@onready var _slot_arrow_rows: Array = [
	$RelicSlotsRow/Slot1/Slot1Box/Slot1Arrows,
	$RelicSlotsRow/Slot2/Slot2Box/Slot2Arrows,
	$RelicSlotsRow/Slot3/Slot3Box/Slot3Arrows,
]
@onready var _slot_left_buttons: Array = [
	$RelicSlotsRow/Slot1/Slot1Box/Slot1Arrows/Slot1Left,
	$RelicSlotsRow/Slot2/Slot2Box/Slot2Arrows/Slot2Left,
	$RelicSlotsRow/Slot3/Slot3Box/Slot3Arrows/Slot3Left,
]
@onready var _slot_right_buttons: Array = [
	$RelicSlotsRow/Slot1/Slot1Box/Slot1Arrows/Slot1Right,
	$RelicSlotsRow/Slot2/Slot2Box/Slot2Arrows/Slot2Right,
	$RelicSlotsRow/Slot3/Slot3Box/Slot3Arrows/Slot3Right,
]

var _level: Node = null
var _bound_enemy: Node = null
var _slot_assignments: Array = [null, null, null]

func _ready() -> void:
	_level = get_parent()
	effect_tooltip_popup.hide()
	background_dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background_dimmer.hide()
	relic_info_popup.popup_hide.connect(_on_relic_info_popup_hide)
	for i in range(3):
		_slot_left_buttons[i].pressed.connect(_on_slot_left_pressed.bind(i))
		_slot_right_buttons[i].pressed.connect(_on_slot_right_pressed.bind(i))
		_slot_panels[i].mouse_filter = Control.MOUSE_FILTER_STOP
		_slot_panels[i].gui_input.connect(_on_slot_gui_input.bind(i))

#+++++++++++++++++++
# Preparation phase entry — called by the level when a new turn begins.
#+++++++++++++++++++
func enter_preparation_phase(turn_number: int) -> void:
	visible = true
	if _level:
		_level.current_battle_phase = "preparation"
		var p = _level.player
		if p and p.has_method("reset_for_turn"):
			p.reset_for_turn()
		var e = _level.current_enemy
		if e and e.has_method("reset_for_turn"):
			e.reset_for_turn()
		_bind_enemy(e)
	_refresh_slots()
	start_prompt_label.text = "Press space to start Turn " + str(turn_number)
	_set_player_animations_enabled(false)

func _bind_enemy(e: Node) -> void:
	if e == null:
		return
	enemy_name_label.text = str(e.get("enemy_name"))
	enemy_description_label.text = str(e.get("enemy_description"))
	if e != _bound_enemy:
		if _bound_enemy != null and _bound_enemy.has_signal("effects_changed") \
				and _bound_enemy.effects_changed.is_connected(_rebuild_enemy_effects_row):
			_bound_enemy.effects_changed.disconnect(_rebuild_enemy_effects_row)
		if e.has_signal("effects_changed"):
			e.effects_changed.connect(_rebuild_enemy_effects_row)
		_bound_enemy = e
	_rebuild_enemy_effects_row()

#+++++++++++++++++++
# Build one small label per active enemy status effect, with hover popup
# showing the effect's explanation. If none are active, the row is empty.
#+++++++++++++++++++
func _rebuild_enemy_effects_row() -> void:
	for child in enemy_effects_row.get_children():
		child.queue_free()
	if _bound_enemy == null or not is_instance_valid(_bound_enemy):
		return
	if not ("active_effects" in _bound_enemy):
		return
	for effect_name in _bound_enemy.active_effects.keys():
		var stacks: int = int(_bound_enemy.active_effects[effect_name])
		var data: Dictionary = _get_effect_data(effect_name)
		var entry := HBoxContainer.new()
		entry.mouse_filter = Control.MOUSE_FILTER_STOP
		var icon_path: String = String(data.get("icon", ""))
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var tex := TextureRect.new()
			tex.texture = load(icon_path)
			tex.custom_minimum_size = Vector2(24, 24)
			tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
			entry.add_child(tex)
		var stack_label := Label.new()
		stack_label.text = " x%d" % stacks
		stack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		entry.add_child(stack_label)
		entry.mouse_entered.connect(
			_on_effect_hover_in.bind(entry, String(data.get("name", effect_name)), String(data.get("explanation", "")))
		)
		entry.mouse_exited.connect(_on_effect_hover_out)
		enemy_effects_row.add_child(entry)

func _get_effect_data(effect_name: String) -> Dictionary:
	if not StatusEffects.dispatcher.has(effect_name):
		return {}
	var cls = StatusEffects.dispatcher[effect_name]
	var instance = cls.new()
	return {
		"name": instance.name,
		"explanation": instance.explanation,
		"icon": instance.icon_small,
	}

func _on_effect_hover_in(entry: Control, effect_display_name: String, explanation: String) -> void:
	effect_tooltip_name_label.text = effect_display_name
	effect_tooltip_explanation_label.text = explanation
	effect_tooltip_popup.reset_size()
	effect_tooltip_popup.global_position = entry.global_position + Vector2(0, entry.size.y + 4)
	effect_tooltip_popup.show()

func _on_effect_hover_out() -> void:
	effect_tooltip_popup.hide()

#+++++++++++++++++++
# Refresh all three relic slots based on current godhood level
# and current selections. Slots above godhood level are locked.
#+++++++++++++++++++
func _refresh_slots() -> void:
	var godhood_level: int = _get_godhood_level()
	for i in range(3):
		var slot_number: int = i + 1
		var unlocked: bool = godhood_level >= slot_number
		_slot_arrow_rows[i].visible = unlocked
		if not unlocked:
			_slot_assignments[i] = null
			_slot_labels[i].text = "Locked at Godhood Level %d" % slot_number
			_set_slot_icon(i, null)
			continue
		_slot_labels[i].text = _get_slot_display_text(i)
		_set_slot_icon(i, _slot_assignments[i])

func _get_slot_display_text(slot_idx: int) -> String:
	var assigned = _slot_assignments[slot_idx]
	if assigned == null:
		return "Empty"
	return str(assigned.name)

func _set_slot_icon(slot_idx: int, relic) -> void:
	if relic == null:
		_slot_icons[slot_idx].texture = null
		return
	var icon_path: String = String(relic.icon_small)
	if icon_path != "" and ResourceLoader.exists(icon_path):
		_slot_icons[slot_idx].texture = load(icon_path)
	else:
		_slot_icons[slot_idx].texture = null

func _get_godhood_level() -> int:
	if _level == null or _level.player == null:
		return 1
	return int(_level.player.get("godhood_level"))

func _get_eligible_relics(slot_idx: int) -> Array:
	var slot_tier: int = slot_idx + 1
	var result: Array = []
	if _level == null or _level.player == null:
		return result
	var inventory = _level.player.get("owned_relics")
	if inventory == null:
		return result
	for relic in inventory:
		if relic == null:
			continue
		if int(relic.godhood_requirement) == slot_tier:
			result.append(relic)
	return result

func _cycle_slot(slot_idx: int, step: int) -> void:
	var eligible: Array = _get_eligible_relics(slot_idx)
	if eligible.is_empty():
		return
	var current = _slot_assignments[slot_idx]
	var current_idx: int = -1
	if current != null:
		current_idx = eligible.find(current)
	var next_idx: int
	if current_idx == -1:
		next_idx = 0 if step > 0 else eligible.size() - 1
	else:
		next_idx = (current_idx + step) % eligible.size()
		if next_idx < 0:
			next_idx += eligible.size()
	_slot_assignments[slot_idx] = eligible[next_idx]
	_slot_labels[slot_idx].text = _get_slot_display_text(slot_idx)
	_set_slot_icon(slot_idx, _slot_assignments[slot_idx])

func _on_slot_left_pressed(slot_idx: int) -> void:
	_cycle_slot(slot_idx, -1)

func _on_slot_right_pressed(slot_idx: int) -> void:
	_cycle_slot(slot_idx, 1)

#+++++++++++++++++++
# Right-click on a slot: open the relic info popup if the slot is
# unlocked AND has a relic assigned. PopupPanel auto-closes on outside click.
#+++++++++++++++++++
func _on_slot_gui_input(event: InputEvent, slot_idx: int) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed:
		return
	if event.button_index != MOUSE_BUTTON_RIGHT:
		return
	var godhood_level: int = _get_godhood_level()
	if godhood_level < slot_idx + 1:
		return
	var assigned = _slot_assignments[slot_idx]
	if assigned == null:
		return
	_open_relic_info_popup(assigned)

func _open_relic_info_popup(relic) -> void:
	var artwork_path: String = String(relic.icon_on_acquire)
	if artwork_path == "" or not ResourceLoader.exists(artwork_path):
		artwork_path = PLACEHOLDER_RELIC_ARTWORK
	if ResourceLoader.exists(artwork_path):
		relic_artwork.texture = load(artwork_path)
	else:
		relic_artwork.texture = null
	relic_description_label.text = String(relic.description)
	background_dimmer.show()
	relic_info_popup.popup_centered()

func _on_relic_info_popup_hide() -> void:
	background_dimmer.hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE:
			_on_space_pressed()
			get_viewport().set_input_as_handled()

#+++++++++++++++++++
# Space pressed: hide menu, kick off enemy attack, and keep the player
# locked out for X seconds so the same space press doesn't trigger an action.
#+++++++++++++++++++
func _on_space_pressed() -> void:
	visible = false
	effect_tooltip_popup.hide()
	emit_signal("prep_confirmed", _slot_assignments.duplicate())
	await get_tree().create_timer(0.1).timeout
	_set_player_animations_enabled(true)

func _set_player_animations_enabled(enabled: bool) -> void:
	if _level == null:
		return
	var p = _level.player
	if p:
		p.set_process(enabled)
