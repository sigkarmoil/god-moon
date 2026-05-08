extends CanvasLayer

@onready var player_label: Label = $PlayerStatus
@onready var enemy_label: Label = $EnemyStatus
@onready var gaib_label: Label = $GaibLabel
@onready var godhood_label: Label = $GodhoodLabel
@onready var player_effects_row: HBoxContainer = $PlayerEffectsRow
@onready var enemy_effects_row: HBoxContainer = $EnemyEffectsRow

var player: Node = null
var enemy: Node = null


func bind(p: Node, e: Node) -> void:
	player = p
	enemy = e
	if player.has_signal("gaib_changed"):
		player.gaib_changed.connect(_update_gaib_label)
	if player.has_signal("effects_changed"):
		player.effects_changed.connect(_rebuild_player_effects)
	if enemy.has_signal("effects_changed"):
		enemy.effects_changed.connect(_rebuild_enemy_effects)
	_update_gaib_label()
	_rebuild_player_effects()
	_rebuild_enemy_effects()


func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		player_label.text = "HP: %d / %d\nStamina: %d\nDefense: %d" % [
			player.health, player.max_health, player.stamina, player.defense
		]
		godhood_label.text = "Godhood: Lv %d  (%d / %d)" % [
			player.godhood_level, player.godhood_meter, player.GODHOOD_METER_MAX
		]
	if enemy != null and is_instance_valid(enemy):
		enemy_label.text = "HP: %d / %d\nStamina: %d" % [
			enemy.health, enemy.max_health, enemy.stamina
		]


func _update_gaib_label() -> void:
	if player == null or not is_instance_valid(player):
		return
	gaib_label.text = "Ga'ib: %d" % int(player.gaib)


func _rebuild_player_effects() -> void:
	_rebuild_effects_row(player_effects_row, player)


func _rebuild_enemy_effects() -> void:
	_rebuild_effects_row(enemy_effects_row, enemy)


func _rebuild_effects_row(row: HBoxContainer, target: Node) -> void:
	for child in row.get_children():
		child.queue_free()
	if target == null or not is_instance_valid(target):
		return
	for effect_name in target.active_effects.keys():
		var entry := HBoxContainer.new()
		var icon_path: String = StatusEffects.get_effect_icon(effect_name)
		if icon_path != "" and ResourceLoader.exists(icon_path):
			var tex := TextureRect.new()
			tex.texture = load(icon_path)
			tex.custom_minimum_size = Vector2(24, 24)
			tex.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			entry.add_child(tex)
		var lbl := Label.new()
		lbl.text = " x%d" % int(target.active_effects[effect_name])
		entry.add_child(lbl)
		row.add_child(entry)
