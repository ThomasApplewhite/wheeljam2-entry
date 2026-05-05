extends MovementAbility3D
class_name WDodgeAbility3D

## Much like the walk ability, except with a tweening cooldown to run the dodge!
## Most of the dodge movement happens in the last 90% of the move.

# When started (if it's in an inactive state and then given an input), it will jack
# the player's velocity really really high, and then slowly reduce it
# because it's a movement ability, it'll be applied after the other ones in much the
# same way. Or I'll just do it myself
@export var max_dodge_speed : float = 10.0
@export var dodge_duration : float = 1.0

var _is_dodging : bool = false
var _dodge_speed : float = 0.0
var _dodge_direction : Vector3 = Vector3.ZERO

func apply(velocity : Vector3, speed : float, is_on_floor : bool, direction : Vector3, _delta : float) -> Vector3:
	if not _is_dodging:
		# No change if not dodging
		if direction == Vector3.ZERO:
			return velocity
		# Start dodging!
		else:
			_start_dodge(direction)
	
	velocity = _dodge_speed * _dodge_direction
	return velocity
	

func _start_dodge(in_direction : Vector3):
	_dodge_speed = max_dodge_speed
	_dodge_direction = in_direction
	_is_dodging = true
	var tween = create_tween().bind_node(self)
	tween.set_trans(Tween.TRANS_EXPO)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "_dodge_speed", 0.0, dodge_duration)
	tween.tween_callback(_end_dodge)

func _end_dodge():
	_dodge_speed = 0.0
	_dodge_direction = Vector3.ZERO
	_is_dodging = false
	
