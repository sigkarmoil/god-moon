extends CharacterBody2D

var animations: Array = [
	"multi_attack",
    "strong_attack"
]

@export var pause_duration: float = 1.0

func _on_Timer_timeout() -> void:
	await play_sequence(3)
	await get_tree().create_timer(pause_duration).timeout
	$Timer.start()

func play_sequence(count: int):
	var pool = animations.duplicate()
	pool.shuffle()
	var selected = pool.slice(0, count)

	for anim in selected:
		$AnimationPlayer.play(anim)
		await $AnimationPlayer.animation_finished
