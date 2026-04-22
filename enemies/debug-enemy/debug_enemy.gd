extends CharacterBody2D

# Add new animation names here to include them in the random pool.
var animations: Array[String] = [
	"strong_attack",
	"multi_attack",
]

#length of animation
const SEQUENCE_LENGTH: int = 1

var queued_sequence: Array[String] = []

func _ready() -> void:
	queued_sequence = build_sequence(SEQUENCE_LENGTH)
	$Timer.start()

func _on_timer_timeout() -> void:
	await play_sequence(queued_sequence)
	queued_sequence = build_sequence(SEQUENCE_LENGTH)
	$Timer.start()

func build_sequence(count: int) -> Array[String]:
	var pool := animations.duplicate()
	pool.shuffle()
	var sequence: Array[String] = []
	for i in count:
		sequence.append(pool[i % pool.size()])
	return sequence

func play_sequence(sequence: Array[String]) -> void:
	for anim: String in sequence:
		$anim.play(anim)
		await $anim.animation_finished
