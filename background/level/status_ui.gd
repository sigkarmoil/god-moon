extends CanvasLayer

@onready var player_label: Label = $PlayerStatus
@onready var enemy_label: Label = $EnemyStatus

var player: Node = null
var enemy: Node = null


func bind(p: Node, e: Node) -> void:
	player = p
	enemy = e


func _process(_delta: float) -> void:
	if player != null and is_instance_valid(player):
		player_label.text = "HP: %d / %d\nStamina: %d\nDefense: %d" % [
			player.health, player.max_health, player.stamina, player.defense
		]
	if enemy != null and is_instance_valid(enemy):
		enemy_label.text = "HP: %d / %d\nStamina: %d" % [
			enemy.health, enemy.max_health, enemy.stamina
		]
