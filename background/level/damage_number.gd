extends Node2D

@onready var label: Label = $Label

const DURATION: float = 1.0
const RISE_DISTANCE: float = 40.0
const ARC_DROP: float = 12.0  # slight downward dip after the rise (orange/enemy variant)


#+++++++++++++++++++++++++
# Set the displayed amount, color, and motion style.
# arc=false → straight rise + fade (red on player)
# arc=true  → rise then slight drop + fade (orange on enemy)
#+++++++++++++++++++++++++
func setup(amount: int, color: Color, arc: bool = false) -> void:
	if not is_node_ready():
		await ready
	label.text = str(amount)
	label.modulate = color

	var start_y: float = position.y

	# Alpha fade runs the full duration on its own tween so it overlaps
	# whatever Y motion we choose.
	var alpha_tween := create_tween()
	alpha_tween.tween_property(label, "modulate:a", 0.0, DURATION)

	var y_tween := create_tween()
	if arc:
		y_tween.tween_property(self, "position:y",
			start_y - RISE_DISTANCE, DURATION * 0.5)
		y_tween.tween_property(self, "position:y",
			start_y - RISE_DISTANCE + ARC_DROP, DURATION * 0.5)
	else:
		y_tween.tween_property(self, "position:y",
			start_y - RISE_DISTANCE, DURATION)

	await alpha_tween.finished
	queue_free()
