extends ProgressBar
## Life is immediate; a brief bronze trace makes the last loss readable.
## This never interpolates or writes the simulation's health value.
const HOLD := 0.18
const SETTLE := 0.42
var trail_value := 0.0
var reduced_motion := false
var feedback_active := true
var _previous := 0.0
var _maximum := 0.0
var _hold := 0.0
var _trail_speed := 0.0
var _trail_style: StyleBoxFlat

func _ready() -> void:
	trail_value = value
	_previous = value
	_maximum = max_value
	_trail_style = StyleBoxFlat.new()
	_trail_style.bg_color = Color("d2ad70")
	_trail_style.set_corner_radius_all(2)
	value_changed.connect(_on_health_changed)
	set_process(false)

func _on_health_changed(current: float) -> void:
	if reduced_motion or not is_equal_approx(max_value, _maximum) or current >= _previous:
		trail_value = current
		_hold = 0.0
	else:
		trail_value = maxf(trail_value, _previous)
		_hold = HOLD
		_trail_speed = (trail_value - current) / SETTLE
	_previous = current
	_maximum = max_value
	set_process(feedback_active and not reduced_motion and trail_value > value)
	queue_redraw()

func set_presentation(motion_reduced: bool, _battery: bool) -> void:
	reduced_motion = motion_reduced
	if reduced_motion: trail_value = value
	set_feedback_active(feedback_active)
	queue_redraw()

func set_feedback_active(active: bool) -> void:
	feedback_active = active
	set_process(active and not reduced_motion and trail_value > value)

func _process(delta: float) -> void:
	var elapsed := maxf(0.0, delta - _hold)
	_hold = maxf(0.0, _hold - delta)
	trail_value = move_toward(trail_value, value, _trail_speed * elapsed)
	if trail_value <= value: set_process(false)
	queue_redraw()

func _draw() -> void:
	if _trail_style == null or trail_value <= value or max_value <= min_value: return
	var start := size.x * ratio
	var end := size.x * clampf((trail_value - min_value) / (max_value - min_value), 0.0, 1.0)
	if end > start: draw_style_box(_trail_style, Rect2(start, 0.0, end - start, size.y))
