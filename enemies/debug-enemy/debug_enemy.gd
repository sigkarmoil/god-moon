extends CharacterBody2D

var attack_variant: int

func _ready() -> void:
	$AnimationPlayer.play("idle")
	
func _physics_process(delta: float) -> void:
	pass


func _on_timer_timeout() -> void:
	$AnimationPlayer.play("multi_attack")
